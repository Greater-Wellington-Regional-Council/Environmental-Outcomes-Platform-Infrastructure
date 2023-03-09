resource "aws_cloudwatch_log_metric_filter" "manager_log_errors" {
  name           = "Manager Log Error Messages"
  pattern        = "\" ERROR \""
  log_group_name = var.eop_manager_log_group_name

  metric_transformation {
    name          = "ErrorMessageEventCount"
    namespace     = "EOP"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "manager_log_errors_alarm" {
  alarm_name          = "eop-manager-log-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  namespace           = "EOP"
  metric_name         = "ErrorMessageEventCount"
  period              = "900"
  statistic           = "Sum"
  alarm_description   = "This metric monitors error log records in the EOP Manager log file."
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarms_sns_topic_arn

}

resource "aws_cloudwatch_log_metric_filter" "manager_log_warnings" {
  name           = "Manager Log Warning Messages"
  pattern        = "\" WARN \""
  log_group_name = var.eop_manager_log_group_name

  metric_transformation {
    name          = "WarningMessageEventCount"
    namespace     = "EOP"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "manager_log_warnings_alarm" {
  alarm_name          = "eop-manager-log-warnings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  namespace           = "EOP"
  metric_name         = "WarningMessageEventCount"
  period              = "900"
  statistic           = "Sum"
  alarm_description   = "This metric monitors warning log records in the EOP Manager log file."
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarms_sns_topic_arn

}

data "aws_arn" "eop_alb_arn" {
  arn = var.eop_alb_arn
}

resource "aws_cloudwatch_metric_alarm" "eop_elb_500_errors" {
  alarm_name          = "eop-elb-500-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions = {
    LoadBalancer = replace(data.aws_arn.eop_alb_arn.resource, "loadbalancer/", "") # Convert "loadbalancer/app/AAA/BBB" -> "app/AAA/BBB" to match the name expected by cloudwatch
  }

  period             = "900"
  statistic          = "Sum"
  alarm_description  = "This monitors 500 errors being returned from the EOP API's."
  treat_missing_data = "notBreaching"

  alarm_actions = var.alarms_sns_topic_arn
}
