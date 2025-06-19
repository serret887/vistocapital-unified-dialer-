# ViSto Capital Unified Dialer - Deployment Guide

## 🚀 **Automated Deployment Overview**

This guide covers the **fully automated deployment** of the ViSto Capital Unified Dialer system using **SAM + CDK** integration. The deployment process now automates **100% of Amazon Connect configuration** while maintaining your existing infrastructure.

## 🏗️ **Architecture: SAM + CDK Integration**

### **SAM (Serverless Application Model)**
✅ **Handles Core Infrastructure:**
- Lambda functions (lookupSupabase, dial, setDisposition, etc.)
- DynamoDB tables (ActiveDialingTable, LeadCacheTable)
- S3 buckets (input/output storage)
- SQS queues, IAM roles, SSM parameters
- EventBridge rules, Kinesis Firehose

### **CDK (Cloud Development Kit)**  
✅ **Handles Amazon Connect Resources:**
- Contact flows (auto-imports from JSON)
- Spanish/English queues with language routing
- Routing profiles for agent assignment
- Hours of operation
- Lambda function associations
- Phone number configuration

### **Integration Flow**
1. **SAM deploys** → Core infrastructure ready
2. **CDK deploys** → Connect resources created
3. **SAM updates** → Connect resource IDs injected into Lambda environment variables
4. **System ready** → Complete dialer operational

## 📋 **Prerequisites**

### **AWS Requirements**
- Amazon Connect instance already created
- AWS account with appropriate permissions
- IAM user with Connect + CloudFormation permissions

### **External Services**
- Supabase project with customer data
- GitHub repository configured with Actions

### **Development Tools** (for local deployment)
- AWS CLI configured
- AWS SAM CLI installed
- Node.js 18+ and Yarn
- AWS CDK CLI (`npm install -g aws-cdk`)

## 🔧 **GitHub Secrets Setup**

Configure **only 8 secrets** (down from 20+ previously!):

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Staging Environment  
STAGING_CONNECT_INSTANCE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
STAGING_SUPABASE_URL=https://your-staging-project.supabase.co
STAGING_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Production Environment
PROD_CONNECT_INSTANCE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  
PROD_SUPABASE_URL=https://your-production-project.supabase.co
PROD_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**That's it!** All Connect resource IDs are now automated.

## 🚀 **Deployment Process**

### **Automatic Deployment (Recommended)**

#### **Staging Deployment:**
```bash
git checkout develop
git add .
git commit -m "Your changes"
git push origin develop
```

#### **Production Deployment:**
```bash
git checkout main  
git merge develop
git push origin main
```

### **Manual Local Deployment** (Optional)

#### **Deploy SAM Infrastructure:**
```bash
cd infra
sam build --use-container
sam deploy --guided --stack-name vistocapital-dialer-dev
```

#### **Deploy CDK Connect Resources:**
```bash
cd cdk
yarn install
cdk bootstrap  # First time only
cdk deploy ViStoCapital-Connect-dev \
  --parameters ConnectInstanceId=your-instance-id \
  --context environment=dev
```

## 🔄 **Deployment Stages Explained**

### **Stage 1: Validation (2-3 minutes)**
- ✅ **test**: Lambda function testing  
- ✅ **validate-template**: SAM template validation
- ✅ **validate-cdk**: CDK template synthesis and validation

### **Stage 2: SAM Infrastructure (5-8 minutes)**
- ✅ **Deploy Lambda functions**: All dialer logic functions
- ✅ **Create DynamoDB tables**: Active dialing + lead cache
- ✅ **Setup S3 buckets**: Input lists + results storage  
- ✅ **Configure SQS queues**: Dialing queue management
- ✅ **Create IAM roles**: Lambda execution permissions
- ✅ **Deploy state machines**: Dialer control workflows

### **Stage 3: CDK Connect Automation (3-5 minutes)**
- ✅ **Import contact flow**: From `contact-flows/UnifiedDialerContactFlow.json`
- ✅ **Create Spanish queue**: "ViSto Capital - Spanish Support"
- ✅ **Create English queue**: "ViSto Capital - English Support"  
- ✅ **Setup routing profile**: Language-based agent routing
- ✅ **Configure hours**: 9 AM - 6 PM EST business hours
- ✅ **Associate Lambda functions**: Connect dialer functions to contact flow

### **Stage 4: Integration (1-2 minutes)** 
- ✅ **Extract Connect IDs**: From CDK stack outputs
- ✅ **Update SAM parameters**: Inject Connect resource IDs
- ✅ **Redeploy Lambda environment**: Variables updated with Connect resources
- ✅ **System ready**: Complete unified dialer operational

**Total Deployment Time: ~12-18 minutes**

## 📊 **Deployment Outputs**

### **SAM Stack Outputs:**
```json
{
  "LookupSupabaseFunctionArn": "arn:aws:lambda:us-east-1:123456789012:function:vistocapital-dialer-LookupSupabaseFunction",
  "DialingListBucket": "vistocapital-dialer-dialinglistbucket-xxxxx",
  "ResultsBucket": "vistocapital-dialer-resultsbucket-xxxxx",
  "ActiveDialingTable": "vistocapital-dialer-ActiveDialingTable",
  "DialingQueueUrl": "https://sqs.us-east-1.amazonaws.com/123456789012/vistocapital-dialer-DialingQueue"
}
```

