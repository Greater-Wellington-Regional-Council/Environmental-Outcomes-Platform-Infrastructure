variable "alarms_sns_topic_arn" {
  description = "The ARNs of SNS topics where CloudWatch alarms (e.g., for CPU, memory, and disk space usage) should send notifications."
  type        = list(string)
  default     = []
}

variable "eop_alb_arn" {
  description = "The name for the EOP Manager ELB."
  type        = string
}

variable "eop_manager_log_group_name" {
  description = "The log group name for the EOP Manager Service."
  type        = string
}
