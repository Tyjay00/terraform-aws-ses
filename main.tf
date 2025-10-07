# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  count  = var.domain_name != "" ? 1 : 0
  domain = var.domain_name
}

# SES Domain DKIM
resource "aws_ses_domain_dkim" "main" {
  count  = var.domain_name != "" && var.enable_dkim ? 1 : 0
  domain = aws_ses_domain_identity.main[0].domain
}

# Route53 DKIM verification records
resource "aws_route53_record" "dkim" {
  count   = var.domain_name != "" && var.enable_dkim && var.hosted_zone_id != "" ? 3 : 0
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.main[0].dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Route53 verification record for domain identity
resource "aws_route53_record" "domain_verification" {
  count   = var.domain_name != "" && var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main[0].verification_token]
}

# SES Domain Identity Verification
resource "aws_ses_domain_identity_verification" "main" {
  count  = var.domain_name != "" && var.hosted_zone_id != "" ? 1 : 0
  domain = aws_ses_domain_identity.main[0].id

  depends_on = [aws_route53_record.domain_verification]
}

# SES Email Identity (for individual email addresses)
resource "aws_ses_email_identity" "emails" {
  count = length(var.email_addresses)
  email = var.email_addresses[count.index]
}

# SES Configuration Set
resource "aws_ses_configuration_set" "main" {
  count = var.enable_configuration_set ? 1 : 0
  name  = "${var.project_name}-config-set"

  reputation_metrics_enabled = var.enable_reputation_metrics
  delivery_options {
    tls_policy = var.tls_policy
  }

  tags = {
    Name        = "${var.project_name}-config-set"
    Environment = var.environment
  }
}

# SES Event Destination for CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  count                  = var.enable_configuration_set && var.enable_cloudwatch_destination ? 1 : 0
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main[0].name
  enabled                = true
  matching_types         = var.cloudwatch_event_types

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# SES Event Destination for SNS
resource "aws_ses_event_destination" "sns" {
  count                  = var.enable_configuration_set && var.sns_topic_arn != "" ? 1 : 0
  name                   = "sns-destination"
  configuration_set_name = aws_ses_configuration_set.main[0].name
  enabled                = true
  matching_types         = var.sns_event_types

  sns_destination {
    topic_arn = var.sns_topic_arn
  }
}

# SES Receipt Rule Set
resource "aws_ses_receipt_rule_set" "main" {
  count         = var.enable_receipt_rules ? 1 : 0
  rule_set_name = "${var.project_name}-receipt-rules"
}

# SES Receipt Rule
resource "aws_ses_receipt_rule" "main" {
  count         = var.enable_receipt_rules ? 1 : 0
  name          = "${var.project_name}-receipt-rule"
  rule_set_name = aws_ses_receipt_rule_set.main[0].rule_set_name
  recipients    = var.receipt_recipients
  enabled       = true
  scan_enabled  = var.enable_spam_scanning

  dynamic "s3_action" {
    for_each = var.s3_bucket_name != "" ? [1] : []
    content {
      bucket_name       = var.s3_bucket_name
      object_key_prefix = var.s3_object_prefix
      topic_arn         = var.sns_topic_arn != "" ? var.sns_topic_arn : null
    }
  }

  dynamic "lambda_action" {
    for_each = var.lambda_function_arn != "" ? [1] : []
    content {
      function_arn    = var.lambda_function_arn
      invocation_type = var.lambda_invocation_type
      topic_arn       = var.sns_topic_arn != "" ? var.sns_topic_arn : null
    }
  }
}

# Activate Receipt Rule Set
resource "aws_ses_active_receipt_rule_set" "main" {
  count         = var.enable_receipt_rules ? 1 : 0
  rule_set_name = aws_ses_receipt_rule_set.main[0].rule_set_name
}

# SES Identity Policy (for cross-account access)
resource "aws_ses_identity_policy" "main" {
  count    = var.domain_name != "" && var.identity_policy_json != "" ? 1 : 0
  identity = aws_ses_domain_identity.main[0].arn
  name     = "${var.project_name}-identity-policy"
  policy   = var.identity_policy_json
}