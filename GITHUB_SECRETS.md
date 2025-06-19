# GitHub Secrets Configuration

This document lists all the required GitHub repository secrets for the ViSto Capital Unified Dialer CI/CD pipeline.

## General AWS Secrets

These secrets are required for both staging and production deployments:

### AWS Credentials
- `AWS_ACCESS_KEY_ID` - AWS access key with deployment permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key

## Staging Environment Secrets

Configure these secrets for the staging environment (develop branch):

### Amazon Connect Configuration (Staging)
- `STAGING_CONNECT_INSTANCE_ID` - Amazon Connect instance ID for staging
- `STAGING_CONTACT_FLOW_ID` - Contact flow ID for staging
- `STAGING_SOURCE_PHONE_NUMBER` - Source phone number for outbound calls
- `STAGING_QUEUE_ID` - Queue ID for staging environment
- `STAGING_HOURS_OF_OPERATION_ID` - Hours of operation ID
- `STAGING_USER_HIERARCHY_GROUP_ID` - User hierarchy group ID

### Supabase Configuration (Staging)
- `STAGING_SUPABASE_URL` - Supabase project URL (e.g., https://your-project.supabase.co)
- `STAGING_SUPABASE_ANON_KEY` - Supabase anonymous key
- `STAGING_SUPABASE_SERVICE_KEY` - Supabase service role key (for server-side operations)

## Production Environment Secrets

Configure these secrets for the production environment (main branch):

### Amazon Connect Configuration (Production)
- `PROD_CONNECT_INSTANCE_ID` - Amazon Connect instance ID for production
- `PROD_CONTACT_FLOW_ID` - Contact flow ID for production
- `PROD_SOURCE_PHONE_NUMBER` - Source phone number for outbound calls
- `PROD_QUEUE_ID` - Queue ID for production environment
- `PROD_HOURS_OF_OPERATION_ID` - Hours of operation ID
- `PROD_USER_HIERARCHY_GROUP_ID` - User hierarchy group ID

### Supabase Configuration (Production)
- `PROD_SUPABASE_URL` - Supabase project URL (e.g., https://your-project.supabase.co)
- `PROD_SUPABASE_ANON_KEY` - Supabase anonymous key
- `PROD_SUPABASE_SERVICE_KEY` - Supabase service role key (for server-side operations)

## How to Set GitHub Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name listed above
5. Paste the corresponding value
6. Click **Add secret**

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

The AWS credentials need the following permissions:

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
                "connect:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Troubleshooting

### Common Issues

1. **Invalid AWS Credentials**: Verify access key and secret are correct
2. **Permission Denied**: Ensure IAM user has sufficient permissions
3. **Resource Not Found**: Verify Amazon Connect resource IDs are correct
4. **Supabase Connection**: Test Supabase credentials manually before adding to secrets

### Testing Secrets

Before deploying, you can test your configuration locally:

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Supabase connection (requires Node.js and supabase-js)
node -e "
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('YOUR_URL', 'YOUR_KEY');
console.log('Supabase client created successfully');
"
```

## Support

For issues with secrets configuration:
1. Check AWS CloudTrail logs for permission issues
2. Verify Supabase project settings and API keys
3. Review GitHub Actions workflow logs for specific error messages
4. Ensure all required secrets are properly named and set 