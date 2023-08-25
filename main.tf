terraform {
  backend "s3" {}

  required_providers {
    docker = {
      source  = "registry.terraform.io/kreuzwerker/docker"
      version = "~>3.0"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~>3.5"
    }
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~>4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.4"
    }
  }
}

provider "random" {}
provider "docker" {}
provider "aws" {}
provider "local" {}

locals {
  project_name   = var.project_name != null ? var.project_name : basename(var.dream_project_dir)
  non_secret_env = {
    for k, v in var.dream_env : k => try(tostring(v), null)
  }

  non_secret_cleaned = {
    for k, v in local.non_secret_env : k => v if v != null
  }

  secret_env = {
    for k in var.dream_secrets : k => data.aws_ssm_parameter.secret_env[k].value
  }

  env = toset([
    for k, v in merge(local.oidc_env, local.non_secret_cleaned, local.secret_env, {
      REDIS_HOST = "host.docker.internal"
    }) : "${k}=${v}"
  ])

  url_parse_regex          = "(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?"
  root_url_parts           = regex(local.url_parse_regex, var.root_url)
  //noinspection HILUnresolvedReference
  root_url_scheme          = local.root_url_parts.scheme
  //noinspection HILUnresolvedReference
  root_url_authority       = local.root_url_parts.authority
  root_url_authority_parts = split(":", local.root_url_authority)
  root_url_host            = local.root_url_authority_parts[0]
  app_host                 = contains([
    "localhost", "127.0.0.1"
  ], local.root_url_host) ? "host.docker.internal" : local.root_url_host
  app_port = length(local.root_url_authority_parts) == 2 ? local.root_url_authority_parts[1] : (local.root_url_scheme == "https" ? "443" : "80")
}

data "aws_ssm_parameter" "secret_env" {
  for_each = var.dream_secrets
  name     = var.dream_env[each.key].key
}

resource "random_pet" "docker_network_name" {}

resource "docker_network" "private_network" {
  name = "oidc-sidecar-${random_pet.docker_network_name.id}"
}

resource "docker_image" "envoy" {
  name = "envoyproxy/envoy:v1.26-latest"
}

resource "random_pet" "envoy_container_name" {}

resource "local_file" "envoy_config" {
  filename = "${path.module}/envoy.yaml"
  content  = templatefile("${path.module}/envoy.tpl.yaml", {
    port     = var.port
    appPort  = local.app_port
    appHost  = local.app_host
    authHost = docker_container.oidc_sidecar.hostname
    authPort = docker_container.oidc_sidecar.ports[0].internal
  })
}

resource "docker_container" "envoy" {
  image = docker_image.envoy.image_id
  name  = "envoy-${random_pet.envoy_container_name.id}"
  ports {
    internal = var.port
    external = var.port
  }
  volumes {
    container_path = "/etc/envoy/envoy.yaml"
    host_path      = abspath(local_file.envoy_config.filename)
    read_only      = true
  }
  must_run = true
  rm       = true
  networks_advanced {
    name = docker_network.private_network.name
  }
}

resource "docker_image" "oidc_sidecar" {
  name         = "public.ecr.aws/hereya/oidc-sidecar:f5191a4"
  keep_locally = true
}

resource "random_pet" "oidc_sidecar_container_name" {}

resource "docker_container" "oidc_sidecar" {
  name  = "oidc-sidecar-${random_pet.oidc_sidecar_container_name.id}"
  image = docker_image.oidc_sidecar.image_id
  ports {
    internal = 8080
  }
  env      = local.env
  must_run = true
  rm       = true
  networks_advanced {
    name = docker_network.private_network.name
  }
}

