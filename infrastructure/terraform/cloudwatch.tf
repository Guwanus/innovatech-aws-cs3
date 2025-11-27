resource "aws_cloudwatch_log_group" "ecs_portal" {
  name              = "/ecs/cs3-portal"
  retention_in_days = 7

  tags = var.default_tags
}

resource "aws_cloudwatch_log_group" "lambda_onboarding" {
  name              = "/aws/lambda/cs3-onboarding"
  retention_in_days = 7

  tags = var.default_tags
}

resource "aws_cloudwatch_log_group" "lambda_offboarding" {
  name              = "/aws/lambda/cs3-offboarding"
  retention_in_days = 7

  tags = var.default_tags
}
