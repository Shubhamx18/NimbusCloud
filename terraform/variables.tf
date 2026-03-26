# -------------------------------------------------------
# VARIABLES
# -------------------------------------------------------

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
  description = "Environment name (prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  # Must be all lowercase - GitHub OIDC sub claim is always lowercase.
  # Example: "Shubhamx18" -> "shubhamx18"
  description = "GitHub username or org (lowercase only - OIDC sub is case-sensitive)"
  type        = string
  default     = "Shubhamx18"
}

variable "github_repo" {
  # Must be lowercase and must match the repo running the workflow (this repo is nimbus-deploy).
  # If it mismatches, OIDC sub will not match and AssumeRoleWithWebIdentity will fail.
  description = "GitHub repository name (lowercase, must match workflow repo)"
  type        = string
  default     = "NimbusCloud"
}
