#!/bin/bash
set -xeo pipefail

# --- Configuration ---
STACK_NAME="vistocapital-dialer-dev"
ROOT_DIR="$(git rev-parse --show-toplevel)"
ENV_FILE="$ROOT_DIR/.env"
CDK_DIR="$ROOT_DIR/cdk"
INFRA_TEMPLATE="$ROOT_DIR/infra/template.yaml"
SAM_BUILD_DIR="$ROOT_DIR/.aws-sam"
CONNECT_ALIAS="vistocapital-unified-dialer-dev"

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
    set -a
    source "$ENV_FILE"
    set +a
else
    error "Root .env file not found. Please create it and add required variables."
    exit 1
fi

# 2. Validate Environment Variables
if [ -z "$AWS_REGION" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    error "One or more required environment variables are missing from .env file (AWS_REGION, SUPABASE_URL, SUPABASE_ANON_KEY)."
    exit 1
fi

# 3. Lookup or Create Amazon Connect Instance
info "Looking up Amazon Connect instance with alias: $CONNECT_ALIAS"
CONNECT_INSTANCE_ID=$(aws connect list-instances \
  --region "$AWS_REGION" \
  --query "InstanceSummaryList[?InstanceAlias=='$CONNECT_ALIAS'].Id" \
  --output text)

if [ -z "$CONNECT_INSTANCE_ID" ]; then
    info "No existing Connect instance found. Creating a new one."
    CONNECT_INSTANCE_ID=$(aws connect create-instance \
      --region "$AWS_REGION" \
      --identity-management-type CONNECT_MANAGED \
      --instance-alias "$CONNECT_ALIAS" \
      --inbound-calls-enabled \
      --outbound-calls-enabled \
      --query "Id" \
      --output text)
    info "Created new Connect instance with ID: $CONNECT_INSTANCE_ID"
else
    info "Found existing Connect instance with ID: $CONNECT_INSTANCE_ID"
fi

# 4. Deploy CDK Application
info "Deploying CDK application..."
pushd "$CDK_DIR" > /dev/null
yarn install --silent
cdk deploy --require-approval never --verbose --parameters ConnectInstanceId="$CONNECT_INSTANCE_ID"
popd > /dev/null
info "CDK deployment complete."

# 5. Build and Deploy SAM Infrastructure
info "Building SAM application..."
sam build --debug --template "$INFRA_TEMPLATE" --build-dir "$SAM_BUILD_DIR"

info "Deploying SAM infrastructure..."
sam deploy --debug \
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
        "SupabaseAnonKey=${SUPABASE_ANON_KEY}" \
        "CustomerProfilesDomainName=${CUSTOMER_PROFILES_DOMAIN_NAME}" \
        "ConnectInstanceId=${CONNECT_INSTANCE_ID}"

info "Deployment complete!" 