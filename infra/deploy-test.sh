#!/bin/bash

# Exit on any error
set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Load environment variables from the root .env file
if [ -f ../.env ]; then
  echo "🔑 Sourcing configuration and credentials from ../.env"
  export $(grep -v '^#' ../.env | xargs)
else
  echo "⚠️  Warning: .env file not found at ../.env. Relying on environment variables."
fi

# Set deployment configuration
STACK_NAME=${STACK_NAME:-vistocapital-dialer}
REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT=${ENVIRONMENT:-dev}
CONNECT_INSTANCE_ID=${CONNECT_INSTANCE_ID:-"12345678-1234-1234-1234-123456789012"} # Placeholder
CONNECT_CONTACT_FLOW_ID=${CONNECT_CONTACT_FLOW_ID:-"87654321-4321-4321-4321-210987654321"} # Placeholder
CONNECT_QUEUE_ID=${CONNECT_QUEUE_ID:-"11111111-2222-3333-4444-555555555555"} # Placeholder
VALIDATE_PROFILE=${VALIDATE_PROFILE:-"False"}
CUSTOMER_PROFILES_DOMAIN_NAME=${CUSTOMER_PROFILES_DOMAIN_NAME:-"vistocapitaltest"}
COUNTRY_CODE=${COUNTRY_CODE:-"1"}
ISO_COUNTRY_CODE=${ISO_COUNTRY_CODE:-"US"}
CONCURRENT_CALLS=${CONCURRENT_CALLS:-"5"}
CALL_TIMEOUT=${CALL_TIMEOUT:-"3600"}
NO_CALL_STATUS_LIST=${NO_CALL_STATUS_LIST:-"No"}
SUPABASE_URL=${SUPABASE_URL:-"https://test-project.supabase.co"} # Placeholder
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-"test-anon-key-placeholder-for-infrastructure-testing-only"} # Placeholder

echo "🚀 Deploying ViSto Capital Unified Dialer - Test Environment"
echo "📋 Deployment Configuration:"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Environment: $ENVIRONMENT"
echo "  Connect Instance: $CONNECT_INSTANCE_ID"
echo "  Supabase URL: $SUPABASE_URL"
echo ""
echo "📝 Note: Using placeholder values for testing infrastructure deployment"
echo "   Update Supabase credentials in AWS Secrets Manager after deployment"
echo ""

# Check stack status
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].StackStatus" --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" == "ROLLBACK_COMPLETE" ] || [ "$STACK_STATUS" == "ROLLBACK_FAILED" ]; then
    echo "❌ Stack is in a failed state ($STACK_STATUS). Deleting before proceeding..."
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
    echo "⏳ Waiting for stack to be deleted..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION
    echo "✅ Stack deleted."
elif [ "$STACK_STATUS" != "DOES_NOT_EXIST" ] && [[ "$STACK_STATUS" != *"_COMPLETE"* ]]; then
    echo "❌ Stack is in an unrecoverable state: $STACK_STATUS. Please check the AWS Console."
    exit 1
elif [ "$STACK_STATUS" != "DOES_NOT_EXIST" ]; then
    echo "ℹ️ Stack '$STACK_NAME' is in a healthy state ($STACK_STATUS). It will be updated if necessary."
fi

# Run sam build from the infra directory
echo "🔨 Building SAM application..."
sam build --template-file ./template.yaml --base-dir ..

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful!"


# Deploy the application
echo "🚀 Starting deployment..."
sam deploy \
    --template-file ./.aws-sam/build/template.yaml \
    --stack-name $STACK_NAME \
    --region $REGION \
    --tags "Environment=$ENVIRONMENT" \
    --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
    --resolve-s3 \
    --parameter-overrides \
        ConnectInstanceId="$CONNECT_INSTANCE_ID" \
        ConnectContactFlowId="$CONNECT_CONTACT_FLOW_ID" \
        ConnectQueueId="$CONNECT_QUEUE_ID" \
        ValidateProfile="$VALIDATE_PROFILE" \
        CustomerProfilesDomainName="$CUSTOMER_PROFILES_DOMAIN_NAME" \
        CountryCode="$COUNTRY_CODE" \
        ISOCountryCode="$ISO_COUNTRY_CODE" \
        ConcurrentCalls="$CONCURRENT_CALLS" \
        CallTimeOut="$CALL_TIMEOUT" \
        NoCallStatusList="$NO_CALL_STATUS_LIST" \
        SupabaseUrl=$SUPABASE_URL \
        SupabaseAnonKey=$SUPABASE_ANON_KEY \
        Environment=$ENVIRONMENT \
    --no-confirm-changeset \
    --fail-on-empty-changeset \
    --on-failure ROLLBACK \
    --max-wait-duration 60

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "🎉 ViSto Capital Unified Dialer has been deployed to the '$ENVIRONMENT' environment."
    echo "Stack Name: $STACK_NAME"
    echo "Region: $REGION"
else
    echo ""
    echo "❌ Deployment failed. Please check the logs above or the AWS CloudFormation console for more details."
    exit 1
fi 