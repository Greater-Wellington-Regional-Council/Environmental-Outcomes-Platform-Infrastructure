module "ecs_task_scheduler" {
  source = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-ecs.git//modules/ecs-task-scheduler?ref=v0.35.12-gwrc"

  ecs_target_cluster_arn         = var.ecs_target_cluster_arn
  ecs_target_task_definition_arn = aws_ecs_task_definition.task.arn
  task_schedule_expression       = var.task_schedule_expression

  ecs_target_network_configuration = {
    assign_public_ip = false
    security_groups = [
      aws_security_group.service.id
    ]
    subnets = var.subnets
  }


  ecs_target_launch_type      = "FARGATE"
  ecs_target_platform_version = "LATEST"

}

resource "aws_security_group" "service" {
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS task cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

# Define the Assume Role IAM Policy Document for the ECS Service Scheduler IAM Role
data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "service_policy" {
  name   = "${var.service_name}Policy"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.service_policy.json
}

data "aws_iam_policy_document" "service_policy" {
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.service_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json

  # IAM objects take time to propagate. This leads to subtle eventual consistency bugs where the ECS task cannot be
  # created because the IAM role does not exist. We add a 15 second wait here to give the IAM role a chance to propagate
  # within AWS.
  provisioner "local-exec" {
    command = "echo 'Sleeping for 15 seconds to wait for IAM role to be created'; sleep 15"
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name   = "${var.service_name}-task-execution-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_policy_document.json
  role   = aws_iam_role.ecs_task_execution_role.id
}

data "aws_iam_policy_document" "ecs_task_execution_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  name   = "${var.service_name}-task-execution-secrets-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_secrets_policy_document.json
  role   = aws_iam_role.ecs_task_execution_role.id
}

data "aws_iam_policy_document" "ecs_task_execution_secrets_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [for secret in data.aws_secretsmanager_secret.secrets_manager_arn_exchange : secret.arn]
  }
}

# This allows the user to pass either the full ARN of a Secrets Manager secret (including the randomly generated
# suffix) or the ARN without the random suffix. The data source will find the full ARN for use in the IAM policy.
data "aws_secretsmanager_secret" "secrets_manager_arn_exchange" {
  for_each = { for secret in var.secrets_manager_arns : secret => secret }
  arn      = each.value
}

resource "aws_ecs_task_definition" "task" {
  family = var.service_name

  container_definitions = jsonencode(var.container_definitions)
  task_role_arn         = aws_iam_role.ecs_task.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn

  network_mode = "awsvpc"

  # For FARGATE, these options must be defined here and not in the container definition file
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}
