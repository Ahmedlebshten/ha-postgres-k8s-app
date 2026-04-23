output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.k3s_node.public_ip
}
