# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Kafka cluster (e.g. kafka-stage). This variable is used to namespace all resources created by this module."
  type        = string
}

variable "cluster_size" {
  description = "The number of brokers to have in the cluster."
  type        = number
}

variable "kafka_version" {
  description = "Kafka version to install. See https://docs.aws.amazon.com/msk/latest/developerguide/supported-kafka-versions.html for a list of supported versions."
  type        = string
}

variable "instance_type" {
  description = "Specify the instance type to use for the kafka brokers (e.g. `kafka.m5.large`). See https://docs.aws.amazon.com/msk/latest/developerguide/msk-create-cluster.html#broker-instance-types for available instance types."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the cluster."
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs into which the broker instances should be deployed. You should typically pass in one subnet ID per node in the cluster_size variable. The number of broker nodes must be a multiple of subnets. We strongly recommend that you run Kafka in private subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

# General settings
variable "server_properties" {
  type        = map(string)
  default     = {}
  description = "Contents of the server.properties file. Supported properties are documented in the MSK Developer Guide (https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html)."

  # Example:
  #   {
  #     "auto.create.topics.enable" = "true"
  #     "default.replication.factor" = "2"
  #   }
}

variable "enhanced_monitoring" {
  description = "Specify the desired enhanced MSK CloudWatch monitoring level. See https://docs.aws.amazon.com/msk/latest/developerguide/metrics-details.html for valid values."
  type        = string
  default     = "DEFAULT"
}

variable "custom_tags" {
  description = "Custom tags to apply to the Kafka broker nodes and all related resources."
  type        = map(string)
  default     = {}

  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

# Broker storage settings
variable "initial_ebs_volume_size" {
  description = "The initial size of the EBS volume (in GiB) for the data drive on each broker node. "
  type        = number
  default     = 50
}

variable "broker_storage_autoscaling_max_capacity" {
  description = "Max capacity of broker node EBS storage (in GiB)"
  type        = number
  default     = 100
}

variable "broker_storage_autoscaling_target_percentage" {
  description = "Broker storage utilization percentage at which scaling is triggered."
  type        = number
  default     = 70
}

variable "disable_broker_storage_scale_in" {
  description = "Flag indicating whether broker storage should never be scaled in."
  type        = bool
  default     = false
}

variable "override_broker_storage_autoscaling_role_arn" {
  description = "Override automatically created Service-linked role for storage autoscaling. If not provided, Application Auto Scaling creates the appropriate service-linked role for you."
  type        = string
  default     = null
}

# Access settings
variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that will be allowed to connect to the Kafka brokers."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_security_group_ids" {
  description = "A list of security group IDs that will be allowed to connect to the Kafka brokers."
  type        = list(string)
  default     = []
}

# Security group settings
variable "additional_security_group_ids" {
  description = "A list of Security Group IDs that should be added to the MSK cluster broker instances."
  type        = list(string)
  default     = []
}

variable "custom_tags_security_group" {
  description = "A map of custom tags to apply to the Security Group for this MSK Cluster. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}

  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

# Encryption settings
variable "encryption_at_rest_kms_key_arn" {
  description = "You may specify a KMS key short ID or ARN (it will always output an ARN) to use for encrypting your data at rest. If no key is specified, an AWS managed KMS ('aws/msk' managed service) key will be used for encrypting the data at rest."
  type        = string
  default     = null
}

variable "encryption_in_transit_client_broker" {
  description = "Encryption setting for data in transit between clients and brokers. Valid values: TLS, TLS_PLAINTEXT, and PLAINTEXT. Default value is `TLS`."
  type        = string
  default     = "TLS"
}

variable "encryption_in_transit_in_cluster" {
  description = "Whether data communication among broker nodes is encrypted. Default value: true."
  type        = bool
  default     = true
}

# Client settings
variable "enable_client_sasl_scram" {
  description = "Whether SASL SCRAM client authentication is enabled."
  type        = bool
  default     = false
}

variable "client_sasl_scram_secret_arns" {
  description = "List of ARNs for SCRAM secrets stored in the Secrets Manager service."
  type        = list(string)
  default     = []
}

variable "enable_client_sasl_iam" {
  description = "Whether SASL IAM client authentication is enabled."
  type        = bool
  default     = false
}

variable "enable_client_tls" {
  description = "Whether TLS client authentication is enabled."
  type        = bool
  default     = false
}

variable "client_tls_certificate_authority_arns" {
  type        = list(string)
  default     = []
  description = "Optional list of ACM Certificate Authority Amazon Resource Names (ARNs)."
}

# Monitoring settings
variable "open_monitoring_enable_jmx_exporter" {
  description = "Indicates whether you want to enable or disable the Prometheus JMX Exporter."
  type        = bool
  default     = true
}

variable "open_monitoring_enable_node_exporter" {
  description = "Indicates whether you want to enable or disable the Prometheus Node Exporter."
  type        = bool
  default     = true
}

# Logging setting
variable "enable_cloudwatch_logs" {
  description = "Indicates whether you want to enable or disable streaming broker logs to Cloudwatch Logs."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group" {
  description = "Name of the Cloudwatch Log Group to deliver logs to."
  type        = string
  default     = null
}

variable "enable_firehose_logs" {
  description = "Indicates whether you want to enable or disable streaming broker logs to Kinesis Data Firehose."
  type        = bool
  default     = false
}

variable "firehose_delivery_stream" {
  description = "Name of the Kinesis Data Firehose delivery stream to deliver logs to."
  type        = string
  default     = null
}

variable "enable_s3_logs" {
  description = "Indicates whether you want to enable or disable streaming broker logs to S3."
  type        = bool
  default     = false
}

variable "s3_logs_bucket" {
  description = "Name of the S3 bucket to deliver logs to."
  type        = string
  default     = null
}
variable "s3_logs_prefix" {
  description = "Prefix to append to the folder name."
  type        = string
  default     = null
}
