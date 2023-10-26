variable "total_monthly_budget_amount" {
  type = number
}

variable "monthly_cloudwatch_budget_amount" {
  type = number
}

variable "notification_email_addresses" {
  type = set(string)
}
