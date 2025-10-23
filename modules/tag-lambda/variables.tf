# Variables
variable "tags" {
  type        = map(string)
  description = "A map of tags to be applied to resources"
}

variable "schedule_expression" {
  type        = string
  description = "The EventBridge schedule expression for triggering the Lambda. Examples: 'rate(7 days)', 'rate(1 hour)', 'cron(0 12 * * ? *)'"
}