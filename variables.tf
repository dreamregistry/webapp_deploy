variable "root_url" {
  type        = string
  description = "Application root url"
}

variable "auth0_custom_domain" {
  type        = string
  description = "Auth0 custom domain"
}

variable "port" {
  type        = number
  description = "The port to run the application on"
  default     = 8000
}

variable "dream_env" {
  description = "dream app environment variables to set"
  type        = any
  default     = {}
}

variable "dream_secrets" {
  description = "dream app secrets to set"
  type        = set(string)
  default     = []
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = null
}

variable "dream_project_dir" {
  description = "root directory of the project sources"
  type        = string
}
