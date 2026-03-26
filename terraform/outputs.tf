# -------------------------------------------------------
# OUTPUTS — printed after terraform apply
#
# After first apply, copy these values to GitHub Secrets:
#   AWS_ROLE_ARN         ← github_actions_role_arn
#   S3_BUCKET_NAME       ← s3_bucket_name  (used in destroy workflow)
# -------------------------------------------------------

output "cloudfront_url" {
  description = "Live website URL"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used by pipeline for cache invalidation)"
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_name" {
  description = "S3 site bucket name — add as GitHub secret S3_BUCKET_NAME"
  value       = aws_s3_bucket.site.id
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions — add as GitHub secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "aws_region" {
  description = "Deployment region"
  value       = var.aws_region
}
