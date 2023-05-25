output "AUTH_ENDPOINT" {
  description = "The endpoint for the authenticating requests"
  value       = "http://localhost:${docker_container.oidc_sidecar.ports[0].external}/auth/authenticate"
}

output "REVERSE_PROXY_ENDPOINT" {
  value = "http://localhost:${docker_container.envoy.ports[0].external}"
}