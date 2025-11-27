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

  timeout = 30

  depends_on = [
    aws_cloudwatch_log_group.lambda_offboarding
  ]

  tags = var.default_tags
}
