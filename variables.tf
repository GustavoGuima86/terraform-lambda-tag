variable "aws_region" {
  type = string
  default = "eu-central-1"
  description = "Region where the resources will be deployed"
}

variable "schedule_expression" {
  type = string
  default = "rate(7 days)"
  description = "The EventBridge schedule expression for triggering the Lambda. Examples: 'rate(7 days)', 'rate(1 hour)', 'cron(0 12 * * ? *)'"
}