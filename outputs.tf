output "app_instance_ip" {
  description = "Public IP of the App instance"
  value       = aws_eip.public_eip.public_ip
}

output "db_instance_ip" {
  description = "Private IP of the DB instance"
  value       = aws_network_interface.eni3.private_ip
}