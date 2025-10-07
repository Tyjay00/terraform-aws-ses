variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Domain name for SES identity"
  type        = string
  default     = ""
}

variable "email_addresses" {
  description = "List of email addresses to verify"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS verification"
  type        = string
  default     = ""
}

variable "enable_dkim" {
  description = "Whether to enable DKIM for the domain"
  type        = bool
  default     = true
}

variable "enable_configuration_set" {
  description = "Whether to create SES configuration set"
  type        = bool
  default     = false
}

variable "enable_reputation_metrics" {
  description = "Whether to enable reputation metrics"
  type        = bool
  default     = true
}

variable "tls_policy" {
  description = "TLS policy for delivery options"
  type        = string
  default     = "Require"
  
  validation {
    condition     = contains(["Require", "Optional"], var.tls_policy)
    error_message = "TLS policy must be either 'Require' or 'Optional'."
  }
}

variable "enable_cloudwatch_destination" {
  description = "Whether to enable CloudWatch event destination"
  type        = bool
  default     = false
}

variable "cloudwatch_event_types" {
  description = "List of event types to send to CloudWatch"
  type        = list(string)
  default     = ["send", "reject", "bounce", "complaint"]
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for SES notifications"
  type        = string
  default     = ""
}

variable "sns_event_types" {
  description = "List of event types to send to SNS"
  type        = list(string)
  default     = ["bounce", "complaint"]
}

variable "enable_receipt_rules" {
  description = "Whether to enable SES receipt rules"
  type        = bool
  default     = false
}

variable "receipt_recipients" {
  description = "List of recipient email addresses for receipt rules"
  type        = list(string)
  default     = []
}

variable "enable_spam_scanning" {
  description = "Whether to enable spam and virus scanning"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for storing received emails"
  type        = string
  default     = ""
}

variable "s3_object_prefix" {
  description = "S3 object prefix for stored emails"
  type        = string
  default     = "emails/"
}

variable "lambda_function_arn" {
  description = "Lambda function ARN for processing emails"
  type        = string
  default     = ""
}

variable "lambda_invocation_type" {
  description = "Lambda invocation type"
  type        = string
  default     = "Event"
  
  validation {
    condition     = contains(["Event", "RequestResponse"], var.lambda_invocation_type)
    error_message = "Lambda invocation type must be either 'Event' or 'RequestResponse'."
  }
}

variable "identity_policy_json" {
  description = "SES identity policy in JSON format"
  type        = string
  default     = ""
}