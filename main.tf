// Possible values for schedule_expression:
// - rate(7 days): runs every 7 days
// - rate(1 hour): runs every hour
// - rate(5 minutes): runs every 5 minutes
// - cron(0 12 * * ? *): runs at 12:00 UTC every day
// See AWS docs: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-schedule-expressions.html

module "tag_lambda" {
  source = "./modules/tag-lambda"
  tags = {
    Environment = "dev"
    Owner       = "Gustavo"
    Project     = "Gustavo"
  }
  schedule_expression = var.schedule_expression
}