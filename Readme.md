# Unified Omnichannel Dialer for Amazon Connect

A comprehensive, Supabase-aware dialer solution that merges power dialer and outbound campaign capabilities into a single, unified system supporting voice, SMS, email, and web chat channels.

## Overview

This unified dialer combines the best features from both:
- **Amazon Connect Power Dialer**: Predictive dialing with agent availability monitoring
- **Voice Channel for Outbound Campaigns**: Campaign-style mass dialing with Pinpoint integration

### Key Features

- 🔄 **Dual Mode Operation**: Switch between power dialer and blaster campaign modes
- 🗄️ **Supabase Integration**: Real-time customer data lookup and caching
- 📊 **DynamoDB Caching**: Optimized performance with local lead data caching
- 🌐 **Omnichannel Support**: Voice, SMS, email, and web chat capabilities
- 📈 **Intelligent Routing**: Agent availability monitoring and predictive dialing
- 🎯 **Campaign Management**: Pinpoint integration for targeted campaigns
- 📱 **Real-time Monitoring**: CloudWatch integration with comprehensive logging
- 🔐 **Enterprise Security**: IAM roles, encryption, and least-privilege access

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Amazon S3     │    │  Amazon Connect  │    │     Supabase        │
│  (Contact Lists)│    │  (Contact Flows) │    │   (Lead Database)   │
└─────────┬───────┘    └────────┬─────────┘    └──────────┬──────────┘
          │                     │                         │
          │                     │                         │
┌─────────▼───────┐    ┌────────▼─────────┐    ┌──────────▼──────────┐
│  EventBridge    │    │   Step Functions │    │  Lambda Functions   │
│   (Triggers)    │    │ (Orchestration)  │    │  (Business Logic)   │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
          │                     │                         │
          │                     │                         │
┌─────────▼───────┐    ┌────────▼─────────┐    ┌──────────▼──────────┐
│      SQS        │    │    DynamoDB      │    │  Kinesis Firehose   │
│   (Queues)      │    │   (Tracking)     │    │    (Results)        │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- SAM CLI installed
- Node.js 18+ for Lambda functions
- Python 3.9+ for Lambda layers
- Amazon Connect instance configured
- Supabase project with leads table

### 1. Deploy Infrastructure

```bash
# Clone and navigate to the project
cd dialer

# Build and deploy the unified stack
cd infra
sam build
sam deploy --guided

# Follow the prompts to configure:
# - Stack name (e.g., unified-dialer-prod)
# - AWS region
# - Connect Instance ID
# - Connect Contact Flow ID  
# - Connect Queue ID
# - Supabase URL and credentials
# - Other configuration parameters
```

### 2. Configure Amazon Connect

#### Import Contact Flow
1. Navigate to Amazon Connect admin console
2. Go to Routing > Contact flows
3. Create new contact flow
4. Import `contact-flows/UnifiedDialerContactFlow.json`
5. Update Lambda ARNs in the flow to match your deployment
6. Save and publish the flow

#### Add Lambda Functions
1. Go to Routing > AWS Lambda
2. Add the following functions:
   - `{StackName}-LookupSupabaseFunction`
   - `{StackName}-SetDispositionFunction`

### 3. Configure Supabase

#### Create Leads Table
```sql
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    status VARCHAR(50) DEFAULT 'new',
    property_count INTEGER DEFAULT 0,
    total_loan_amount DECIMAL(12,2) DEFAULT 0,
    credit_score INTEGER,
    last_contact_date TIMESTAMP,
    notes TEXT,
    priority_level VARCHAR(20) DEFAULT 'normal',
    lead_source VARCHAR(100),
    assigned_agent VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for fast lookups
CREATE INDEX idx_leads_customer_number ON leads(customer_number);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_priority ON leads(priority_level);
```

#### Insert Sample Data
```sql
INSERT INTO leads (customer_number, first_name, last_name, email, phone, status, property_count, total_loan_amount, credit_score, lead_source, priority_level) VALUES
('5551234567', 'John', 'Smith', 'john.smith@email.com', '5551234567', 'qualified', 2, 750000.00, 720, 'website', 'high'),
('5551234568', 'Jane', 'Doe', 'jane.doe@email.com', '5551234568', 'new', 1, 425000.00, 680, 'referral', 'medium'),
('5551234569', 'Bob', 'Johnson', 'bob.johnson@email.com', '5551234569', 'contacted', 3, 1200000.00, 750, 'campaign', 'high');
```

### 4. Test the System

#### Upload Contact List
1. Create a CSV file with the following format:
```csv
custID,phone,name,email,status,campaignId,endpointId
001,5551234567,John Smith,john@email.com,qualified,test-campaign,endpoint-001
002,5551234568,Jane Doe,jane@email.com,new,test-campaign,endpoint-002
```

2. Upload to the input S3 bucket created by the stack

#### Start Campaign
```bash
# Manual execution via AWS CLI
aws stepfunctions start-execution \
    --state-machine-arn "arn:aws:states:REGION:ACCOUNT:stateMachine:STACK-UnifiedDialer-XXXX" \
    --name "test-campaign-$(date +%s)" \
    --input '{}'

# Or enable the scheduled trigger
aws events put-rule \
    --name "STACK-CampaignLaunchSchedule" \
    --state ENABLED
```

## Configuration

### Campaign Modes

#### Power Dialer Mode (Default)
- Monitors agent availability
- Predictive dialing based on agent capacity
- Automatic concurrency adjustment
- Best for steady, agent-focused calling

