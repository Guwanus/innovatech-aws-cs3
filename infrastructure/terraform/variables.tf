variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "db_username" {
  description = "DB master username"
  type        = string
}

variable "db_password" {
  description = "DB master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "innovatech_db"
}

variable "portal_image" {
  description = "Docker image for the portal (ECR URI)"
  type        = string
}

variable "default_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "CS3"
    Env     = "dev"
  }
}
