locals {
  manager_service_name    = "eop-manager"
  tileserver_service_name = "eop-tileserver"

  manager_log_group_name    = "/${var.account_name}/ecs/${local.manager_service_name}"
  tileserver_log_group_name = "/${var.account_name}/ecs/${local.tileserver_service_name}"
}

resource "aws_cloudwatch_log_metric_filter" "manager_log_errors" {
  name           = "Manager Log Error Messages"
  pattern        = "?\" WARN \" ?\" ERROR \""
  log_group_name = local.manager_log_group_name

  metric_transformation {
    name          = "ManagerErrorMessageEventCount"
    namespace     = "EOP"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "manager_log_errors_alarm" {
  alarm_name          = "eop-manager-log-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  namespace           = "EOP"
  metric_name         = "ManagerErrorMessageEventCount"
  period              = "300"
  statistic           = "Sum"
  alarm_description   = "This metric monitors error log records in the EOP Manager log file."
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarms_sns_topic_arn
}

resource "aws_cloudwatch_log_metric_filter" "tileserver_log_errors" {
  name           = "Tileserver Log Error Messages"
  pattern        = "?\"=warning\" ?\"=error\" ?\"=panic\" ?\"=fatal\""
  log_group_name = local.tileserver_log_group_name

  metric_transformation {
    name          = "TileserverErrorMessageEventCount"
    namespace     = "EOP"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "tileserver_log_errors_alarm" {
  alarm_name          = "eop-tileserver-log-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  namespace           = "EOP"
  metric_name         = "TileserverErrorMessageEventCount"
  period              = "300"
  statistic           = "Sum"
  alarm_description   = "This metric monitors error log records in the EOP Tileserver log file."
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarms_sns_topic_arn
}

data "aws_arn" "eop_alb_arn" {
  arn = var.eop_alb_arn
}

resource "aws_cloudwatch_metric_alarm" "eop_elb_500_errors" {
  alarm_name          = "eop-elb-500-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
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

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "eop"

  dashboard_body = jsonencode({
    start = "-PT3H"
    widgets = [
      {
        height = 4,
        width  = 24,
        y      = 0,
        x      = 0,
        type   = "alarm",
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.manager_log_errors_alarm.arn,
            aws_cloudwatch_metric_alarm.eop_elb_500_errors.arn,
            # The Gruntworks modules don't expose these ARNs as outputs. Easier to build them here than get them added as outputs.
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:services-${var.account_name}-eop-tileserver-high-memory-utilization",
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:services-${var.account_name}-eop-tileserver-high-cpu-utilization",
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:services-${var.account_name}-eop-manager-high-memory-utilization",
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:services-${var.account_name}-eop-manager-high-cpu-utilization",
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:aurora-${var.account_name}-0-high-cpu-utilization",
            "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:aurora-${var.account_name}-0-too-many-db-connections"
          ]
        }
      },
      {
        height = 6,
        width  = 24,
        y      = 4,
        x      = 0,
        type   = "metric",
        properties = {
          metrics = [
            [
              "ECS/ContainerInsights",
              "RunningTaskCount",
              "ServiceName",
              local.manager_service_name,
              "ClusterName",
              var.ecs_cluster_name,
              {
                label = "Manager Tasks"
              }
            ],
            [
              "...",
              local.tileserver_service_name,
              ".",
              ".",
              {
                label = "Tile Server Tasks"
              }
            ]
          ],
          sparkline = true,
          view      = "singleValue",
          region    = var.aws_region,
          title     = "Running Containers",
          stat      = "Average",
          period    = 300
        }
      },
      {
        height = 6,
        width  = 6,
        y      = 10,
        x      = 0,
        type   = "metric",
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", replace(data.aws_arn.eop_alb_arn.resource, "loadbalancer/", "")]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          period  = 300,
          title   = "API Request Count",
          stat    = "SampleCount"
        }
      },
      {
        height = 6,
        width  = 6,
        y      = 10,
        x      = 6,
        type   = "metric",
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", replace(data.aws_arn.eop_alb_arn.resource, "loadbalancer/", "")]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          period  = 300,
          title   = "API 5XX Count",
          stat    = "SampleCount"
        }
      },
      {
        height = 6,
        width  = 6,
        y      = 10,
        x      = 12,
        type   = "metric",
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", replace(data.aws_arn.eop_alb_arn.resource, "loadbalancer/", "")]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          period  = 300,
          title   = "API 4XX Count",
          stat    = "SampleCount"
        }
      },
      {
        height = 6,
        width  = 6,
        y      = 10,
        x      = 18,
        type   = "metric",

        properties = {
          metrics = [
            [{ expression = "METRICS() * 1000", label = "to Millis", id : "e1", region : var.aws_region }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", replace(data.aws_arn.eop_alb_arn.resource, "loadbalancer/", ""), { stat = "Average", id = "m1", visible = false }],
            ["...", { stat = "Maximum", id = "m2", visible = false }],
            ["...", { stat = "p99", id = "m3", visible = false }]

          ],
          view     = "timeSeries",
          stacked  = false,
          region   = var.aws_region,
          period   = 300,
          title    = "API Response Times",
          liveData = true,
          yAxis = {
            right = {
              showUnits = false
            }
            left = {
              showUnits = false
              label     = "Millis"
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Goal",
                value = 3000,
                fill  = "above"
              }
            ]
          }
        }
      },
      {
        height = 6,
        width  = 24,
        y      = 16,
        x      = 0,
        type   = "log",
        properties = {
          query   = "SOURCE '${local.manager_log_group_name}' | fields @message\n| sort @timestamp desc\n| limit 50",
          region  = var.aws_region,
          stacked = false,
          view    = "table",
          title   = "Latest Manager Logs"
        }
      },
      {
        height = 6,
        width  = 24,
        y      = 22,
        x      = 0,
        type   = "log",
        properties = {
          query   = "SOURCE '${local.tileserver_log_group_name}' | fields @message\n| sort @timestamp desc\n| limit 50",
          region  = var.aws_region,
          stacked = false,
          view    = "table",
          title   = "Latest Tile Server Logs"
        }
      },

    ]
  })
}
