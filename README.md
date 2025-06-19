# ViSto Capital - Unified Omnichannel Dialer

A comprehensive, Supabase-aware omnichannel dialer stack built on AWS Connect for ViSto Capital. This unified system combines power dialing capabilities with advanced lead management, language-based routing, and intelligent campaign automation.

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- AWS SAM CLI installed
- Node.js 18+ (for Lambda functions)
- Python 3.9+ (for Lambda functions)
- Git

### Setup

1. **Clone and setup environment:**
   ```bash
   git clone <repository-url>
   cd vistocapital-unified-dialer
   ./setup-env.sh
   ```

2. **Configure your environment:**
   - Edit `.env` with your AWS and deployment settings
   - Edit `lambdas/lookupSupabase/.env` with your Supabase credentials
   - Review and update configuration as needed

3. **Deploy the infrastructure:**
   ```bash
   cd infra
   sam build && sam deploy --guided
   ```

## 📁 Project Structure

```
├── .github/workflows/     # GitHub Actions CI/CD
├── amazon-connect-power-dialer/  # Legacy power dialer components
├── contact-flows/         # Amazon Connect contact flows
├── infra/                # SAM infrastructure templates
├── lambdas/              # Lambda function implementations
├── statemachine/         # Step Functions workflows
├── voice-channel-for-outbound-campaigns/  # Legacy campaign components
├── setup-env.sh          # Environment setup script
└── README.md
```

## 🎯 Key Features

### Unified Architecture
- **Single Infrastructure Stack**: Consolidated AWS resources
- **Supabase Integration**: Real-time lead lookup and management
- **Language-Based Routing**: Automatic Spanish/English routing
- **Omnichannel Support**: Voice, SMS, and future channels

### Advanced Campaign Management
- **Dynamic List Loading**: Automated campaign data ingestion
- **Real-Time Lead Lookup**: Instant customer data retrieval
- **Intelligent Disposition**: Automated result classification
- **Multi-Language Support**: Spanish and English campaigns

### DevOps & CI/CD
- **GitHub Actions**: Automated testing and deployment
- **Environment Management**: Separate staging and production
- **Infrastructure as Code**: SAM templates for reproducible deployments
- **Security**: Comprehensive secret management

## 🏗️ Architecture Components

### Core Infrastructure
- **S3 Buckets**: Campaign data and results storage
- **DynamoDB**: Active dialing state and lead cache
- **Lambda Functions**: Serverless processing logic
- **Step Functions**: Campaign workflow orchestration
- **Amazon Connect**: Contact center integration
- **EventBridge**: Event-driven automation

### Lambda Functions
- **lookupSupabase**: Customer data retrieval with caching
- **dial**: Outbound call initiation
- **getContacts**: Campaign contact management
- **setDisposition**: Call outcome processing
- **connectStatus**: Agent availability monitoring

### Data Flow
1. **Campaign Upload** → S3 Bucket
2. **List Processing** → Step Function workflow
3. **Lead Lookup** → Supabase integration with DynamoDB caching
4. **Call Routing** → Language-based queue assignment
5. **Result Processing** → Automated disposition and storage

## 📊 Daily Campaign Workflow

Our system supports automated daily campaign management:

1. **Morning Load**: Spanish campaigns (8 AM EST)
2. **Afternoon Load**: English campaigns (12 PM EST)
3. **Lead Segregation**: Automatic language-based routing
4. **Agent Assignment**: Queue-based distribution
5. **Real-Time Analytics**: Live campaign monitoring

For detailed workflow information, see [DAILY_CAMPAIGN_WORKFLOW.md](DAILY_CAMPAIGN_WORKFLOW.md).

## 🔧 Configuration

### Environment Variables

The system uses multiple environment files:

- **`.env`**: Main deployment configuration
- **`lambdas/lookupSupabase/.env`**: Supabase credentials
- **`infra/.env`**: Infrastructure-specific settings

### Supabase Integration

Configure your Supabase connection:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Amazon Connect

Required Connect configuration:
- Instance ID
- Contact Flow ID
- Queue IDs (Spanish/English)
- Security Profile permissions

## 🚀 Deployment

### Local Development
```bash
# Setup environment
./setup-env.sh

# Test Lambda functions locally
cd lambdas/lookupSupabase
npm test

# Deploy to development
cd infra
sam build && sam deploy --config-env dev
```

### Production Deployment

The system includes automated CI/CD via GitHub Actions:

1. **Push to develop** → Staging deployment
2. **Push to main** → Production deployment
3. **Automatic rollback** on deployment failures
4. **Environment protection** rules for production

For deployment details, see [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md).

### GitHub Actions Setup

Configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- And more...

For the complete list, see [GITHUB_SECRETS.md](GITHUB_SECRETS.md).

## 📈 Monitoring & Analytics

### CloudWatch Metrics
- Call volume and success rates
- Lambda function performance
- Error rates and latency

### Real-Time Dashboards
- Agent availability
- Campaign progress
- Lead conversion rates

### Alerting
- Failed calls notifications
- System error alerts
- Performance threshold warnings

## 🔒 Security

### Data Protection
- Encrypted data at rest (S3, DynamoDB)
- Encrypted data in transit (HTTPS/TLS)
- IAM role-based access control
- Secrets management via AWS Secrets Manager

### Compliance
- TCPA compliance features
- Do Not Call list integration
- Call recording and retention policies
- GDPR data handling capabilities

## 🛠️ Development

### Local Testing
```bash
# Run Lambda tests
cd lambdas/lookupSupabase
npm test

# Test with sample data
npm run test:integration

# Validate SAM templates
cd infra
sam validate
```

### Code Quality
- ESLint for JavaScript
- Black for Python
- Pre-commit hooks
- Automated testing in CI/CD

## 📚 Documentation

- [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Deployment guide
- [GITHUB_SECRETS.md](GITHUB_SECRETS.md) - CI/CD configuration
- [DAILY_CAMPAIGN_WORKFLOW.md](DAILY_CAMPAIGN_WORKFLOW.md) - Campaign management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is proprietary to ViSto Capital. All rights reserved.

## 📞 Support

For technical support or questions:
- Internal team: Use Slack #dialer-support
- Documentation issues: Create GitHub issue
- Production issues: Follow incident response procedures

---

**ViSto Capital Unified Dialer** - Powering intelligent omnichannel engagement 