### **CDK Stack Outputs:**
```json  
{
  "ContactFlowId": "12345678-1234-1234-1234-123456789012",
  "SpanishQueueId": "12345678-1234-1234-1234-123456789012", 
  "EnglishQueueId": "12345678-1234-1234-1234-123456789012",
  "RoutingProfileId": "12345678-1234-1234-1234-123456789012",
  "HoursOfOperationId": "12345678-1234-1234-1234-123456789012"
}
```

## 🌍 **Environment Configuration**

### **Staging Environment**
- **Concurrent Calls**: 3 (conservative testing)
- **Validation**: Relaxed phone number validation
- **Auto-deployment**: On push to `develop` branch
- **Connect Instance**: Separate staging instance recommended

### **Production Environment**  
- **Concurrent Calls**: 10 (full capacity)
- **Validation**: Strict phone number validation
- **Manual approval**: Required for production deployments
- **Connect Instance**: Production Connect instance

## 🔍 **Monitoring & Troubleshooting**

### **GitHub Actions Monitoring**
- **Real-time logs**: Watch deployment progress in Actions tab
- **Stack outputs**: Automatically posted to PR comments
- **Release notes**: Auto-generated with deployment details

### **AWS CloudWatch Monitoring**
- **Lambda logs**: `/aws/lambda/vistocapital-dialer-*`
- **Connect logs**: Connect instance → Logging
- **DynamoDB metrics**: Table throughput and capacity

### **Common Issues & Solutions**

#### **"Connect Instance Not Found"**
```bash
# Verify your Connect instance ID
aws connect list-instances
```

#### **"CDK Bootstrap Required"**  
```bash
cd cdk
cdk bootstrap aws://ACCOUNT-ID/REGION
```

#### **"Permission Denied on Connect API"**
- Ensure IAM user has `connect:*` permissions
- Check Connect instance security profile

#### **"Contact Flow Import Failed"**
- Verify `contact-flows/UnifiedDialerContactFlow.json` is valid
- Check Connect instance supports contact flow features

## 🔄 **Updates & Maintenance**

### **Updating Contact Flows**
1. Edit `contact-flows/UnifiedDialerContactFlow.json`
2. Commit and push changes
3. CDK automatically updates the flow in Connect

### **Adding New Lambda Functions**
1. Add function to `infra/template.yaml`
2. Deploy via SAM
3. Associate with Connect using CDK custom resources

### **Scaling Configuration**
- **Staging**: Modify `ConcurrentCalls=3` in workflow
- **Production**: Modify `ConcurrentCalls=10` in workflow
- **Auto-scaling**: DynamoDB and Lambda scale automatically

## 📞 **Testing Your Deployment**

### **1. Verify Infrastructure**
```bash
# Check SAM stack
aws cloudformation describe-stacks --stack-name vistocapital-dialer-staging

# Check CDK stack  
aws cloudformation describe-stacks --stack-name ViStoCapital-Connect-staging
```

### **2. Test Supabase Integration**
```bash
# Test lookup function
aws lambda invoke --function-name vistocapital-dialer-LookupSupabaseFunction \
  --payload '{"phone":"+1234567890"}' response.json
```

### **3. Verify Connect Configuration**
- Log into Amazon Connect admin portal
- Check queues: "ViSto Capital - Spanish Support", "ViSto Capital - English Support"
- Verify contact flow: "Unified Dialer Contact Flow"
- Test routing profiles and hours of operation

## 🎯 **Next Steps After Deployment**

1. **Configure agents**: Assign agents to Spanish/English routing profiles
2. **Upload contact lists**: Use the S3 bucket for CSV uploads
3. **Start campaigns**: Use the dialer control state machine
4. **Monitor results**: Check ResultsBucket and DynamoDB tables
5. **Review metrics**: CloudWatch dashboards and Connect analytics

## 📚 **Additional Resources**

- [GITHUB_SECRETS.md](GITHUB_SECRETS.md) - Secrets configuration
- [AMAZON_CONNECT_SETUP_GUIDE.md](AMAZON_CONNECT_SETUP_GUIDE.md) - Manual setup (deprecated)
- [DAILY_CAMPAIGN_WORKFLOW.md](DAILY_CAMPAIGN_WORKFLOW.md) - Campaign operations
- [GitHub Actions Workflow](.github/workflows/deploy.yml) - CI/CD configuration

## 🆘 **Support**

For deployment issues:
1. **GitHub Actions logs**: Check workflow execution details
2. **AWS CloudTrail**: Review API calls and permissions
3. **CloudFormation events**: Check stack deployment logs
4. **Connect admin portal**: Verify resource creation
5. **Lambda logs**: Check function execution in CloudWatch

The automated deployment eliminates 95% of manual Connect configuration - enjoy your fully automated unified dialer! 🚀 