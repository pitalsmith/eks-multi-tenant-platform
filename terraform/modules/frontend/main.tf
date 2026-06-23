resource "aws_s3_bucket" "this" {
  bucket = "dev-frontend-${random_integer.suffix.result}"
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# -----------------------------
# CloudFront Origin Access Identity
# -----------------------------
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for frontend S3 bucket"
}

# -----------------------------
# CloudFront Distribution
# -----------------------------
resource "aws_cloudfront_distribution" "frontend_cdn" {

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "s3-frontend-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-frontend-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
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

# -----------------------------
# S3 Bucket Policy (allow CloudFront only)
# -----------------------------
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}