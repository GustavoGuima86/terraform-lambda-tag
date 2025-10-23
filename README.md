# terraform-lambda-tag

## Project Description
This Terraform module deploys an AWS Lambda function that automatically tags AWS resources. It is designed to be reusable and configurable, allowing you to specify multiple tags and schedule the Lambda execution using CloudWatch Events.

## Usage

### Direct Usage
To use this module directly in your Terraform project:

```hcl
module "tag_lambda" {
  source              = "./modules/tag-lambda" # or the relative path to the module
  tags                = {
    "Environment" = "Production"
    "Owner"       = "DevOps"
  }
  schedule_expression = "rate(1 day)" # See below for possible values
}
```

### Referencing from an External Repository
If your module is published in a public Git repository, you can reference it from another Terraform project like this:

```hcl
module "tag_lambda" {
  source              = "git::https://github.com/GustavoGuima86/terraform-lambda-tag.git//modules/tag-lambda?ref=main"
  tags                = {
    "Environment" = "Production"
    "Owner"       = "DevOps"
  }
  schedule_expression = "rate(1 day)"
}
```
Replace `<your-org>` and `<version-or-branch>` with your repository details.

## schedule_expression Parameter
This parameter defines when the Lambda function is triggered. It accepts CloudWatch Events schedule expressions:

- `rate(<value> <unit>)` (e.g., `rate(5 minutes)`, `rate(1 hour)`, `rate(1 day)`)
- `cron(<cron-expression>)` (e.g., `cron(0 12 * * ? *)` for every day at 12:00 UTC)

Refer to [AWS Schedule Expressions for Rules](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html) for more details.

## Requirements
- Terraform >= 0.13
- AWS provider

## License
MIT