```bash
# Set power dialer mode
aws ssm put-parameter \
    --name "/connect/unified-dialer/STACK-NAME/campaignMode" \
    --value "power-dialer" \
    --overwrite
```

#### Blaster Mode
- High-volume campaign dialing
- Less agent availability dependency
- Faster call placement
- Best for large-scale campaigns

```bash
# Set blaster mode
aws ssm put-parameter \
    --name "/connect/unified-dialer/STACK-NAME/campaignMode" \
    --value "blaster" \
    --overwrite
```

### Configuration Parameters

All configuration is managed through AWS Systems Manager Parameter Store:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `/connect/unified-dialer/STACK/campaignMode` | Dialer mode: power-dialer or blaster | power-dialer |
| `/connect/unified-dialer/STACK/concurrentCalls` | Max simultaneous calls | 5 |
| `/connect/unified-dialer/STACK/timeOut` | Call timeout in seconds | 3600 |
| `/connect/unified-dialer/STACK/activeDialer` | Enable/disable dialer | False |

### Supabase Configuration

Update your Supabase credentials:

```bash
# Update Supabase credentials
aws secretsmanager update-secret \
    --secret-id "STACK-NAME-supabase-credentials" \
    --secret-string '{
        "url": "https://your-project.supabase.co",
        "anon_key": "your-anon-key"
    }'
```

## Monitoring and Operations

### CloudWatch Dashboards

The system automatically creates CloudWatch dashboards for:
- Call volume and success rates
- Lambda function performance
- DynamoDB read/write metrics
- Step Function execution status

### Logs

Key log groups:
- `/aws/lambda/STACK-LookupSupabaseFunction`
- `/aws/lambda/STACK-DialFunction`
- `/aws/states/STACK-UnifiedDialer`

### Troubleshooting

#### Common Issues

1. **Supabase Connection Errors**
   ```bash
   # Check credentials
   aws secretsmanager get-secret-value \
       --secret-id "STACK-NAME-supabase-credentials"
   
   # Test connectivity
   aws lambda invoke \
       --function-name "STACK-LookupSupabaseFunction" \
       --payload '{"customerNumber":"5551234567"}' \
       response.json
   ```

2. **No Calls Being Placed**
   ```bash
   # Check dialer status
   aws ssm get-parameter \
       --name "/connect/unified-dialer/STACK/activeDialer"
   
   # Check queue status
   aws sqs get-queue-attributes \
       --queue-url "https://sqs.REGION.amazonaws.com/ACCOUNT/STACK-dialing-queue-XXXX" \
       --attribute-names ApproximateNumberOfMessages
   ```

3. **Contact Flow Errors**
   - Verify Lambda ARNs in contact flow match deployed functions
   - Check Lambda permissions for Connect invocation
   - Review CloudWatch logs for Lambda errors

## Omnichannel Features

### SMS Integration
Configure Pinpoint SMS campaigns that trigger the unified dialer:

```python
# Example: Create SMS campaign that feeds dialer
import boto3

pinpoint = boto3.client('pinpoint')

response = pinpoint.create_campaign(
    ApplicationId='your-pinpoint-app-id',
    WriteCampaignRequest={
        'Name': 'SMS-to-Voice-Campaign',
        'MessageConfiguration': {
            'SMSMessage': {
                'Body': 'Thank you for your interest. Expect a call from our team soon.',
                'MessageType': 'PROMOTIONAL'
            }
        },
        'Schedule': {
            'StartTime': '2024-01-01T10:00:00Z'
        },
        'CustomDeliveryConfiguration': {
            'DeliveryUri': 'arn:aws:lambda:REGION:ACCOUNT:function:STACK-QueueContactsFunction'
        }
    }
)
```

### Web Chat Integration
The contact flow supports web chat contacts with the same Supabase lookup functionality.

### Email Campaign Integration
Use Pinpoint email campaigns to warm leads before voice outreach.

## Security

### IAM Roles
- **UnifiedDialerLambdaRole**: Minimal permissions for Lambda functions
- **SupabaseLookupLambdaRole**: Specific permissions for Supabase integration
- **UnifiedDialerStateMachineRole**: Step Functions execution permissions

### Encryption
- All DynamoDB tables encrypted at rest
- S3 buckets with encryption enabled
- Secrets Manager for sensitive credentials

### Network Security
- VPC endpoints for AWS services
- Security groups restricting access
- NAT Gateway for outbound Lambda connectivity

## Cost Optimization

### DynamoDB Caching
- Reduces Supabase API calls by 80%+
- 24-hour TTL for cached data
- Pay-per-request billing model

### Lambda Optimization
- Efficient connection pooling
- Proper timeout configuration
- Minimal memory allocation

### S3 Lifecycle Policies
- Automatic archival of old campaign results
- Intelligent tiering for cost savings

## API Reference

### Supabase Lookup Lambda

**Input:**
```json
{
  "customerNumber": "5551234567"
}
```

**Output:**
```json
{
  "leadFound": "true",
  "leadName": "John Smith",
  "leadEmail": "john@email.com",
  "leadStatus": "qualified",
  "propertyCount": "2",
  "totalLoanAmount": "750000",
  "creditScore": "720"
}
```

### Set Disposition Lambda

**Input:**
```json
{
  "contactId": "12345678-1234-1234-1234-123456789012",
  "customerNumber": "5551234567",
  "callResult": "completed",
  "campaignType": "unified-dialer"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and support:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Create an issue with detailed information

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### v1.0.0
- Initial unified dialer release
- Supabase integration
- Dual mode operation (power dialer + blaster)
- Omnichannel support
- Comprehensive monitoring and logging