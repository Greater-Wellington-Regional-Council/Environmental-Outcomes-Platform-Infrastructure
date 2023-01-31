output "secret" {
  description = "The generated secret"
  value       = random_password.secret.result
  sensitive   = true
}
