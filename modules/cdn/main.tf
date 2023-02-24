resource "aws_cloudfront_distribution" "cdn" {
  aliases = [var.domain_name]
  origin {
    domain_name = var.alb_dns_name
    origin_id   = var.alb_dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    # Restrict access to ALB origin via this distribution via a custom host header
    # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/restrict-access-to-load-balancer.html
    custom_header {
      name  = "x-alb-secret"
      value = var.alb_http_header_secret
    }
  }
  enabled = true

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = var.alb_dns_name
    viewer_protocol_policy = "redirect-to-https"

    # In order to use origin cache headers, we need to set some magic numbers here.
    # See https://github.com/hashicorp/terraform-provider-aws/issues/21272
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
      headers = ["Host"]
    }
  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"

    }
  }
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    include_cookies = false
    bucket          = "${module.access_logs.name}.s3.amazonaws.com"
  }
}

# Based on https://github.com/gruntwork-io/terraform-aws-static-assets/blob/main/modules/s3-cloudfront/main.tf#L542
module "access_logs" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/private-s3-bucket?ref=v0.65.3"

  name          = "${var.domain_name}-cloudfront-logs"
  sse_algorithm = "AES256"

  bucket_policy_statements = {
    AllowCloudfrontWriteS3AccessLog = {
      effect  = "Allow"
      actions = ["s3:*"]
      principals = {
        "AWS" = ["arn:aws:iam::162777425019:root"]
      }
    }
  }

  lifecycle_rules = {
    log = {
      enabled = true
      expiration = {
        expire_in_days = {
          # This matches the default value used for other CDNs created by terragrunt
          days = 30
        }
      }
    }
  }
}

resource "aws_route53_record" "dns_record" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    name                   = aws_cloudfront_distribution.cdn.domain_name
    evaluate_target_health = false
  }
}
