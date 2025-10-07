output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].arn : ""
}

output "domain_identity_verification_token" {
  description = "Domain identity verification token"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].verification_token : ""
}

output "dkim_tokens" {
  description = "DKIM tokens for DNS verification"
  value       = var.domain_name != "" && var.enable_dkim ? aws_ses_domain_dkim.main[0].dkim_tokens : []
}

output "email_identities" {
  description = "List of verified email identities"
  value       = [for email in aws_ses_email_identity.emails : email.email]
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = var.enable_configuration_set ? aws_ses_configuration_set.main[0].name : ""
}

output "configuration_set_arn" {
  description = "ARN of the SES configuration set"
  value       = var.enable_configuration_set ? aws_ses_configuration_set.main[0].arn : ""
}

output "receipt_rule_set_name" {
  description = "Name of the SES receipt rule set"
  value       = var.enable_receipt_rules ? aws_ses_receipt_rule_set.main[0].rule_set_name : ""
}