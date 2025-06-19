# GitHub Secrets Configuration

This document lists all the required GitHub repository secrets for the ViSto Capital Unified Dialer CI/CD pipeline with automated Amazon Connect deployment via CDK.

## 🚀 **New: Automated Connect Deployment**

The updated CI/CD pipeline now includes **AWS CDK automation** that creates Amazon Connect resources automatically. This reduces the number of manual secrets required!

## General AWS Secrets

These secrets are required for both staging and production deployments:

### AWS Credentials
- `AWS_ACCESS_KEY_ID` - AWS access key with deployment permissions (including Connect)
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key

## Staging Environment Secrets

Configure these secrets for the staging environment (develop branch):

### Amazon Connect Configuration (Staging)
**⚠️ SIMPLIFIED**: Only the Connect Instance ID is required now - all other resources are created automatically by CDK!

- `STAGING_CONNECT_INSTANCE_ID` - Amazon Connect instance ID for staging

~~The following are now AUTOMATED by CDK (no longer needed as secrets):~~
- ~~`STAGING_CONTACT_FLOW_ID`~~ - ✅ **Auto-created by CDK**
- ~~`STAGING_SOURCE_PHONE_NUMBER`~~ - ✅ **Auto-configured by CDK**
- ~~`STAGING_QUEUE_ID`~~ - ✅ **Auto-created by CDK** (Spanish & English queues)
- ~~`STAGING_HOURS_OF_OPERATION_ID`~~ - ✅ **Auto-created by CDK**
- ~~`STAGING_USER_HIERARCHY_GROUP_ID`~~ - ✅ **Auto-created by CDK**

### Supabase Configuration (Staging)
- `STAGING_SUPABASE_URL` - Supabase project URL (e.g., https://your-project.supabase.co)
- `STAGING_SUPABASE_ANON_KEY` - Supabase anonymous key

## Production Environment Secrets

Configure these secrets for the production environment (main branch):

### Amazon Connect Configuration (Production)
**⚠️ SIMPLIFIED**: Only the Connect Instance ID is required now - all other resources are created automatically by CDK!

- `PROD_CONNECT_INSTANCE_ID` - Amazon Connect instance ID for production

~~The following are now AUTOMATED by CDK (no longer needed as secrets):~~
- ~~`PROD_CONTACT_FLOW_ID`~~ - ✅ **Auto-created by CDK**
- ~~`PROD_SOURCE_PHONE_NUMBER`~~ - ✅ **Auto-configured by CDK**
- ~~`PROD_QUEUE_ID`~~ - ✅ **Auto-created by CDK** (Spanish & English queues)
- ~~`PROD_HOURS_OF_OPERATION_ID`~~ - ✅ **Auto-created by CDK**
- ~~`PROD_USER_HIERARCHY_GROUP_ID`~~ - ✅ **Auto-created by CDK**

### Supabase Configuration (Production)
- `PROD_SUPABASE_URL` - Supabase project URL (e.g., https://your-project.supabase.co)
- `PROD_SUPABASE_ANON_KEY` - Supabase anonymous key

## 📋 **Summary: Required Secrets (Only 6 total!)**

### **Essential Secrets:**
1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `STAGING_CONNECT_INSTANCE_ID`
4. `STAGING_SUPABASE_URL`
5. `STAGING_SUPABASE_ANON_KEY`
6. `PROD_CONNECT_INSTANCE_ID`
7. `PROD_SUPABASE_URL`
8. `PROD_SUPABASE_ANON_KEY`

**That's it!** The CDK automation handles all other Amazon Connect configuration automatically.

## How to Set GitHub Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name listed above
5. Paste the corresponding value
6. Click **Add secret**

## 🔄 **New Deployment Flow**

### **What Happens During Deployment:**

1. **SAM Infrastructure** - Deploys Lambda functions, DynamoDB, S3, etc.
2. **CDK Connect Automation** - Creates all Amazon Connect resources:
   - ✅ Contact flows (imports from `contact-flows/UnifiedDialerContactFlow.json`)
   - ✅ Spanish and English queues
   - ✅ Routing profiles for language-based routing
   - ✅ Lambda function associations
   - ✅ Hours of operation configuration
3. **Integration** - SAM stack is updated with Connect resource IDs from CDK
4. **Ready to Use** - Complete dialer system deployed and configured

### **Staging vs Production:**
- **Staging**: 3 concurrent calls, relaxed validation
- **Production**: 10 concurrent calls, strict validation

## Environment Protection Rules

For additional security, consider setting up environment protection rules:

### Staging Environment
- No special protection needed
- Auto-deploys on push to `develop` branch

### Production Environment
- Require reviewers before deployment
- Restrict to `main` branch only
- Optional: Add deployment branch rules

## Security Best Practices

1. **Principle of Least Privilege**: Ensure AWS credentials have only the minimum required permissions
2. **Separate Environments**: Use completely separate AWS accounts or strict IAM policies for staging vs production
3. **Key Rotation**: Regularly rotate AWS access keys and Supabase keys
4. **Monitor Usage**: Enable AWS CloudTrail and monitor secret usage
5. **Environment Variables**: Never commit secrets to version control

## Required IAM Permissions

The AWS credentials need the following permissions (updated for CDK):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "s3:*",
                "lambda:*",
                "iam:*",
                "dynamodb:*",
                "sqs:*",
                "secretsmanager:*",
                "ssm:*",
                "kinesis:*",
                "firehose:*",
                "events:*",
                "states:*",
                "connect:*",
                "sts:AssumeRole"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

## Troubleshooting

### Common Issues

1. **Invalid AWS Credentials**: Verify access key and secret are correct
2. **Permission Denied**: Ensure IAM user has sufficient permissions (especially Connect)
3. **Connect Instance Not Found**: Verify `CONNECT_INSTANCE_ID` is correct
4. **CDK Bootstrap Required**: First deployment may require CDK bootstrap (handled automatically)
5. **Supabase Connection**: Test Supabase credentials manually before adding to secrets

### Testing Secrets

Before deploying, you can test your configuration locally:

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Connect access
aws connect list-instances

# Test Supabase connection (requires Node.js and supabase-js)
node -e "
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('YOUR_URL', 'YOUR_KEY');
console.log('Supabase client created successfully');
"
```

## 🆕 **CDK Outputs Available**

After deployment, the CDK stack provides these outputs (automatically used by SAM):

- `ContactFlowId` - The unified dialer contact flow ID
- `SpanishQueueId` - Spanish language queue ID  
- `EnglishQueueId` - English language queue ID
- `RoutingProfileId` - Multi-language routing profile ID
- `HoursOfOperationId` - Business hours configuration ID

These are automatically passed to your Lambda functions - no manual configuration needed!

## Support

For issues with secrets configuration:
1. Check GitHub Actions logs for detailed deployment information
2. Review AWS CloudTrail logs for permission issues
3. Verify Supabase project settings and API keys
4. Check CDK deployment logs for Connect resource creation issues
5. Ensure all required secrets are properly named and set 