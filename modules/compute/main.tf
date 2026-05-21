# Look up the latest official Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Application Load Balancer (Public Facing)
resource "aws_lb" "main" {
  name               = "${var.environment}-epicbook-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.environment}-alb"
  }
}

# 2. ALB Target Group (Routes traffic to your app on port 3000)
resource "aws_lb_target_group" "app" {
  name     = "${var.environment}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = tostring(var.app_port)
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.environment}-target-group"
  }
}

# 3. ALB Listener (Listens on public port 80 and forwards to Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 4. EC2 Launch Template (Blueprint for instances launched by ASG)
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-epicbook-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_sg_id]

  # Attach the Identity Profile created in Layer 2
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  # Script to provision the server at boot time
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Stop execution if any command fails
              set -e

              # Update system and install the Docker engine
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker

              sudo sed -i 's/listen 80 default_server;/listen ${var.app_port} default_server;/' /etc/nginx/sites-available/default
              sudo sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:${var.app_port} default_server;/' /etc/nginx/sites-available/default

              sudo systemctl restart nginx
              echo "<h1>EpicBook Dev Infra is Live on Port ${var.app_port}</h1>" | sudo tee /var/www/html/index.html

              # Ensure the default ubuntu user can interact with Docker safely
              usermod -aG docker ubuntu
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 5. Auto Scaling Group (Deploys and maintains instances across private subnets)
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-epicbook-asg"
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = var.app_port

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.environment}-epicbook-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_iam_role" "ec2_profile" {
  name = "${var.environment}-epicbook-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-epicbook-instance-profile"
  role = aws_iam_role.ec2_profile.name
}