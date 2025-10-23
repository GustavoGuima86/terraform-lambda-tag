data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py" # Direct reference to the file
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function resource
resource "aws_lambda_function" "resource_tagger" {
  function_name    = "resource_tagger_lambda"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_tagger_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900 # 15 minutes
  memory_size      = 2048

  package_type = "Zip"

  environment {
    variables = {
      TAGS_JSON = jsonencode(var.tags)
    }
  }
  depends_on = [
    aws_iam_role_policy.lambda_tagger_policy,
    aws_iam_role_policy_attachment.lambda_logs,
    data.archive_file.lambda_zip
  ]
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_tagger_role" {
  name = "lambda_resource_tagger_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Custom policy for resource tagging
resource "aws_iam_role_policy" "lambda_tagger_policy" {
  name = "resource_tagger_policy"
  role = aws_iam_role.lambda_tagger_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowResourceTagDiscoveryAndModification"
      Effect = "Allow"
      Action = [
        "resource-groups:*",
        "tag:*",
        "acm:AddTagsToCertificate",
        "appstream:TagResource",
        "athena:TagResource",
        "cloudfront:TagResource",
        "cloudtrail:AddTags",
        "cloudwatch:TagResource",
        "codebuild:UpdateProject",
        "codepipeline:TagResource",
        "cognito-idp:TagResource",
        "config:TagResource",
        "dax:TagResource",
        "directconnect:TagResource",
        "dms:AddTagsToResource",
        "dynamodb:TagResource",
        "ec2:CreateTags",
        "ecr:TagResource",
        "ecs:TagResource",
        "eks:TagResource",
        "elasticache:AddTagsToResource",
        "elasticbeanstalk:UpdateTagsForResource",
        "elasticfilesystem:TagResource",
        "elasticloadbalancing:AddTags",
        "es:AddTags",
        "events:TagResource",
        "firehose:TagDeliveryStream",
        "fsx:TagResource",
        "glue:TagResource",
        "iam:TagInstanceProfile",
        "iam:TagPolicy",
        "iam:TagRole",
        "iam:TagUser",
        "kinesis:AddTagsToStream",
        "kinesisvideo:TagStream",
        "kms:TagResource",
        "lambda:TagResource",
        "logs:TagResource",
        "mq:CreateTags",
        "opsworks:TagResource",
        "rds:AddTagsToResource",
        "redshift:CreateTags",
        "route53:ChangeTagsForResource",
        "route53resolver:TagResource",
        "s3:PutBucketTagging",
        "s3:PutObjectTagging",
        "sagemaker:AddTags",
        "secretsmanager:TagResource",
        "sns:TagResource",
        "sqs:TagQueue",
        "ssm:AddTagsToResource",
        "transfer:TagResource",
        "waf:TagResource",
        "waf-regional:TagResource",
        "wafv2:TagResource",
        "workspaces:CreateTags",
        "s3:GetBucketTagging"
      ]
      Resource = "*"
    }]
  })
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_tagger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# EventBridge rule to trigger Lambda weekly
resource "aws_cloudwatch_event_rule" "weekly_trigger" {
  name                = "trigger-resource-tagger-weekly"
  description         = "Triggers the resource tagger Lambda function on a schedule"
  schedule_expression = var.schedule_expression
}

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_trigger.name
  target_id = "TriggerResourceTaggerLambda"
  arn       = aws_lambda_function.resource_tagger.arn
}

# Lambda permission to allow EventBridge invocation
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_tagger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_trigger.arn
}
