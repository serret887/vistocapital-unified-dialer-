#!/bin/bash

# Unified Omnichannel Dialer - Deployment Script
# This script deploys the unified dialer stack to AWS

set -e

echo "🚀 Unified Omnichannel Dialer Deployment"
echo "========================================"

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI is not installed. Please install it first:"
    echo "   pip install aws-sam-cli"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get parameters from user
echo ""
echo "📋 Configuration Parameters"
echo "============================"

read -p "Stack name (e.g., unified-dialer-prod): " STACK_NAME
read -p "AWS Region (e.g., us-west-2): " AWS_REGION
read -p "Connect Instance ID: " CONNECT_INSTANCE_ID
read -p "Connect Contact Flow ID: " CONNECT_CONTACT_FLOW_ID
read -p "Connect Queue ID: " CONNECT_QUEUE_ID
read -p "Customer Profiles Domain Name: " PROFILES_DOMAIN
read -p "Supabase URL (https://your-project.supabase.co): " SUPABASE_URL
read -s -p "Supabase Anonymous Key: " SUPABASE_ANON_KEY
echo ""

# Validate required parameters
if [[ -z "$STACK_NAME" || -z "$AWS_REGION" || -z "$CONNECT_INSTANCE_ID" || -z "$CONNECT_CONTACT_FLOW_ID" || -z "$CONNECT_QUEUE_ID" || -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
    echo "❌ All parameters are required. Please run the script again."
    exit 1
fi

echo ""
echo "🔧 Building SAM Application"
echo "============================"

cd infra

# Build the SAM application
echo "Building Lambda functions and dependencies..."
sam build

echo ""
echo "🚀 Deploying Stack"
echo "=================="

# Deploy with parameters
sam deploy \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        ConnectInstanceId="$CONNECT_INSTANCE_ID" \
        ConnectContactFlowId="$CONNECT_CONTACT_FLOW_ID" \
        ConnectQueueId="$CONNECT_QUEUE_ID" \
        CustomerProfilesDomainName="$PROFILES_DOMAIN" \
        SupabaseUrl="$SUPABASE_URL" \
        SupabaseAnonKey="$SUPABASE_ANON_KEY" \
    --confirm-changeset

echo ""
echo "✅ Deployment Complete!"
echo "======================="

# Get stack outputs
echo "📊 Stack Outputs:"
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs' \
    --output table

echo ""
echo "🔧 Next Steps:"
echo "=============="
echo "1. Import contact-flows/UnifiedDialerContactFlow.json to Amazon Connect"
echo "2. Add the Lambda functions to Amazon Connect (Routing > AWS Lambda)"
echo "3. Create the leads table in Supabase (see README.md)"
echo "4. Test with sample-contact-list.csv"
echo ""
echo "📚 For detailed instructions, see README.md"

cd ..

echo ""
echo "🎉 Ready to start dialing!" 