# -------------------------------------------------------
# PROVIDER + TERRAFORM VERSION
# -------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------------
# LOCALS
# -------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =======================================================
# S3 BUCKET — static site storage
# =======================================================

resource "aws_s3_bucket" "site" {
  bucket        = "${local.name_prefix}-site"
  force_destroy = true # Allows destroy even when bucket has objects
  tags          = local.common_tags
}

# FIX #2 (State mismatch / AlreadyExists): If bucket already exists in AWS
# but not in state, import it first:
#   terraform import aws_s3_bucket.site nimbuscloud-prod-site

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.site]
}

# FIX #12 (Lifecycle Invalid Attribute Combination):
#   The rule MUST have either a filter block (even empty with prefix="")
#   OR a top-level prefix — never both, never neither on AWS provider v5.
#   Using filter { prefix = "" } is the correct form for "apply to all objects".
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  # FIX: depends_on versioning — lifecycle rule for noncurrent versions
  # only works after versioning is enabled; without this, apply can race.
  depends_on = [aws_s3_bucket_versioning.site]

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    # filter with empty prefix = apply rule to ALL objects in bucket
    filter {
      prefix = ""
    }

    # Auto-delete old non-current versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Auto-delete expired delete markers to keep bucket clean
    expiration {
      expired_object_delete_marker = true
    }
  }
}

# FIX #11 (s3:GetBucketPolicy AccessDenied):
#   depends_on public_access_block — bucket policy apply fails if
#   public access block hasn't been set yet (AWS rejects policy with error).
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  depends_on = [
    aws_s3_bucket_public_access_block.site,
    aws_cloudfront_distribution.site,
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            # Only this specific CloudFront distribution can read the bucket
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}

# =======================================================
# CLOUDFRONT
# =======================================================

# FIX #5 (OriginAccessControlAlreadyExists):
#   If this resource already exists in AWS but not in state, import it:
#     terraform import aws_cloudfront_origin_access_control.site <OAC_ID>
#   The name must be unique in your AWS account — using name_prefix ensures
#   it won't collide across environments.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${local.name_prefix} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${local.name_prefix} static site"

  # PriceClass_100 = US, Canada, Europe only — cheapest option
  price_class  = "PriceClass_100"
  http_version = "http2"
  tags         = local.common_tags

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # SPA routing fix — return index.html for unknown paths instead of S3 403/404
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
