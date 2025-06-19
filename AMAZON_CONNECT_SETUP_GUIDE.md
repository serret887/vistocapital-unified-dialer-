# Amazon Connect Manual Setup Guide

## ❗ Why Amazon Connect Resources Aren't Created by CI/CD

The CI/CD pipeline deploys **supporting AWS infrastructure** (Lambda functions, DynamoDB tables, S3 buckets, etc.) but **DOES NOT create Amazon Connect resources** like contact flows, queues, or routing profiles. This is by design for several important reasons:

### 🔐 **Security & Permissions**
- Amazon Connect has separate IAM permissions from other AWS services
- Contact center operations require specialized Amazon Connect admin privileges
- Connect resources are typically managed by contact center administrators, not DevOps

### 🏗️ **Architecture Limitations**
- **No CloudFormation Support**: Amazon Connect resources cannot be defined in CloudFormation/SAM templates
- **Manual Configuration Required**: Connect contact flows, queues, and routing must be configured through the Connect console
- **Instance-Specific**: Each Connect instance requires individual configuration

### 🎯 **Operational Separation**
- Contact flows contain business logic that contact center managers need to control
- Routing profiles and queues affect live customer operations
- Phone numbers and hours of operation are business decisions, not deployment decisions

---

## 🛠️ Required Manual Amazon Connect Configuration

### **Step 1: Prepare Connect Instance Information**

You need these from your Amazon Connect instance:

```bash
# Get these values from Amazon Connect console
CONNECT_INSTANCE_ID="12345678-1234-1234-1234-123456789012"
CONTACT_FLOW_ID="12345678-1234-1234-1234-123456789012"  
QUEUE_ID="12345678-1234-1234-1234-123456789012"
```

**How to find these values:**

1. **Instance ID**: 
   - Amazon Connect Console → Access URL 
   - Copy from URL: `https://INSTANCE.my.connect.aws/ccp-v2/`
   - Instance ID is the INSTANCE part

2. **Contact Flow ID**:
   - Connect Admin Console → Routing → Contact Flows
   - Select your outbound contact flow → Show additional flow information
   - Copy the ID from the ARN (after `contact-flow/`)

3. **Queue ID**:
   - Connect Admin Console → Routing → Queues  
   - Select your queue → Show additional queue information
   - Copy the ID from the ARN (after `queue/`)

---

### **Step 2: Import the Unified Contact Flow**

The contact flow contains the business logic for handling calls with Supabase integration.

1. **Navigate to Contact Flows**:
   ```
   Amazon Connect Admin Console → Routing → Contact Flows
   ```

2. **Create New Contact Flow**:
   - Click "Create contact flow"
   - Select "Contact flow (inbound)" type
   - Name it "Unified Dialer Contact Flow"

3. **Import the Flow**:
   - Click "Import flow (beta)" or use the import option
   - Upload `contact-flows/UnifiedDialerContactFlow.json`
   - **Important**: Update the Lambda function ARNs in the flow

4. **Configure Lambda Function ARNs**:
   ```json
   // Replace placeholders with actual deployed function ARNs
   "FunctionArn": "arn:aws:lambda:REGION:ACCOUNT:function:STACK-LookupSupabaseFunction-HASH"
   ```

5. **Update Queue ARNs**:
   ```json
   // Update queue references with your actual queue IDs
   "QueueId": "arn:aws:connect:REGION:ACCOUNT:instance/INSTANCE-ID/queue/QUEUE-ID"
   ```

6. **Save and Publish**:
   - Save the contact flow
   - Click "Publish" to make it active
   - Copy the new Contact Flow ID for deployment

---

### **Step 3: Configure Lambda Function Permissions**

Add the deployed Lambda functions to Amazon Connect:

1. **Navigate to Lambda Integration**:
   ```
   Amazon Connect Admin Console → Routing → AWS Lambda
   ```

2. **Add Functions**:
   - Click "Add Lambda Function"
   - Add these functions from your deployment:
     ```
     LookupSupabaseFunction-XXXXX
     SetDispositionFunction-XXXXX  
     GetConfigFunction-XXXXX
     ```

3. **Test Function Access**:
   - Verify functions appear in contact flow blocks
   - Test function invocation from a test contact flow

---

### **Step 4: Create Language-Specific Queues**

For the language-based routing feature:

1. **Create English Queue**:
   ```
   Routing → Queues → Add new queue
   Name: "English Support Queue"
   Hours of Operation: [Your business hours]
   ```

2. **Create Spanish Queue**:
   ```
   Routing → Queues → Add new queue  
   Name: "Spanish Support Queue"
   Hours of Operation: [Your business hours]
   ```

