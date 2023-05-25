variable "root_url" {
  type        = string
  description = "Application root url"
}

variable "cognito_user_pool_id" {
  type        = string
  description = "The name of the user pool to create the app client in"
}

variable "cognito_user_pool_domain" {
  type        = string
  description = "The fully-qualified domain name of the user pool"
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


