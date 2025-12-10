data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "cs3-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = var.default_tags
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "cs3-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = var.default_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_logs" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Lambda assume role

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_onboarding_role" {
  name               = "cs3-lambda-onboarding-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = var.default_tags
}

resource "aws_iam_role" "lambda_offboarding_role" {
  name               = "cs3-lambda-offboarding-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = var.default_tags
}

# Lambda invoke role

data "aws_iam_policy_document" "ecs_invoke_lambda" {
  statement {
    sid    = "AllowInvokeOnOnboardingOffboarding"
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      aws_lambda_function.onboarding.arn,
      aws_lambda_function.offboarding.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_invoke_lambda" {
  name   = "cs3-ecs-invoke-lambda"
  policy = data.aws_iam_policy_document.ecs_invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_invoke_lambda" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_invoke_lambda.arn
}

# Policies for Lambda: logs + IAM management

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "IAMUserManagement"
    effect = "Allow"

    actions = [
      "iam:GetUser",
      "iam:CreateUser",
      "iam:TagUser",
      "iam:GetGroup",
      "iam:CreateGroup",
      "iam:AddUserToGroup",
      "iam:ListGroupsForUser",
      "iam:RemoveUserFromGroup"
    ]

    resources = ["*"]
  }
  statement {
    sid    = "LambdaVPCAccess"
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "cs3-lambda-onoff-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_onboarding_attach" {
  role       = aws_iam_role.lambda_onboarding_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_offboarding_attach" {
  role       = aws_iam_role.lambda_offboarding_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
