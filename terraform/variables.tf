variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "nimbuscloud"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "GitHub username or org (lowercase)"
  type        = string
  default     = "Shubhamx18"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "NimbusCloud"
}