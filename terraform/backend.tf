# -------------------------------------------------------
# BACKEND — Terraform remote state in S3 + DynamoDB lock
#
# ⚠️  RUN THESE COMMANDS ONCE MANUALLY before `terraform init`
#     (Only needed on first setup — idempotent if re-run)
#
# 1. Create state bucket:
#   aws s3api create-bucket \
#     --bucket nimbuscloud-terraform-state \
#     --region ap-south-1 \
#     --create-bucket-configuration LocationConstraint=ap-south-1
#
# 2. Enable versioning (protects state history):
#   aws s3api put-bucket-versioning \
#     --bucket nimbuscloud-terraform-state \
#     --versioning-configuration Status=Enabled
#
# 3. Enable encryption:
#   aws s3api put-bucket-encryption \
#     --bucket nimbuscloud-terraform-state \
#     --server-side-encryption-configuration \
#       '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# 4. Block public access on state bucket:
#   aws s3api put-public-access-block \
#     --bucket nimbuscloud-terraform-state \
#     --public-access-block-configuration \
#       "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#
# 5. Create DynamoDB lock table:
#   aws dynamodb create-table \
#     --table-name nimbuscloud-terraform-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region ap-south-1
#
# FIX #1 (S3 Backend 403): IAM role MUST have s3:GetObject + s3:PutObject +
#   s3:ListBucket on arn:aws:s3:::nimbuscloud-terraform-state and /*
#
# FIX #8 (DynamoDB lock): IAM role MUST have dynamodb:GetItem + PutItem +
#   DeleteItem + DescribeTable on the lock table ARN
#
# FIX #13 (State lock stuck): If pipeline dies mid-run, unlock manually:
#   terraform force-unlock <LOCK_ID> -force
# -------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "nimbuscloud-terraform-state"
    key            = "nimbuscloud/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "nimbuscloud-terraform-lock"
    encrypt        = true
  }
}
