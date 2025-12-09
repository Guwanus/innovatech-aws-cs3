resource "aws_ecs_cluster" "main" {
  name = "cs3-ecs-cluster"

  tags = var.default_tags
}

resource "aws_ecs_task_definition" "portal" {
  family                   = "cs3-portal-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "portal"
      image     = var.portal_image
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.employee_db.address },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "ONBOARDING_LAMBDA_ARN", value = aws_lambda_function.onboarding.arn },
        { name = "OFFBOARDING_LAMBDA_ARN", value = aws_lambda_function.offboarding.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_portal.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.default_tags
}

resource "aws_ecs_service" "portal" {
  name            = "cs3-portal-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.portal.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.portal_tg.arn
    container_name   = "portal"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = var.default_tags
}
