variable "domain_name" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_http_header_secret" {
  type = string
}