3. **Configure Routing Profiles**:
   ```
   Users → Routing profiles → Create routing profile
   Name: "English-Speaking-Profile"
   Queues: Add English Support Queue
   
   Name: "Spanish-Speaking-Profile" 
   Queues: Add Spanish Support Queue
   ```

---

### **Step 5: Configure GitHub Secrets**

Update your GitHub repository secrets with the actual Connect resource IDs:

```bash
# Staging Environment
STAGING_CONNECT_INSTANCE_ID="12345678-1234-1234-1234-123456789012"
STAGING_CONTACT_FLOW_ID="12345678-1234-1234-1234-123456789012"
STAGING_QUEUE_ID="12345678-1234-1234-1234-123456789012"

# Production Environment  
PROD_CONNECT_INSTANCE_ID="12345678-1234-1234-1234-123456789012"
PROD_CONTACT_FLOW_ID="12345678-1234-1234-1234-123456789012"
PROD_QUEUE_ID="12345678-1234-1234-1234-123456789012"
```

**Note**: Use the same instance for staging/prod or separate instances if you have them.

---

### **Step 6: Test End-to-End Integration**

1. **Test Contact Flow**:
   - Use Connect's contact flow testing feature
   - Verify Lambda functions are invoked correctly
   - Check Supabase data is retrieved and displayed

2. **Test Outbound Calling**:
   ```bash
   aws connect start-outbound-voice-contact \
     --destination-phone-number "+1234567890" \
     --contact-flow-id "YOUR_CONTACT_FLOW_ID" \
     --instance-id "YOUR_INSTANCE_ID" \
     --queue-id "YOUR_QUEUE_ID"
   ```

3. **Monitor Logs**:
   - Check CloudWatch logs for Lambda functions
   - Verify DynamoDB writes to ActiveDialingTable
   - Monitor Connect contact trace records

---

## 🔄 CI/CD Integration

Once manual setup is complete, your CI/CD pipeline will:

✅ **Deploy Infrastructure**: Lambda functions, DynamoDB, S3, etc.  
✅ **Update Function Code**: Latest versions of your business logic  
✅ **Configure Parameters**: SSM parameters for Connect integration  
❌ **NOT Create Connect Resources**: Contact flows, queues, routing profiles  

### **Deployment Parameter Mapping**

The CI/CD pipeline expects these secrets to be configured:

| GitHub Secret | Connect Resource | How to Get |
|---------------|------------------|------------|
| `STAGING_CONNECT_INSTANCE_ID` | Connect Instance | Connect Console → Instance ID |
| `STAGING_CONTACT_FLOW_ID` | Contact Flow | Flow → Additional Information |
| `STAGING_QUEUE_ID` | Queue | Queue → Additional Information |

---

## 🚨 Troubleshooting Common Issues

### **Issue: Contact Flow Import Fails**
```
Error: Invalid Lambda function ARN
```
**Solution**: Replace placeholder ARNs with actual deployed function ARNs

### **Issue: Lambda Function Not Available in Contact Flow**
```
Function not found in dropdown
```
**Solution**: Add function to Connect → Routing → AWS Lambda

### **Issue: Queue Not Found**
```
Error: Queue does not exist
```
**Solution**: Verify queue ID is correct and queue exists in Connect

### **Issue: No Audio in Test Call**
```
Call connects but no prompts play
```
**Solution**: Check contact flow configuration and audio prompt settings

---

## 📋 Pre-Deployment Checklist

Before running CI/CD deployment:

- [ ] Amazon Connect instance is created and configured
- [ ] Contact flow imported and Lambda ARNs updated
- [ ] Lambda functions added to Connect integration
- [ ] Queues created for English and Spanish routing
- [ ] Routing profiles configured for language-based routing
- [ ] GitHub secrets updated with actual Connect resource IDs
- [ ] Test outbound calling works manually
- [ ] Supabase credentials are valid and accessible

---

## 🎯 Next Steps

1. **Complete Manual Setup**: Follow this guide to configure Connect resources
2. **Update GitHub Secrets**: Add the actual Connect resource IDs  
3. **Run CI/CD Pipeline**: Deploy infrastructure and Lambda functions
4. **Test Integration**: Verify end-to-end functionality
5. **Monitor & Optimize**: Use CloudWatch to monitor performance

---

## 💡 Why This Approach?

This hybrid approach (Infrastructure as Code + Manual Connect Config) provides:

- **🔐 Security**: Proper separation of infrastructure and contact center operations
- **🎯 Flexibility**: Contact center admins can modify flows without affecting deployments  
- **🚀 Speed**: Automated infrastructure deployment with business-controlled contact flows
- **📊 Compliance**: Audit trail for both infrastructure changes and contact center modifications

The AWS Lambda functions, databases, and core infrastructure are fully automated through CI/CD, while the Amazon Connect contact center configuration remains under contact center administrator control - this is the recommended AWS best practice for contact center deployments. 