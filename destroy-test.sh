#!/bin/bash
set -eo pipefail

# --- Configuration ---
STACK_NAME="vistocapital-dialer-dev"
ROOT_ENV_FILE="$(dirname "$0")/.env"
CDK_DIR="$(dirname "$0")/cdk"

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
if [ -f "$ROOT_ENV_FILE" ]; then
    info "Sourcing environment variables from $ROOT_ENV_FILE"
    set -a
    # shellcheck source=/dev/null
    source "$ROOT_ENV_FILE"
    set +a
else
    warn "Root .env file not found. Please ensure it exists and contains necessary variables (e.g., AWS_REGION, AWS_PROFILE)."
fi

# 2. Get Connect Instance ID from SAM Output
info "Fetching ConnectInstanceId from SAM stack outputs..."
CONNECT_INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ConnectInstanceId'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null)

if [ -z "$CONNECT_INSTANCE_ID" ]; then
    warn "Could not retrieve ConnectInstanceId from stack '$STACK_NAME'. It might have been deleted already. Skipping CDK destroy."
else
    info "Successfully retrieved Connect Instance ID: $CONNECT_INSTANCE_ID"
    # 3. Destroy CDK Application
    info "Destroying CDK application..."
    pushd "$CDK_DIR" > /dev/null
    yarn install
    cdk destroy \
        --force \
        --parameters connectInstanceId="$CONNECT_INSTANCE_ID"
    popd > /dev/null
    info "CDK application destruction complete."
fi


# 4. Destroy SAM Infrastructure
info "Destroying SAM infrastructure stack '$STACK_NAME'..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION"
info "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"

info "Destruction complete!" 