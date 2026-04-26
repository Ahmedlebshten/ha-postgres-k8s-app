# Fetch the default VPC for simplicity
data "aws_vpc" "default" {
  default = true
}

# Fetch the default subnets to place the EC2 instance
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for the K3s Node
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-node-sg"
  description = "Security group for K3s node allowing SSH, HTTP, HTTPS, and Kubernetes API"
  vpc_id      = data.aws_vpc.default.id

  # SSH access for Ansible and administration
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access for Traefik Ingress
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access for Traefik Ingress
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s API server access
  ingress {
    description = "K3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic to pull images, access DuckDNS, etc.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-node-sg"
  }
}

# Find the latest Ubuntu 24.04 LTS AMI (Noble Numbat)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's official AWS account ID
}

# Create an SSH Key Pair for access
resource "aws_key_pair" "deployer" {
  key_name   = "k3s-deployer-key"
  public_key = file("${path.module}/${var.public_key_path}")
}

# Provision the EC2 Instance
resource "aws_instance" "k3s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  # Automatically assign a public IP address
  associate_public_ip_address = true

  tags = {
    Name = "ai-chat-k3s-node"
  }
}
# Dynamically generate the Ansible inventory file containing the new Public IP
resource "local_file" "ansible_inventory" {
  content  = <<-EOT
[k3s_cluster]
${aws_instance.k3s_node.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/k3s-key
  EOT
  filename = "${path.module}/../ansible/inventory.ini"

  lifecycle {
    replace_triggered_by = [
      aws_instance.k3s_node.public_ip
    ]
  }
}

