variable "sns_topic_name" {
  type = string
}

variable "sns_kms_master_key_id" {
  type = string
}

variable "total_monthly_budget_amount" {
  type = number
}

variable "monthly_cloudwatch_budget_amount" {
  type = number
}
