# Example: you uploaded lambda/onboarding.zip and offboarding.zip to S3

variable "lambda_code_bucket" {
  description = "S3 bucket holding Lambda deployment packages"
  type        = string
}

resource "aws_lambda_function" "onboarding" {
  function_name = "cs3-onboarding"
  role          = aws_iam_role.lambda_onboarding_role.arn
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"

  s3_bucket = var.lambda_code_bucket
  s3_key    = "onboarding.zip"

  environment {
    variables = {
      DB_HOST     = aws_db_instance.employee_db.address
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT     = "3306"
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  timeout = 30

  depends_on = [
    aws_cloudwatch_log_group.lambda_onboarding
  ]

  tags = var.default_tags
}

resource "aws_lambda_function" "offboarding" {
  function_name = "cs3-offboarding"
  role          = aws_iam_role.lambda_offboarding_role.arn
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"

  s3_bucket = var.lambda_code_bucket
  s3_key    = "offboarding.zip"

  environment {
    variables = {
      DB_HOST     = aws_db_instance.employee_db.address
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_PORT     = "3306"
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  timeout = 30

  depends_on = [
    aws_cloudwatch_log_group.lambda_offboarding
  ]

  tags = var.default_tags
}

resource "aws_security_group" "lambda_sg" {
  name        = "cs3-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  # Lambda mag outbound overal naartoe (voor RDS verkeer)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.default_tags,
    { Name = "cs3-lambda-sg" }
  )
}

resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}
