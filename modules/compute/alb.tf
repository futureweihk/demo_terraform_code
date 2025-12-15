# Application Load Balancer Configuration

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = var.alb_name
    }
  )
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = var.target_group_protocol
  }

  deregistration_delay = var.deregistration_delay

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = var.enable_stickiness
  }

  tags = merge(
    var.tags,
    {
      Name = var.target_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "main" {
  count = var.instance_count

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.main[count.index].id
  port             = var.target_group_port

  depends_on = [
    aws_instance.main
  ]
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# # HTTPS Listener
# resource "aws_lb_listener" "https" {
#   count = var.enable_https ? 1 : 0

#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = var.ssl_policy
#   certificate_arn   = var.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }

# # HTTP-only Listener (for environments without SSL certificate)
# resource "aws_lb_listener" "http_forward" {
#   count = var.enable_https ? 0 : 1

#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }
