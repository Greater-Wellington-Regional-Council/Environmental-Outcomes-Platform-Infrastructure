variable "alb_dns_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "alb_http_header_secret" {
  type = string
}

locals {
  origin_id = "tileserver-origin"
}

# Cloudfront -> ALB
resource "aws_cloudfront_distribution" "tileserver_cdn" {
  aliases = [var.domain_name]
  origin {
    domain_name              = var.alb_dns_name
    origin_id                = local.origin_id
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
    # Restrict access to ALB origin via this distribution via a custom host header
    # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/restrict-access-to-load-balancer.html

    custom_header {
      name = "x-alb-secret"
      value = var.alb_http_header_secret
    }
  }
  enabled = true

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

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
      locations = []
      restriction_type = "none"

    }
  }
  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }  
}

resource "aws_route53_record" "dns_record" {
  zone_id = var.hosted_zone_id
  name   = var.domain_name
  type    = "A"

  alias {
    zone_id = aws_cloudfront_distribution.tileserver_cdn.hosted_zone_id
    name = aws_cloudfront_distribution.tileserver_cdn.domain_name
    evaluate_target_health = false
  }
}
