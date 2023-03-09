variable "account_name" {
  description = "The name of the account this is being created in. e.g eopdev"
  type        = string
}

variable "account_id" {
  description = "The id of the account this is being created in. e.g 111222333"
  type        = string
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "alarms_sns_topic_arn" {
  description = "The ARNs of SNS topics where CloudWatch alarms should send notifications."
  type        = list(string)
  default     = []
}

variable "eop_alb_arn" {
  description = "The name for the EOP Manager ELB."
  type        = string
}
