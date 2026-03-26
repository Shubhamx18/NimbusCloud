output "cloudfront_url" {
  description = "Live website URL"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_name" {
  description = "S3 site bucket name"
  value       = aws_s3_bucket.site.id
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "aws_region" {
  description = "Deployment region"
  value       = var.aws_region
}