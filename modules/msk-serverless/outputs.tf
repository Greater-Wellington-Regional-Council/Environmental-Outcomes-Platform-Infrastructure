output "cluster_name" {
  description = "Name of the MSK cluster."
  value       = aws_msk_cluster.msk.cluster_name
}

output "cluster_arn" {
  description = "ARN of the MSK cluster."
  value       = aws_msk_cluster.msk.arn
}

output "cluster_current_version" {
  description = "Current version of the MSK Cluster used for updates"
  value       = aws_msk_cluster.msk.current_version
}

output "bootstrap_brokers" {
  description = "A comma separated list of one or more hostname:port pairs of kafka brokers suitable to boostrap connectivity to the kafka cluster"
  value       = aws_msk_cluster.msk.bootstrap_brokers
}

output "bootstrap_brokers_tls" {
  description = "A comma separated list of one or more DNS names (or IPs) and TLS port pairs kafka brokers suitable to boostrap connectivity to the kafka cluster"
  value       = aws_msk_cluster.msk.bootstrap_brokers_tls
}

output "bootstrap_brokers_scram" {
  description = "A comma separated list of one or more DNS names (or IPs) and TLS port pairs kafka brokers suitable to boostrap connectivity using SASL/SCRAM to the kafka cluster."
  value       = aws_msk_cluster.msk.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_iam" {
  description = "A comma separated list of one or more DNS names (or IPs) and TLS port pairs kafka brokers suitable to boostrap connectivity using SASL/IAM to the kafka cluster."
  value       = aws_msk_cluster.msk.bootstrap_brokers_sasl_iam
}

output "zookeeper_connect_string" {
  description = "A comma separated list of one or more hostname:port pairs to use to connect to the Apache Zookeeper cluster"
  value       = aws_msk_cluster.msk.zookeeper_connect_string
}

output "zookeeper_connect_string_tls" {
  description = "A comma separated list of one or more hostname:port pairs to use to connect to the Apache Zookeeper cluster"
  value       = aws_msk_cluster.msk.zookeeper_connect_string_tls
}

output "msk_config_arn" {
  description = "ARN of the MSK configuration."
  value       = aws_msk_configuration.msk.arn
}

output "msk_config_latest_revision" {
  description = "Latest revision of the MSK configuration."
  value       = aws_msk_configuration.msk.latest_revision
}

output "security_group_id" {
  description = "The ID of the cluster security group."
  value       = aws_security_group.msk.id
}

output "security_group_name" {
  description = "The name of the cluster security group."
  value       = aws_security_group.msk.name
}

output "cluster_topic_arn_prefix" {
  description = "Topic ARN prefix (without trailing '/') to help creating IAM policies, e.g. 'arn:aws:kafka:us-east-1:0123456789012:topic/MyTestCluster'"
  value       = local.cluster_topic_arn_prefix
}

output "cluster_group_arn_prefix" {
  description = "Group ARN prefix (without trailing '/') to help creating IAM policies, e.g. 'arn:aws:kafka:us-east-1:0123456789012:group/MyTestCluster'"
  value       = local.cluster_group_arn_prefix
}
