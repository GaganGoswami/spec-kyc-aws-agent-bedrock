#!/bin/bash

# LocalStack initialization script
# This script runs automatically when LocalStack container starts
# It creates all necessary AWS resources for local development

set -e

echo "🚀 Initializing LocalStack AWS resources..."

# Set AWS endpoint
export AWS_ENDPOINT="http://localhost:4566"
export AWS_DEFAULT_REGION="us-east-1"

# Wait for LocalStack to be ready
echo "⏳ Waiting for LocalStack to be ready..."
until curl -s "${AWS_ENDPOINT}/_localstack/health" | grep -q '"s3": "available"'; do
  sleep 2
done
echo "✅ LocalStack is ready!"

# Create S3 buckets
echo "📦 Creating S3 buckets..."
awslocal s3 mb s3://kyc-documents-dev 2>/dev/null || echo "  - S3 bucket kyc-documents-dev already exists"
awslocal s3 mb s3://kyc-snapshots-dev 2>/dev/null || echo "  - S3 bucket kyc-snapshots-dev already exists"
awslocal s3 mb s3://kyc-test-documents 2>/dev/null || echo "  - S3 bucket kyc-test-documents already exists"

# Enable versioning on buckets
awslocal s3api put-bucket-versioning \
  --bucket kyc-documents-dev \
  --versioning-configuration Status=Enabled

awslocal s3api put-bucket-versioning \
  --bucket kyc-snapshots-dev \
  --versioning-configuration Status=Enabled

echo "✅ S3 buckets created and configured"

# Create DynamoDB tables
echo "📊 Creating DynamoDB tables..."

# Sessions table
awslocal dynamodb create-table \
  --table-name kyc-sessions \
  --attribute-definitions \
    AttributeName=session_id,AttributeType=S \
  --key-schema \
    AttributeName=session_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  2>/dev/null || echo "  - DynamoDB table kyc-sessions already exists"

# Agent state table
awslocal dynamodb create-table \
  --table-name kyc-agent-state \
  --attribute-definitions \
    AttributeName=case_id,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=case_id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  2>/dev/null || echo "  - DynamoDB table kyc-agent-state already exists"

echo "✅ DynamoDB tables created"

# Create SQS queues (for Phase 2+)
echo "📨 Creating SQS queues..."
awslocal sqs create-queue --queue-name kyc-agent-tasks 2>/dev/null || echo "  - SQS queue kyc-agent-tasks already exists"
awslocal sqs create-queue --queue-name kyc-dlq 2>/dev/null || echo "  - SQS queue kyc-dlq already exists"

echo "✅ SQS queues created"

# Create SNS topics (for Phase 2+)
echo "📢 Creating SNS topics..."
awslocal sns create-topic --name kyc-alerts 2>/dev/null || echo "  - SNS topic kyc-alerts already exists"

echo "✅ SNS topics created"

echo ""
echo "🎉 LocalStack initialization complete!"
echo ""
echo "Available resources:"
echo "  - S3 Buckets: kyc-documents-dev, kyc-snapshots-dev, kyc-test-documents"
echo "  - DynamoDB Tables: kyc-sessions, kyc-agent-state"
echo "  - SQS Queues: kyc-agent-tasks, kyc-dlq"
echo "  - SNS Topics: kyc-alerts"
echo ""
echo "Access LocalStack at: ${AWS_ENDPOINT}"
echo ""
