# # ECS Task Execution Role
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "${var.app_name}-ecs-task-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # ECS Task Role
# resource "aws_iam_role" "ecs_task_role" {
#   name = "${var.app_name}-ecs-task-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# # Allow accessing secrets from Secrets Manager
# resource "aws_iam_policy" "ecs_task_policy" {
#   name = "${var.app_name}-ecs-task-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject"
#         ]
#         Resource = "${aws_s3_bucket.frontend.arn}/*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = aws_iam_policy.ecs_task_policy.arn
# }

# # Security Group for ECS Tasks
# resource "aws_security_group" "ecs_tasks" {
#   name   = "${var.app_name}-ecs-tasks-sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port       = 8081
#     to_port         = 8084
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }

#   ingress {
#     from_port       = 3000
#     to_port         = 3000
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.app_name}-ecs-tasks-sg"
#   }
# }

# # API Gateway for Microservices
# resource "aws_apigatewayv2_api" "main" {
#   name          = "${var.app_name}-api"
#   protocol_type = "HTTP"

#   cors_configuration {
#     allow_origins = ["*"]
#     allow_methods = ["*"]
#     allow_headers = ["*"]
#   }

#   tags = {
#     Name = "${var.app_name}-api-gateway"
#   }
# }

# resource "aws_apigatewayv2_stage" "main" {
#   api_id      = aws_apigatewayv2_api.main.id
#   name        = var.environment
#   auto_deploy = true

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.api_gateway.arn
#     format         = jsonencode({
#       requestId         = "$context.requestId"
#       ip                = "$context.identity.sourceIp"
#       requestTime       = "$context.requestTime"
#       httpMethod        = "$context.httpMethod"
#       resourcePath      = "$context.resourcePath"
#       status            = "$context.status"
#       protocol          = "$context.protocol"
#       responseLength    = "$context.responseLength"
#       integrationLatency = "$context.integration.latency"
#     })
#   }
# }

# resource "aws_cloudwatch_log_group" "api_gateway" {
#   name              = "/aws/api-gateway/${var.app_name}"
#   retention_in_days = 7
# }

# # CloudWatch Alarms
# resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
#   alarm_name          = "${var.app_name}-alb-response-time"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "TargetResponseTime"
#   namespace           = "AWS/ApplicationELB"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "1"
#   alarm_description   = "Alert when ALB response time is high"

#   dimensions = {
#     LoadBalancer = aws_lb.main.arn_suffix
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "ecs_cpu_utilization" {
#   alarm_name          = "${var.app_name}-ecs-cpu-utilization"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "80"
#   alarm_description   = "Alert when ECS CPU utilization is high"

#   dimensions = {
#     ClusterName = aws_ecs_cluster.main.name
#   }
# }
