data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "instance" {
  name_prefix = "${var.environment}-instance-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (GitHub Actions)
    description = "SSH access for deployment automation"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RDP access for Windows"
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "WinRM for Ansible (HTTP and HTTPS)"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment}-instance-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "instance" {
  name_prefix = "${var.environment}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name_prefix = "${var.environment}-instance-profile"
  role        = aws_iam_role.instance.name
}

resource "aws_instance" "app" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_name

  # Use public subnets for GitHub Actions access
  subnet_id             = element(var.public_subnet_ids, count.index % length(var.public_subnet_ids))
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  # Enable public IP for SSH access from GitHub Actions
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from ${var.environment} - Instance ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name           = "${var.environment}-instance-${count.index + 1}"
    Environment    = var.environment
    AnsibleManaged = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Windows Server Instance
resource "aws_instance" "windows" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.instance_type
  key_name              = var.key_name

  subnet_id              = element(var.public_subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  associate_public_ip_address = true

  user_data = <<-EOF
    <powershell>
    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools

    # Create simple webpage
    Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<h1>Hello from ${var.environment} - Windows Server</h1>"

    # Enable WinRM for Ansible
    winrm quickconfig -q
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    # Set Administrator password (retrieve from Secrets Manager in production)
    # For demo, use a temporary password that will be changed via Ansible

    # Configure firewall for WinRM
    netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
    netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow

    # Restart WinRM service
    Restart-Service winrm
    </powershell>
    EOF

  tags = {
    Name           = "${var.environment}-windows-instance"
    Environment    = var.environment
    OS             = "Windows"
    AnsibleManaged = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}
