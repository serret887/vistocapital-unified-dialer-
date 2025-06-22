#!/bin/bash
set -eo pipefail

# --- Configuration ---
STACK_NAME="vistocapital-dialer-test"
ROOT_DIR="$(git rev-parse --show-toplevel)"
ENV_FILE="$ROOT_DIR/.env"
CDK_DIR="$ROOT_DIR/cdk"
INFRA_TEMPLATE="$ROOT_DIR/infra/template.yaml"
SAM_BUILD_DIR="$ROOT_DIR/.aws-sam"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Functions ---
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Main Script ---

# 1. Load Environment Variables
if [ -f "$ENV_FILE" ]; then
    info "Sourcing environment variables from $ENV_FILE"
    # shellcheck source=/dev/null
    export "$(grep -v '^#' "$ENV_FILE" | xargs)"
else
    error "Root .env file not found. Please create it and add required variables."
    exit 1
fi

# 2. Validate Environment Variables
if [ -z "$AWS_REGION" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    error "One or more required environment variables are missing from .env file (AWS_REGION, SUPABASE_URL, SUPABASE_ANON_KEY)."
    exit 1
fi

# 3. Deploy SAM Infrastructure
info "Building SAM application..."
sam build --template "$INFRA_TEMPLATE" --build-dir "$SAM_BUILD_DIR"

info "Deploying SAM infrastructure..."
sam deploy \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
    --resolve-s3 \
    --template-file "$SAM_BUILD_DIR/template.yaml" \
    --parameter-overrides \
        "Environment=test" \
        "ConnectContactFlowId=00000000-0000-0000-0000-000000000000" \
        "ConnectQueueId=00000000-0000-0000-0000-000000000000" \
        "ValidateProfile=False" \
        "CountryCode=1" \
        "ISOCountryCode=US" \
        "ConcurrentCalls=1" \
        "CallTimeOut=3600" \
        "NoCallStatusList=''" \
        "SupabaseUrl=${SUPABASE_URL}" \
        "SupabaseAnonKey=${SUPABASE_ANON_KEY}"

info "SAM infrastructure deployment complete."

# 4. Get Connect Instance ID from SAM Output
info "Fetching ConnectInstanceId from SAM stack outputs..."
CONNECT_INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ConnectInstanceId'].OutputValue" \
    --output text \
    --region "$AWS_REGION")

if [ -z "$CONNECT_INSTANCE_ID" ]; then
    error "Failed to retrieve ConnectInstanceId from stack outputs. Aborting."
    exit 1
fi
info "Successfully retrieved Connect Instance ID: $CONNECT_INSTANCE_ID"

# 5. Deploy CDK Application
info "Deploying CDK application..."
pushd "$CDK_DIR" > /dev/null
yarn install --silent
cdk deploy \
    --require-approval never \
    --parameters connectInstanceId="$CONNECT_INSTANCE_ID"
popd > /dev/null

info "Deployment complete!" 