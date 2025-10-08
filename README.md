# Terraform AWS SES Module 📧

> **Enterprise email service with automated templates, bounce handling, reputation management, and compliance features**

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.3-623CE4?logo=terraform)](https://terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-%E2%89%A5%205.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 **Overview**

This Terraform module creates and manages AWS Simple Email Service (SES) infrastructure with domain verification, email templates, configuration sets, and comprehensive monitoring. Designed for production email systems requiring high deliverability, compliance, and automation.

## 🚀 **Features**

### **Core Email Services**
- 📧 **Domain Verification** - Automated domain and email verification
- 📝 **Email Templates** - Dynamic template management
- 📊 **Configuration Sets** - Email tracking and analytics
- 🔄 **Bounce Handling** - Automated bounce and complaint processing
- 📈 **Reputation Tracking** - Sender reputation monitoring
- 🎯 **Suppression Lists** - Automated unsubscribe management

### **Advanced Features**
- 🔒 **DKIM Signing** - Email authentication and security
- 📋 **SPF/DMARC Support** - Anti-spoofing protection
- 🌐 **Multi-Region Setup** - Global email delivery
- 📊 **CloudWatch Integration** - Comprehensive email metrics
- 🚨 **Event Publishing** - Real-time email event streaming
- 🔐 **IAM Integration** - Secure access control

## 📋 **Usage**

### **Basic Email Domain Setup**
```hcl
module "email_service" {
  source = "./terraform-aws-ses"

  # Primary Domain
  domain_name = "company.com"
  
  # Domain Verification
  verify_domain = true
  verify_dkim   = true
  
  # Email Addresses
  verified_email_addresses = [
    "noreply@company.com",
    "support@company.com",
    "alerts@company.com"
  ]
  
  # Basic Configuration Set
  configuration_sets = {
    default = {
      name                     = "default-config-set"
      delivery_delay          = false
      reputation_tracking     = true
      sending_enabled         = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          default_value = 0
          dimensions = {
            MessageTag  = "emailType"
            LinkTag     = "linkType"
          }
        }
      }
    }
  }
  
  project_name = "company-email"
  environment  = "production"
  
  tags = {
    Service = "email"
    Team    = "platform"
  }
}
```

### **Transactional Email System**
```hcl
module "transactional_email" {
  source = "./terraform-aws-ses"

  domain_name = "notifications.company.com"
  
  # Domain Configuration
  verify_domain = true
  verify_dkim   = true
  mail_from_domain = "mail.notifications.company.com"
  
  # Verified Email Addresses
  verified_email_addresses = [
    "no-reply@notifications.company.com",
    "welcome@notifications.company.com",
    "billing@notifications.company.com",
    "security@notifications.company.com"
  ]
  
  # Email Templates
  email_templates = {
    welcome_email = {
      template_name = "WelcomeEmail"
      subject       = "Welcome to {{company_name}}!"
      html_part     = file("${path.module}/templates/welcome.html")
      text_part     = file("${path.module}/templates/welcome.txt")
    }
    
    password_reset = {
      template_name = "PasswordReset"
      subject       = "Reset your password"
      html_part     = file("${path.module}/templates/password-reset.html")
      text_part     = file("${path.module}/templates/password-reset.txt")
    }
    
    billing_notification = {
      template_name = "BillingNotification"
      subject       = "Your invoice from {{company_name}}"
      html_part     = file("${path.module}/templates/billing.html")
      text_part     = file("${path.module}/templates/billing.txt")
    }
    
    security_alert = {
      template_name = "SecurityAlert"
      subject       = "Security Alert - {{alert_type}}"
      html_part     = file("${path.module}/templates/security-alert.html")
      text_part     = file("${path.module}/templates/security-alert.txt")
    }
  }
  
  # Configuration Sets with Event Tracking
  configuration_sets = {
    transactional = {
      name               = "transactional-emails"
      delivery_delay     = false
      reputation_tracking = true
      sending_enabled    = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          default_value = 0
          dimensions = {
            MessageTag = "emailType"
            Template   = "templateName"
            Campaign   = "campaignId"
          }
        }
        
        sns = {
          enabled   = true
          topic_arn = aws_sns_topic.email_events.arn
          events    = ["send", "reject", "bounce", "complaint", "delivery"]
        }
        
        kinesis = {
          enabled     = true
          stream_arn  = aws_kinesis_stream.email_events.arn
          role_arn    = aws_iam_role.ses_kinesis.arn
          events      = ["send", "bounce", "complaint", "delivery", "open", "click"]
        }
      }
    }
    
    marketing = {
      name               = "marketing-emails"
      delivery_delay     = true
      reputation_tracking = true
      sending_enabled    = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          default_value = 0
          dimensions = {
            MessageTag = "campaignType"
            Segment    = "userSegment"
          }
        }
      }
    }
  }
  
  # Bounce and Complaint Handling
  bounce_topic_arn    = aws_sns_topic.bounces.arn
  complaint_topic_arn = aws_sns_topic.complaints.arn
  
  # Sending Quotas and Rate Limits
  sending_quota = {
    max_24_hour_send = 10000
    max_send_rate    = 5  # emails per second
  }
  
  project_name = "transactional-email"
  environment  = "production"
}
```

### **Multi-Region Email Service**
```hcl
# Primary Region (US-East-1)
module "email_primary" {
  source = "./terraform-aws-ses"
  
  providers = {
    aws = aws.us_east_1
  }

  domain_name = "global.company.com"
  
  # Regional Configuration
  region_name  = "us-east-1"
  verify_domain = true
  verify_dkim   = true
  
  # Configuration Set
  configuration_sets = {
    us_east = {
      name               = "us-east-emails"
      reputation_tracking = true
      sending_enabled    = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          dimensions = {
            Region = "us-east-1"
            MessageTag = "emailType"
          }
        }
      }
    }
  }
  
  project_name = "global-email"
  environment  = "production"
}

# Secondary Region (EU-West-1)
module "email_secondary" {
  source = "./terraform-aws-ses"
  
  providers = {
    aws = aws.eu_west_1
  }

  domain_name = "global.company.com"
  
  # Regional Configuration
  region_name  = "eu-west-1"
  verify_domain = true
  verify_dkim   = true
  
  # Configuration Set
  configuration_sets = {
    eu_west = {
      name               = "eu-west-emails"
      reputation_tracking = true
      sending_enabled    = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          dimensions = {
            Region = "eu-west-1"
            MessageTag = "emailType"
          }
        }
      }
    }
  }
  
  # GDPR Compliance Features
  enable_gdpr_compliance = true
  data_retention_days    = 2555  # 7 years
  
  project_name = "global-email"
  environment  = "production"
}
```

### **Advanced Email Analytics and Monitoring**
```hcl
module "email_analytics" {
  source = "./terraform-aws-ses"

  domain_name = "analytics.company.com"
  
  # Enhanced Monitoring Configuration
  configuration_sets = {
    analytics = {
      name               = "analytics-emails"
      reputation_tracking = true
      sending_enabled    = true
      
      event_destinations = {
        cloudwatch = {
          enabled = true
          default_value = 0
          dimensions = {
            MessageTag     = "emailType"
            Campaign       = "campaignId"
            UserSegment    = "segment"
            ABTestVariant  = "variant"
            SendingIP      = "ip"
          }
        }
        
        kinesis_firehose = {
          enabled          = true
          delivery_stream_arn = aws_kinesis_firehose_delivery_stream.email_analytics.arn
          role_arn         = aws_iam_role.ses_firehose.arn
          events           = ["send", "bounce", "complaint", "delivery", "open", "click", "renderingFailure"]
        }
        
        pinpoint = {
          enabled        = true
          application_arn = aws_pinpoint_app.email_campaigns.arn
          role_arn       = aws_iam_role.ses_pinpoint.arn
          events         = ["send", "bounce", "complaint", "delivery"]
        }
      }
    }
  }
  
  # Advanced Email Templates with A/B Testing
  email_templates = {
    newsletter_variant_a = {
      template_name = "NewsletterVariantA"
      subject       = "Weekly Update from {{company_name}}"
      html_part     = file("${path.module}/templates/newsletter-a.html")
      text_part     = file("${path.module}/templates/newsletter-a.txt")
    }
    
    newsletter_variant_b = {
      template_name = "NewsletterVariantB"
      subject       = "This Week at {{company_name}}"
      html_part     = file("${path.module}/templates/newsletter-b.html")
      text_part     = file("${path.module}/templates/newsletter-b.txt")
    }
    
    promotional_offer = {
      template_name = "PromotionalOffer"
      subject       = "Special Offer: {{discount_percentage}}% off!"
      html_part     = file("${path.module}/templates/promotional.html")
      text_part     = file("${path.module}/templates/promotional.txt")
    }
  }
  
  # Custom Tracking Configuration
  custom_tracking_config = {
    open_tracking   = true
    click_tracking  = true
    unsubscribe_tracking = true
    
    # Custom domains for tracking
    tracking_domain = "track.company.com"
    unsubscribe_domain = "unsub.company.com"
  }
  
  # Reputation Management
  reputation_management = {
    enable_feedback_forwarding = true
    enable_bounce_notifications = true
    enable_complaint_notifications = true
    
    # Automatic suppression
    enable_auto_suppression = true
    suppression_reasons = ["bounce", "complaint"]
  }
  
  project_name = "email-analytics"
  environment  = "production"
}
```

### **Compliance and Security Setup**
```hcl
module "secure_email" {
  source = "./terraform-aws-ses"

  domain_name = "secure.company.com"
  
  # Security Configuration
  verify_domain = true
  verify_dkim   = true
  
  # DKIM Configuration
  dkim_tokens = true
  dkim_signing_enabled = true
  
  # Mail-From Domain
  mail_from_domain = "mail.secure.company.com"
  mail_from_behavior_on_mx_failure = "RejectMessage"
  
  # Security Headers and Policies
  security_policy = {
    tls_policy           = "Require"
    dmarc_policy         = "quarantine"
    spf_record          = "v=spf1 include:amazonses.com ~all"
    dkim_signing        = true
    feedback_forwarding = false
  }
  
  # Compliance Features
  compliance_config = {
    enable_encryption_at_rest = true
    enable_encryption_in_transit = true
    data_residency_region = "us-east-1"
    retention_policy_days = 2555  # 7 years for financial compliance
    
    # Audit logging
    enable_cloudtrail_logging = true
    log_api_calls = true
    log_email_events = true
  }
  
  # Configuration Set with Security Focus
  configuration_sets = {
    secure = {
      name               = "secure-emails"
      reputation_tracking = true
      sending_enabled    = true
      
      # Enhanced event tracking for security
      event_destinations = {
        cloudwatch = {
          enabled = true
          dimensions = {
            SecurityLevel = "high"
            Compliance   = "required"
            DataType     = "sensitive"
          }
        }
        
        security_hub = {
          enabled = true
          finding_format = "ASFF"
          events = ["bounce", "complaint", "reject"]
        }
      }
    }
  }
  
  # Identity Policies for Cross-Account Access
  identity_policies = {
    cross_account = {
      policy_name = "CrossAccountEmailSending"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::123456789012:root"
            }
            Action = [
              "ses:SendEmail",
              "ses:SendRawEmail"
            ]
            Resource = "*"
            Condition = {
              StringEquals = {
                "ses:FromAddress" = [
                  "noreply@secure.company.com",
                  "alerts@secure.company.com"
                ]
              }
            }
          }
        ]
      })
    }
  }
  
  project_name = "secure-email"
  environment  = "production"
  
  tags = {
    Security   = "high"
    Compliance = "sox-pci"
    DataClass  = "sensitive"
  }
}
```

## 📝 **Input Variables**

### **Required Variables**
| Name | Description | Type |
|------|-------------|------|
| `domain_name` | Primary domain for email service | `string` |

### **Domain Configuration**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `verify_domain` | Verify domain with SES | `bool` | `true` |
| `verify_dkim` | Enable DKIM verification | `bool` | `true` |
| `mail_from_domain` | Custom MAIL FROM domain | `string` | `""` |
| `mail_from_behavior_on_mx_failure` | Behavior on MX failure | `string` | `"UseDefaultValue"` |

### **Email Addresses**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `verified_email_addresses` | List of verified email addresses | `list(string)` | `[]` |

### **Templates**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `email_templates` | Email template definitions | `map(object)` | `{}` |

### **Configuration Sets**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `configuration_sets` | SES configuration sets | `map(object)` | `{}` |

### **Event Handling**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `bounce_topic_arn` | SNS topic for bounces | `string` | `""` |
| `complaint_topic_arn` | SNS topic for complaints | `string` | `""` |

### **Security**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `identity_policies` | Identity-based policies | `map(object)` | `{}` |
| `sending_quota` | Sending quota configuration | `object` | `null` |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `domain_identity_arn` | ARN of the domain identity |
| `domain_identity_verification_token` | Domain verification token |
| `dkim_tokens` | DKIM verification tokens |
| `mail_from_domain_arn` | Mail-from domain ARN |
| `verified_email_addresses` | List of verified email addresses |
| `configuration_set_names` | Names of configuration sets |
| `configuration_set_arns` | ARNs of configuration sets |
| `email_template_names` | Names of email templates |
| `identity_policy_names` | Names of identity policies |

## 🏗️ **Architecture**

```
                    ┌─────────────────┐
                    │   Application   │
                    │   (Send Email)  │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   AWS SES       │
                    │   Service       │
                    └─────────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Domain    │     │   Email     │     │Configuration│
│Verification │     │ Templates   │     │    Sets     │
└─────────┬───┘     └─────────┬───┘     └─────────┬───┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ DKIM/SPF    │     │   Bounce    │     │Event Tracking│
│   Records   │     │  Handling   │     │& Analytics  │
└─────────────┘     └─────────────┘     └─────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ CloudWatch  │     │     SNS     │     │  Kinesis    │
│  Metrics    │     │Notifications│     │  Streams    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 🔒 **Security Best Practices**

### **Email Authentication**
- 🔐 **DKIM Signing** - Cryptographic email signatures
- 📋 **SPF Records** - Sender Policy Framework
- 🛡️ **DMARC Policy** - Domain-based Message Authentication
- 🔒 **TLS Encryption** - Encrypted email transmission

### **Access Control**
- 🎯 **IAM Policies** - Granular permission management
- 🔐 **Identity Policies** - Cross-account access control
- 🛡️ **Resource Policies** - Service-level permissions
- 📊 **CloudTrail Logging** - Comprehensive audit trail

### **Data Protection**
- 🔒 **Encryption at Rest** - Template and configuration encryption
- 🔐 **Encryption in Transit** - TLS for all communications
- 🛡️ **Data Residency** - Regional data storage compliance
- 📋 **Retention Policies** - Automated data lifecycle management

## 💰 **Cost Optimization**

### **Pricing Components**
- **Email Sending**: $0.10 per 1,000 emails (first 62,000 free with AWS Free Tier)
- **Data Transfer**: $0.12 per GB outbound
- **Dedicated IP**: $24.95 per month per IP
- **Email Receiving**: $0.10 per 1,000 emails received

### **Cost-Saving Strategies**
- 📊 **Template Optimization** - Reduce email size
- 🎯 **Segmentation** - Target relevant audiences
- 📈 **Bounce Management** - Maintain clean lists
- 🔄 **Regional Optimization** - Use closest SES regions

## 🧪 **Examples**

Check the [examples](examples/) directory for complete implementations:

- **[Transactional Emails](examples/transactional-emails/)** - User notifications and alerts
- **[Marketing Campaigns](examples/marketing-campaigns/)** - Newsletter and promotional emails
- **[E-commerce Platform](examples/ecommerce-emails/)** - Order confirmations and receipts
- **[Multi-Tenant SaaS](examples/saas-email-service/)** - Customer-branded email service

## 🔧 **Requirements**

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 5.0 |

## 🧪 **Testing**

```bash
# Validate Terraform configuration
terraform validate

# Test domain verification
aws ses get-identity-verification-attributes --identities example.com

# Send test email
aws ses send-email \
  --source "test@example.com" \
  --destination "ToAddresses=recipient@example.com" \
  --message "Subject={Data=Test},Body={Text={Data=Test message}}"

# Check sending statistics
aws ses get-send-statistics

# Verify DKIM tokens
dig TXT selector1._domainkey.example.com
```

## 📊 **Email Deliverability**

### **Reputation Management**
- 📈 **Bounce Rate** - Keep below 5%
- 🚨 **Complaint Rate** - Keep below 0.1%
- 🎯 **Engagement Metrics** - Track opens and clicks
- 🔄 **List Hygiene** - Regular list cleaning

### **Monitoring and Alerts**
```hcl
# High bounce rate alarm
resource "aws_cloudwatch_metric_alarm" "high_bounce_rate" {
  alarm_name          = "ses-high-bounce-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Bounce"
  namespace           = "AWS/SES"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "SES bounce rate is too high"
  
  dimensions = {
    ConfigurationSet = aws_ses_configuration_set.main.name
  }
}
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/email-enhancement`)
3. Commit your changes (`git commit -m 'Add email enhancement'`)
4. Push to the branch (`git push origin feature/email-enhancement`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 **Related Modules**

- **[terraform-aws-route53](../terraform-aws-route53)** - DNS record management
- **[terraform-aws-cloudwatch](../terraform-aws-cloudwatch)** - Email monitoring
- **[terraform-aws-lambda](../terraform-aws-lambda)** - Email processing
- **[terraform-aws-s3](../terraform-aws-s3)** - Email template storage

---

**📧 Built for enterprise email delivery and communication**

> *This module demonstrates advanced SES architecture patterns and email service expertise suitable for production environments requiring high deliverability, compliance, and comprehensive monitoring.*