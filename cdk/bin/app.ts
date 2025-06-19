#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ConnectAutomationStack } from '../lib/connect-automation-stack';

const app = new cdk.App();

// Get environment from context
const environment = app.node.tryGetContext('environment') || 'dev';
const account = app.node.tryGetContext('account') || process.env.CDK_DEFAULT_ACCOUNT;
const region = app.node.tryGetContext('region') || process.env.CDK_DEFAULT_REGION;

new ConnectAutomationStack(app, `ViStoCapital-Connect-${environment}`, {
  env: {
    account: account,
    region: region,
  },
  environment: environment,
  stackName: `vistocapital-unified-dialer-${environment}`, // Match your SAM stack name
}); 