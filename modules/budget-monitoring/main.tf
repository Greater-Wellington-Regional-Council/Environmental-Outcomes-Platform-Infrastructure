resource "aws_budgets_budget" "total_monthly_budget" {
  name         = "Total Month Spend Budget"
  budget_type  = "COST"
  limit_amount = var.total_monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2022-10-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [module.sns_topic.topic_arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [module.sns_topic.topic_arn]
  }
}

resource "aws_budgets_budget" "monthly_cloudwatch_budget" {
  name         = "Monthly Cloudwatch Spend Budget"
  budget_type  = "COST"
  limit_amount = var.monthly_cloudwatch_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2022-10-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [module.sns_topic.topic_arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [module.sns_topic.topic_arn]
  }
}

module "sns_topic" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/networking/sns-topics"

  name              = var.sns_topic_name
  kms_master_key_id = var.sns_kms_master_key_id

  allow_publish_services = [
    "budgets.amazonaws.com"
  ]
}
