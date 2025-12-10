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

resource "aws_cloudwatch_dashboard" "cs3_main" {
  dashboard_name = "cs3-main-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ECS CPU Utilization
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              aws_ecs_cluster.main.name,
              "ServiceName",
              aws_ecs_service.portal.name
            ]
          ],
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "ECS Portal - CPU Utilization (%)",
          "period" : 60
        }
      },

      # ECS Memory Utilization
      {
        "type" : "metric",
        "x" : 12,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",
              aws_ecs_cluster.main.name,
              "ServiceName",
              aws_ecs_service.portal.name
            ]
          ],
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "ECS Portal - Memory Utilization (%)",
          "period" : 60
        }
      },

      # ALB 5xx errors
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.portal_alb.arn_suffix
            ]
          ],
          "stat" : "Sum",
          "region" : var.aws_region,
          "title" : "ALB 5xx Errors",
          "period" : 60
        }
      },

      # RDS CPU Utilization
      {
        "type" : "metric",
        "x" : 12,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.employee_db.id
            ]
          ],
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "RDS Employee DB - CPU Utilization (%)",
          "period" : 60
        }
      },

      # Lambda Onboarding Error Count
      {
        "type" : "metric",
        "x" : 0,
        "y" : 12,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              aws_lambda_function.onboarding.function_name
            ]
          ],
          "stat" : "Sum",
          "region" : var.aws_region,
          "title" : "Lambda Onboarding - Errors",
          "period" : 60
        }
      },

      # Lambda Offboarding Error Count
      {
        "type" : "metric",
        "x" : 12,
        "y" : 12,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              aws_lambda_function.offboarding.function_name
            ]
          ],
          "stat" : "Sum",
          "region" : var.aws_region,
          "title" : "Lambda Offboarding - Errors",
          "period" : 60
        }
      }
    ]
  })
}