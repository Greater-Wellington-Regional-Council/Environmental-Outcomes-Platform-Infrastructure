variable "service_name" {
  description = "The service name"
  type        = string
}

variable "ecs_target_cluster_arn" {
  description = "The arn of the ECS cluster to use."
  type        = string
}

variable "task_schedule_expression" {
  description = "The scheduling expression to use (rate or cron - see README for usage examples). Leave null if using task_event_pattern."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The VPC to use for the Fargate task network. The security group will be created in this VPC."
  type        = string
}

variable "subnets" {
  description = "The subnets to use for the Fargate task network."
  type        = list(string)
}

variable "container_definitions" {
  description = "List of container definitions to use for the ECS task. Each entry corresponds to a different ECS container definition."

  # Ideally we can use a concrete type here, but container definitions have many optional fields which Terraform does
  # not yet have good support for.
  type = any

  # Example:
  # container_definitions = [{
  #   name  = "nginx"
  #   image = "nginx:1.21"
  # }]
}

variable "secrets_manager_arns" {
  description = "A list of ARNs for Secrets Manager secrets that the ECS execution IAM policy should be granted access to read. Note that this is different from the ECS task IAM policy. The execution policy is concerned with permissions required to run the ECS task. The ARN can be either the complete ARN, including the randomly generated suffix, or the ARN without the suffix. If the latter, the module will look up the full ARN automatically. This is helpful in cases where you don't yet know the randomly generated suffix because the rest of the ARN is a predictable value."
  type        = list(string)
  default     = []
}


