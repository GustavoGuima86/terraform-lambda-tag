"""
AWS Lambda function to automatically tag AWS resources.
This version processes each resource individually and checks the API response
for failures.
"""

import os
import logging
import boto3
import json

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Main Lambda handler function that processes and tags AWS resources."""
    # Get the tags from Lambda environment variable
    tags_json = os.environ.get("TAGS_JSON")
    if not tags_json:
        logger.error("FATAL: TAGS_JSON environment variable must be set.")
        return {
            "statusCode": 400,
            "body": "TAGS_JSON environment variable must be set.",
        }
    try:
        tags_to_apply = json.loads(tags_json)
        if not isinstance(tags_to_apply, dict) or not tags_to_apply:
            raise ValueError("TAGS_JSON must be a non-empty JSON object.")
    except Exception as e:
        logger.error(f"FATAL: Failed to parse TAGS_JSON: {str(e)}")
        return {
            "statusCode": 400,
            "body": f"Failed to parse TAGS_JSON: {str(e)}",
        }

    logger.info(f"Searching for resources missing tags: {tags_to_apply}")
    tagging_client = boto3.client("resourcegroupstaggingapi")
    arns_to_tag = []

    # Specify the resource types we want to tag
    resource_types = [
        # Compute
        "ec2:*",
        "ec2:vpc",
        "ec2:subnet",
        "ec2:instance",
        "ec2:network-interface",
        "ec2:security-group",
        "ec2:volume",
        "ec2:snapshot",
        "autoscaling:*",
        "lambda:*",
        "eks:*",
        "ecs:*",
        # Containers
        "ecr:repository",
        "eks:cluster",
        # Storage
        "s3:*",
        # Database
        "rds:*",
        "dynamodb:*",
        "elasticache:*",
        "redshift:*",
        # Networking
        "elasticloadbalancing:*",
        "apigateway:*",
        "route53:*",
        "cloudfront:*",
        # Analytics
        "kinesis:*",
        "glue:*",
        # Security
        "kms:*",
        "secretsmanager:*",
        "acm:*",
        # Integration
        "sns:*",
        "sqs:*",
        "events:*",
        # Monitoring
        "cloudwatch:*",
        "logs:*",
    ]

    paginator = tagging_client.get_paginator("get_resources")
    pages = paginator.paginate(
        ResourcesPerPage=100,
        ResourceTypeFilters=resource_types,
    )

    for page in pages:
        for resource in page["ResourceTagMappingList"]:
            tags = {tag["Key"]: tag["Value"] for tag in resource.get("Tags", [])}
            missing_tags = {k: v for k, v in tags_to_apply.items() if tags.get(k) != v}
            if missing_tags:
                arns_to_tag.append(resource["ResourceARN"])

    if not arns_to_tag:
        msg = f"✅ All taggable resources already have the correct tags: {tags_to_apply}"
        logger.info(f"{msg}. No action needed.")
        return {"statusCode": 200, "body": "No resources needed tagging."}

    logger.info(f"Found {len(arns_to_tag)} resources to tag. Applying tags individually...")

    success_count = 0
    failure_count = 0

    for arn in arns_to_tag:
        try:
            logger.info(f"Attempting to tag resource: {arn}")
            response = tagging_client.tag_resources(
                ResourceARNList=[arn],
                Tags=tags_to_apply,
            )

            if response.get("FailedResourcesMap") and arn in response.get("FailedResourcesMap"):
                failure_details = response["FailedResourcesMap"][arn]
                error_msg = f"❌ API reported failure for {arn}. " f"ErrorCode: {failure_details.get('ErrorCode')}, " f"ErrorMessage: {failure_details.get('ErrorMessage')}"
                logger.error(error_msg)
                failure_count += 1
            else:
                success_count += 1

        except Exception as e:
            logger.error(f"❌ Exception while tagging {arn}: {str(e)}")
            failure_count += 1

    logger.info("--- Tagging Summary ---")
    logger.info(f"Successfully tagged: {success_count} resources")
    logger.info(f"Failed to tag: {failure_count} resources")

    return {
        "statusCode": 200,
        "body": f"Tagging process complete. Success: {success_count}, Failed: {failure_count}.",
    }
