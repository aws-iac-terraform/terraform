# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "iac_ecs"
}

# ECS Task 定義
resource "aws_ecs_task_definition" "main" {
  family                   = "sample-app"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_execution.arn
  execution_role_arn       = aws_iam_role.task_execution.arn
  container_definitions    = <<EOL
[
  {
    "name": "sample-app",
    "image": "${data.aws_caller_identity.self.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/sample-app:latest",
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "environment": [
      { "name": "MY_ENV_VAR", "value": "環境変数です。" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-northeast-1",
        "awslogs-group": "${aws_cloudwatch_log_group.sample_app.name}",
        "awslogs-stream-prefix": "sample-app"
      }
    }
  }
]
EOL
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                              = "ecs-service"
  cluster                           = aws_ecs_cluster.main.arn
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  deployment_controller {
    # TODO CodeDeployを使う場合
    # type = "CODE_DEPLOY"
    type = "ECS"
  }

  network_configuration {
    # assign_public_ip = false
    security_groups = [aws_security_group.sample_app.id]
    subnets = [
      for e in aws_subnet.private : e.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "sample-app"
    container_port   = 8080
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# SecurityGroup
resource "aws_security_group" "sample_app" {
  name        = "sample_app"
  description = "sample_app_security_group"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "iac-alb"
  }
}
# SecurityGroup Rule
resource "aws_security_group_rule" "sample_app_http_inbound" {
  security_group_id = aws_security_group.sample_app.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sample_app_java_inbound" {
  security_group_id = aws_security_group.sample_app.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "sample_app_outbound" {
  security_group_id = aws_security_group.sample_app.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# IMA ROLE
resource "aws_iam_role" "task_execution" {
  name               = "TaskExecution"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM ROLE POLICY 
resource "aws_iam_role_policy" "task_execution" {
  role   = aws_iam_role.task_execution.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# IAM ROLE POLICY ATTACHMENT
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch
resource "aws_cloudwatch_log_group" "sample_app" {
  name = "sample-app-log-group"
}
