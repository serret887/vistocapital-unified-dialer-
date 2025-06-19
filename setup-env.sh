#!/bin/bash

# ViSto Capital Unified Dialer - Environment Setup Script
# This script copies environment template files and reminds users to configure them

set -e

echo "🚀 ViSto Capital Unified Dialer - Environment Setup"
echo "=================================================="

# Function to copy template if target doesn't exist
copy_template() {
    local template="$1"
    local target="$2"
    
    if [ ! -f "$target" ]; then
        if [ -f "$template" ]; then
            cp "$template" "$target"
            echo "✅ Created $target from template"
        else
            echo "⚠️  Template $template not found"
        fi
    else
        echo "ℹ️  $target already exists, skipping"
    fi
}

# Create main environment file
copy_template "env.example" ".env"

# Create Lambda environment file
copy_template "lambdas/lookupSupabase/env.example" "lambdas/lookupSupabase/.env"

# Create infrastructure environment file if needed
if [ -d "infra" ]; then
    copy_template "infra/env.example" "infra/.env"
fi

echo ""
echo "📝 Next Steps:"
echo "=============="
echo "1. Edit .env with your AWS and deployment configuration"
echo "2. Edit lambdas/lookupSupabase/.env with your Supabase credentials"
echo "3. Review and update any other configuration files as needed"
echo ""
echo "⚠️  IMPORTANT: These .env files contain sensitive information and are"
echo "   automatically ignored by git. Never commit them to the repository!"
echo ""
echo "🔗 For deployment instructions, see DEPLOYMENT_SUMMARY.md"
echo "🔗 For GitHub Actions setup, see GITHUB_SECRETS.md" 