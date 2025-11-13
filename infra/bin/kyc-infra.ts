#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { KycInfraStack } from '../lib/kyc-infra-stack';

const app = new cdk.App();

new KycInfraStack(app, 'KycInfraStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'KYC Agentic System Infrastructure',
});
