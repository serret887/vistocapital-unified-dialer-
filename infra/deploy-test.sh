#!/bin/bash

# ViSto Capital Unified Dialer - Test Deployment Script
echo "🚀 Deploying ViSto Capital Unified Dialer - Test Environment"

# Set deployment parameters
STACK_NAME="vistocapital-dialer"
REGION="us-east-1"

# Placeholder UUIDs for Amazon Connect (replace with real ones when available)
CONNECT_INSTANCE_ID="12345678-1234-1234-1234-123456789012"
CONNECT_CONTACT_FLOW_ID="87654321-4321-4321-4321-210987654321"
CONNECT_QUEUE_ID="11111111-2222-3333-4444-555555555555"

# Customer Profiles Domain
CUSTOMER_PROFILES_DOMAIN="vistocapitaltest"

# Supabase Configuration (placeholder values for testing)
SUPABASE_URL="https://test-project.supabase.co"
SUPABASE_ANON_KEY="test-anon-key-placeholder-for-infrastructure-testing-only"

# Environment
ENVIRONMENT="dev"

echo "📋 Deployment Configuration:"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Environment: $ENVIRONMENT"
echo "  Connect Instance: $CONNECT_INSTANCE_ID"
echo "  Supabase URL: $SUPABASE_URL"
echo ""

# Note about placeholder values
echo "📝 Note: Using placeholder values for testing infrastructure deployment"
echo "   Update Supabase credentials in AWS Secrets Manager after deployment"
echo ""

echo "🔨 Building SAM application..."
sam build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

echo "🚀 Starting deployment..."
sam deploy \
    --stack-name $STACK_NAME \
    --region $REGION \
    --capabilities CAPABILITY_IAM \
    --no-disable-rollback \
    --parameter-overrides \
        ConnectInstanceId=$CONNECT_INSTANCE_ID \
        ConnectContactFlowId=$CONNECT_CONTACT_FLOW_ID \
        ConnectQueueId=$CONNECT_QUEUE_ID \
        ValidateProfile="False" \
        CustomerProfilesDomainName=$CUSTOMER_PROFILES_DOMAIN \
        CountryCode=1 \
        ISOCountryCode="US" \
        ConcurrentCalls=5 \
        CallTimeOut=3600 \
        NoCallStatusList="No Interest,Do Not Call,Previous Renewal" \
        SupabaseUrl=$SUPABASE_URL \
        SupabaseAnonKey=$SUPABASE_ANON_KEY \
        Environment=$ENVIRONMENT \
    --confirm-changeset

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "📊 Getting stack outputs..."
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs' \
        --output table
    
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Test the Supabase lookup Lambda function"
    echo "2. Create Amazon Connect instance and update parameters"
    echo "3. Import the contact flow from contact-flows/UnifiedDialerContactFlow.json"
    echo "4. Create Pinpoint campaigns using the workflow guide"
    echo ""
    echo "📁 Key Resources Created:"
    echo "  - S3 Buckets: Input and Output buckets for campaigns"
    echo "  - DynamoDB Tables: ActiveDialing and LeadCache tables"
    echo "  - Lambda Function: Supabase lookup function"
    echo "  - Kinesis Firehose: Results streaming to S3"
    echo "  - Secrets Manager: Supabase credentials storage"
    
else
    echo "❌ Deployment failed!"
    echo "Check the error messages above for details."
    exit 1
fi 