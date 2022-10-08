# ALB
resource "aws_lb" "main" {
  load_balancer_type         = "application"
  name                       = "iac-alb"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false
  security_groups            = [aws_security_group.alb.id]
  subnets = [
    for e in aws_subnet.public : e.id
  ]
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

# SecurityGroup
resource "aws_security_group" "alb" {
  name        = "iac-alb"
  description = "aws to internet"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "iac-alb"
  }
}

# SecurityGroup Rule
resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "alb_outbounds" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB Listener
resource "aws_lb_listener" "http" {

  # 外部からALBが接続を受け付けるポート
  port              = "80"
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ALB TargetGroup
resource "aws_lb_target_group" "main" {
  name = "iac-target-group"

  vpc_id = aws_vpc.main.id
  # ALBからターゲットに対してルーティングするデフォルトのポート番号です｡ECSタスクがLISTENしているポート番号を指定します｡
  port                 = 8080
  target_type          = "ip"
  protocol             = "HTTP"
  deregistration_delay = 300

  # コンテナへの死活監視設定
  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    # ALBからターゲットに対してヘルスチェックを行うポート番号
    port     = 8080
    protocol = "HTTP"
  }

  # target_groupとloadblancerの依存を明示しておかないと、Fargateのサービス作成時にtarget_groupに紐づきのあるLBがないとエラーになる
  depends_on = [
    aws_lb.main
  ]
}
