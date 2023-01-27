output "secret" {
  description = "The generated secret"
  value       = random_password.secret.result
  # TODO: Check this is required to reference the output from other modules. 
  sensitive   = true
}
