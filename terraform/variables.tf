variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to the public SSH key to be injected into the instance"
  type        = string
  default     = "k3s-key.pub"
}
