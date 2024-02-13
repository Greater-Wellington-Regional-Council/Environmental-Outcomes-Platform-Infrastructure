resource "aws_budgets_budget" "total_monthly_budget" {
  name         = "Total Month Spend Budget"
  budget_type  = "COST"
  limit_amount = var.total_monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2022-10-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_email_addresses
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_email_addresses
  }
}

resource "aws_budgets_budget" "monthly_cloudwatch_budget" {
  name         = "Monthly Cloudwatch Spend Budget"
  budget_type  = "COST"
  limit_amount = var.monthly_cloudwatch_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2022-10-01_00:00"

  cost_filter {
    name = "Service"
    values = [
      "AmazonCloudWatch"
    ]

  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_email_addresses
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_email_addresses
  }
}
