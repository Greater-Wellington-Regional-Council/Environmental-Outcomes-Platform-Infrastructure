# Based on https://github.com/gruntwork-io/terraform-aws-messaging/tree/main/modules/msk
# Adapted to use https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_serverless_cluster

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# RUN AN AMAZON MANAGED STREAMING FOR KAFKA (MSK) CLUSTER
# These templates launch an MSK cluster resource that manages the Kafka cluster. This includes:
# - Security group and rules based on selected auth method
# - Storage autoscaling
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.75.1"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE LOCALS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Construct a properties file format from the properties map
  server_properties = join("\n", [for k, v in var.server_properties : "${k}=${v}"])

  # Determine allowed ports
  allow_plaintext_9092  = contains(["PLAINTEXT", "TLS_PLAINTEXT"], var.encryption_in_transit_client_broker)
  allow_tls_9094        = contains(["TLS", "TLS_PLAINTEXT"], var.encryption_in_transit_client_broker)
  allow_sasl_scram_9096 = var.enable_client_sasl_scram && contains(["TLS", "TLS_PLAINTEXT"], var.encryption_in_transit_client_broker)
  allow_sasl_iam_9098   = var.enable_client_sasl_iam && contains(["TLS", "TLS_PLAINTEXT"], var.encryption_in_transit_client_broker)

  # Clean up ports
  all_ports = [for port in [
    local.allow_plaintext_9092 ? 9092 : 0,
    local.allow_tls_9094 ? 9094 : 0,
    local.allow_sasl_scram_9096 ? 9096 : 0,
    local.allow_sasl_iam_9098 ? 9098 : 0,
    # Always allow Zookeeper ports
    2181,
    2182
  ] : port if port != 0]

  # Construct a product on configured ports and allowed security groups
  allowed_security_groups_with_all_ports = setproduct(var.allowed_inbound_security_group_ids, local.all_ports)

  cluster_topic_arn_prefix = "arn:${data.aws_partition.current.partition}:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${var.cluster_name}"
  cluster_group_arn_prefix = "arn:${data.aws_partition.current.partition}:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:group/${var.cluster_name}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE MSK CLUSTER SECURITY GROUP
# Limits which ports are allowed inbound and outbound on the broker nodes.
# We export the security group id as an output so users of this module can add their own custom rules.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "msk" {
  name        = var.cluster_name
  description = "Security Group for ${var.cluster_name} MSK Cluster"
  vpc_id      = var.vpc_id
  tags        = var.custom_tags_security_group
}

# Allow all outbound
resource "aws_security_group_rule" "allow_outbound_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.msk.id
}

# Allow inbound from provided CIDR blocks
resource "aws_security_group_rule" "allow_inbound_cidr" {
  count             = length(var.allowed_inbound_cidr_blocks)
  type              = "ingress"
  from_port         = local.all_ports[count.index]
  to_port           = local.all_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidr_blocks
  security_group_id = aws_security_group.msk.id
}

# Allow inbound from provided security groups
resource "aws_security_group_rule" "allow_inbound_sg" {
  count                    = length(local.allowed_security_groups_with_all_ports)
  type                     = "ingress"
  from_port                = local.allowed_security_groups_with_all_ports[count.index][1]
  to_port                  = local.allowed_security_groups_with_all_ports[count.index][1]
  protocol                 = "tcp"
  source_security_group_id = local.allowed_security_groups_with_all_ports[count.index][0]
  security_group_id        = aws_security_group.msk.id
}

# Allow inbound from self
resource "aws_security_group_rule" "allow_inbound_self" {
  count             = length(local.all_ports)
  type              = "ingress"
  from_port         = local.all_ports[count.index]
  to_port           = local.all_ports[count.index]
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.msk.id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE MSK CONFIGURATION AND CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_msk_configuration" "msk" {
  kafka_versions = [var.kafka_version]
  name           = var.cluster_name
  description    = "MSK configuration for cluster ${var.cluster_name}"

  server_properties = local.server_properties
}

resource "aws_msk_cluster" "msk" {
  cluster_name           = var.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.cluster_size
  enhanced_monitoring    = var.enhanced_monitoring

  configuration_info {
    arn      = aws_msk_configuration.msk.arn
    revision = aws_msk_configuration.msk.latest_revision
  }

  broker_node_group_info {
    instance_type   = var.instance_type
    ebs_volume_size = var.initial_ebs_volume_size
    client_subnets  = var.subnet_ids
    security_groups = concat(compact(var.additional_security_group_ids), [aws_security_group.msk.id])
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.encryption_in_transit_client_broker
      in_cluster    = var.encryption_in_transit_in_cluster
    }
    encryption_at_rest_kms_key_arn = var.encryption_at_rest_kms_key_arn
  }

  dynamic "client_authentication" {
    for_each = var.enable_client_tls || var.enable_client_sasl_scram || var.enable_client_sasl_iam ? ["auth"] : []
    content {
      dynamic "tls" {
        for_each = var.enable_client_tls ? ["tls"] : []
        content {
          certificate_authority_arns = var.client_tls_certificate_authority_arns
        }
      }
      dynamic "sasl" {
        for_each = var.enable_client_sasl_scram || var.enable_client_sasl_iam ? ["sasl"] : []
        content {
          scram = var.enable_client_sasl_scram
          iam   = var.enable_client_sasl_iam
        }
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = var.enable_cloudwatch_logs
        log_group = var.cloudwatch_log_group
      }
      firehose {
        enabled         = var.enable_firehose_logs
        delivery_stream = var.firehose_delivery_stream
      }
      s3 {
        enabled = var.enable_s3_logs
        bucket  = var.s3_logs_bucket
        prefix  = var.s3_logs_prefix
      }
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.open_monitoring_enable_jmx_exporter
      }
      node_exporter {
        enabled_in_broker = var.open_monitoring_enable_node_exporter
      }
    }
  }

  tags = var.custom_tags

  # Ignore changes to the broker volume, because 'aws_appautoscaling_policy' will take care of scaling the volume
  lifecycle {
    ignore_changes = [broker_node_group_info[0].ebs_volume_size]
  }
}

# AWS Secrets Manager holds entries for username and password authentication for a cluster.
# You will have to create the Secrets Manager secrets separately. For full details, see
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_scram_secret_association
resource "aws_msk_scram_secret_association" "default" {
  count = var.enable_client_sasl_scram && length(var.client_sasl_scram_secret_arns) > 0 ? 1 : 0

  cluster_arn     = aws_msk_cluster.msk.arn
  secret_arn_list = var.client_sasl_scram_secret_arns
}

# ---------------------------------------------------------------------------------------------------------------------
# BROKER STORAGE AUTOSCALING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "msk" {
  max_capacity       = var.broker_storage_autoscaling_max_capacity
  min_capacity       = 1
  role_arn           = var.override_broker_storage_autoscaling_role_arn
  resource_id        = aws_msk_cluster.msk.arn
  scalable_dimension = "kafka:broker-storage:VolumeSize"
  service_namespace  = "kafka"
}

resource "aws_appautoscaling_policy" "msk" {
  name               = "${var.cluster_name}-broker-storage-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_msk_cluster.msk.arn
  scalable_dimension = aws_appautoscaling_target.msk.scalable_dimension
  service_namespace  = aws_appautoscaling_target.msk.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in = var.disable_broker_storage_scale_in
    predefined_metric_specification {
      predefined_metric_type = "KafkaBrokerStorageUtilization"
    }

    target_value = var.broker_storage_autoscaling_target_percentage
  }
}