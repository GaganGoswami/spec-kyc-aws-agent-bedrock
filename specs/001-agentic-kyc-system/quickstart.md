# Quickstart Guide: KYC Agent System

**Feature**: 001-agentic-kyc-system  
**Version**: 1.0.0  
**Date**: 2025-11-12

## Overview

This guide walks you through setting up a complete local development environment for the KYC Agent System. You'll run the backend API, frontend UI, database, and mock AWS services locally in under 30 minutes.

---

## Prerequisites

### Required Software

- **Docker Desktop** (v24+): For running Postgres, LocalStack, and services
- **Node.js** (v20+): For frontend development
- **Python** (v3.11+): For backend development
- **AWS CLI** (v2+): For AWS service interactions
- **Git**: For version control

### Recommended Tools

- **VS Code**: IDE with extensions (Python, ESLint, Prettier, REST Client)
- **DBeaver** or **pgAdmin**: Database GUI
- **Postman** or **Insomnia**: API testing
- **wscat**: WebSocket testing (`npm install -g wscat`)

### Verify Installations

```bash
docker --version          # Docker version 24.0.0 or higher
node --version            # v20.0.0 or higher
python3 --version         # Python 3.11.0 or higher
aws --version             # aws-cli/2.0.0 or higher
git --version             # git version 2.40.0 or higher
```

---

## Quick Start (5 Minutes)

### 1. Clone Repository

```bash
git clone https://github.com/your-org/spec-kyc-aws-agent-bedrock.git
cd spec-kyc-aws-agent-bedrock
```

### 2. Start Infrastructure

```bash
# Start Docker Compose services (Postgres, LocalStack, Redis)
docker-compose up -d

# Wait for services to be healthy (30 seconds)
docker-compose ps
```

### 3. Setup Backend

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Run database migrations
alembic upgrade head

# Seed test data (users, roles, sample cases)
python scripts/seed-test-data.py

# Start backend server
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

Backend now running at: `http://localhost:8000`  
API docs: `http://localhost:8000/docs`

### 4. Setup Frontend

```bash
# Open new terminal
cd frontend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Start development server
npm start
```

Frontend now running at: `http://localhost:3000`

### 5. Test the System

```bash
# Login (in new terminal)
curl -X POST http://localhost:8000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "test_officer", "password": "TestPassword123!"}'

# Returns:
# {
#   "access_token": "eyJhbGci...",
#   "refresh_token": "eyJhbGci...",
#   "token_type": "bearer"
# }

# Visit frontend
open http://localhost:3000
# Login with: test_officer / TestPassword123!
```

---

## Detailed Setup

### Environment Configuration

#### Backend `.env`

Create `backend/.env`:

```bash
# Application
APP_ENV=development
APP_DEBUG=true
LOG_LEVEL=DEBUG

# Database
DATABASE_URL=postgresql://kyc_user:kyc_password@localhost:5432/kyc_db
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20

# JWT Authentication
JWT_SECRET_KEY=your-secret-key-change-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# AWS Configuration (LocalStack)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_ENDPOINT_URL=http://localhost:4566
S3_BUCKET_DOCUMENTS=kyc-documents-dev
S3_BUCKET_SNAPSHOTS=kyc-audit-snapshots-dev

# AWS Bedrock (use LocalStack or actual AWS)
BEDROCK_MODEL_ID_REASONING=anthropic.claude-3-5-sonnet-20250101
BEDROCK_MODEL_ID_EMBEDDINGS=amazon.titan-embed-text-v1
BEDROCK_REGION=us-east-1

# External APIs (Mock endpoints)
SCREENING_API_URL=http://localhost:8001/mock-screening
SCREENING_API_KEY=test-api-key

# Redis (for caching and rate limiting)
REDIS_URL=redis://localhost:6379/0

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# Feature Flags
ENABLE_AGENT_WORKFLOWS=true
ENABLE_REAL_TIME_UPDATES=true
```

#### Frontend `.env.local`

Create `frontend/.env.local`:

```bash
# API Configuration
REACT_APP_API_BASE_URL=http://localhost:8000/v1
REACT_APP_WS_URL=ws://localhost:8000/ws

# Feature Flags
REACT_APP_ENABLE_AGENT_WORKFLOWS=true
REACT_APP_ENABLE_RELATIONSHIP_GRAPH=true

# Environment
REACT_APP_ENV=development
```

---

### Docker Compose Services

The `docker-compose.yml` includes:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: kyc-postgres
    environment:
      POSTGRES_DB: kyc_db
      POSTGRES_USER: kyc_user
      POSTGRES_PASSWORD: kyc_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kyc_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  localstack:
    image: localstack/localstack:3.0
    container_name: kyc-localstack
    environment:
      SERVICES: s3,dynamodb,lambda,apigateway,bedrock
      DEBUG: 1
      DATA_DIR: /tmp/localstack/data
    ports:
      - "4566:4566"  # LocalStack edge port
    volumes:
      - localstack_data:/tmp/localstack
      - ./scripts/localstack-init.sh:/etc/localstack/init/ready.d/init.sh
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/_localstack/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: kyc-redis
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  localstack_data:
```

### LocalStack Initialization

Create `scripts/localstack-init.sh`:

```bash
#!/bin/bash

# Wait for LocalStack to be ready
awslocal s3 ls || exit 1

# Create S3 buckets
awslocal s3 mb s3://kyc-documents-dev
awslocal s3 mb s3://kyc-audit-snapshots-dev

# Enable S3 versioning
awslocal s3api put-bucket-versioning \
  --bucket kyc-documents-dev \
  --versioning-configuration Status=Enabled

awslocal s3api put-bucket-versioning \
  --bucket kyc-audit-snapshots-dev \
  --versioning-configuration Status=Enabled

# Create DynamoDB tables
awslocal dynamodb create-table \
  --table-name AgentSessions \
  --attribute-definitions \
    AttributeName=session_id,AttributeType=S \
    AttributeName=case_id,AttributeType=S \
    AttributeName=status,AttributeType=S \
  --key-schema \
    AttributeName=session_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes \
    "[
      {
        \"IndexName\": \"GSI1\",
        \"KeySchema\": [{\"AttributeName\":\"case_id\",\"KeyType\":\"HASH\"},{\"AttributeName\":\"status\",\"KeyType\":\"RANGE\"}],
        \"Projection\": {\"ProjectionType\":\"ALL\"}
      }
    ]"

awslocal dynamodb create-table \
  --table-name EmbeddingsStore \
  --attribute-definitions \
    AttributeName=embedding_id,AttributeType=S \
    AttributeName=entity_type,AttributeType=S \
    AttributeName=entity_id,AttributeType=S \
  --key-schema \
    AttributeName=embedding_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes \
    "[
      {
        \"IndexName\": \"GSI1\",
        \"KeySchema\": [{\"AttributeName\":\"entity_type\",\"KeyType\":\"HASH\"},{\"AttributeName\":\"entity_id\",\"KeyType\":\"RANGE\"}],
        \"Projection\": {\"ProjectionType\":\"ALL\"}
      }
    ]"

echo "LocalStack initialization complete"
```

---

## Database Management

### Run Migrations

```bash
cd backend

# Create new migration (after model changes)
alembic revision --autogenerate -m "Add new table"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history
```

### Seed Test Data

```bash
# Seed users, roles, and sample cases
python scripts/seed-test-data.py

# Creates:
# - 4 roles (case_officer, senior_officer, manager, administrator)
# - 4 test users (test_officer, test_senior, test_manager, test_admin)
# - 3 sample cases (LOW, MEDIUM, HIGH risk)
# - 10 sample documents
```

### Database Connection

```bash
# Connect via psql
psql postgresql://kyc_user:kyc_password@localhost:5432/kyc_db

# Useful queries
\dt                        # List tables
\d+ cases                  # Describe cases table
SELECT * FROM users;       # Query users
```

---

## Running the Backend

### Development Server

```bash
cd backend
source venv/bin/activate

# Run with auto-reload
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Run with specific workers
uvicorn src.main:app --workers 4 --host 0.0.0.0 --port 8000

# Run with verbose logging
uvicorn src.main:app --reload --log-level debug
```

**API Documentation**: Visit `http://localhost:8000/docs` for interactive Swagger UI

### Testing Backend

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_cases.py

# Run specific test
pytest tests/test_cases.py::test_create_case

# Run only unit tests (fast)
pytest -m unit

# Run integration tests (slower)
pytest -m integration
```

### Debugging Backend

```python
# Add breakpoint in code
import pdb; pdb.set_trace()

# Or use debugpy for VS Code
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()
```

**VS Code launch.json**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["src.main:app", "--reload"],
      "jinja": true,
      "cwd": "${workspaceFolder}/backend"
    }
  ]
}
```

---

## Running the Frontend

### Development Server

```bash
cd frontend

# Start development server
npm start

# Start with custom port
PORT=3001 npm start

# Build for production
npm run build

# Preview production build
npm run preview
```

**Frontend URL**: `http://localhost:3000`

### Testing Frontend

```bash
# Run unit tests (Jest + RTL)
npm test

# Run with coverage
npm test -- --coverage

# Run E2E tests (Playwright)
npm run test:e2e

# Run E2E in UI mode
npm run test:e2e:ui
```

### Debugging Frontend

**Chrome DevTools**: `F12` → `Sources` tab → Set breakpoints

**React DevTools**: Install Chrome extension, inspect component tree

**Redux DevTools**: Install Chrome extension, inspect state changes

---

## Common Workflows

### 1. Create New Case

```bash
# Get authentication token
TOKEN=$(curl -X POST http://localhost:8000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "test_officer", "password": "TestPassword123!"}' \
  | jq -r '.access_token')

# Create new case
curl -X POST http://localhost:8000/v1/cases \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "client_data": {
      "client_type": "INDIVIDUAL",
      "legal_name": "John Doe",
      "first_name": "John",
      "last_name": "Doe",
      "date_of_birth": "1980-01-15",
      "nationality": "USA",
      "email": "john.doe@example.com",
      "is_high_net_worth": true,
      "estimated_net_worth_usd": 10000000
    },
    "priority": "NORMAL"
  }' | jq
```

### 2. Upload Document

```bash
# Upload passport document
curl -X POST "http://localhost:8000/v1/cases/{case_id}/documents" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/passport.pdf" \
  -F "document_type=passport" | jq
```

### 3. Execute Screening

```bash
# Run sanctions and PEP screening
curl -X POST "http://localhost:8000/v1/cases/{case_id}/screening" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "screening_types": ["SANCTIONS", "PEP"],
    "provider": "world_check"
  }' | jq
```

### 4. Compute Risk Assessment

```bash
# Trigger AI risk scoring
curl -X POST "http://localhost:8000/v1/cases/{case_id}/risk-assessment" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 5. Approve Case

```bash
# Approve case with rationale
curl -X POST "http://localhost:8000/v1/cases/{case_id}/approve" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "decision_rationale": "All screening checks passed. Risk level is LOW. Documentation is complete and consistent with claimed source of wealth (inheritance). No red flags identified."
  }' | jq
```

---

## Testing with WebSocket

### Using wscat

```bash
# Install wscat
npm install -g wscat

# Connect to WebSocket
wscat -c "ws://localhost:8000/ws?token=$TOKEN"

# Subscribe to case updates
> {"type":"subscribe","channel":"case.{case_id}","message_id":"test-1"}

# Wait for events (trigger actions via REST API in another terminal)
< {"type":"event","channel":"case.{case_id}","event_name":"case.status_changed",...}
```

### Using JavaScript

```javascript
const ws = new WebSocket(`ws://localhost:8000/ws?token=${accessToken}`);

ws.onopen = () => {
  console.log('Connected');
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'case.123e4567-e89b-12d3-a456-426614174000',
    message_id: crypto.randomUUID()
  }));
};

ws.onmessage = (event) => {
  console.log('Message:', JSON.parse(event.data));
};
```

---

## Troubleshooting

### Backend Won't Start

**Error**: `ModuleNotFoundError: No module named 'fastapi'`

**Fix**:
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

---

**Error**: `psycopg2.OperationalError: could not connect to server`

**Fix**:
```bash
# Check Postgres is running
docker-compose ps postgres

# If not running, start it
docker-compose up -d postgres

# Check connection
psql postgresql://kyc_user:kyc_password@localhost:5432/kyc_db
```

---

**Error**: `alembic.util.exc.CommandError: Can't locate revision identified by`

**Fix**:
```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres

# Wait 10 seconds, then re-run migrations
alembic upgrade head
```

---

### Frontend Won't Start

**Error**: `Cannot find module 'react'`

**Fix**:
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

---

**Error**: `CORS policy: No 'Access-Control-Allow-Origin' header`

**Fix**: Add `http://localhost:3000` to `CORS_ORIGINS` in `backend/.env`, restart backend

---

### LocalStack Issues

**Error**: `botocore.exceptions.EndpointConnectionError`

**Fix**:
```bash
# Check LocalStack is running
docker-compose ps localstack

# View LocalStack logs
docker-compose logs localstack

# Restart LocalStack
docker-compose restart localstack
```

---

**Error**: `S3 bucket does not exist`

**Fix**:
```bash
# Re-run initialization script
docker-compose exec localstack /etc/localstack/init/ready.d/init.sh

# Or manually create buckets
awslocal s3 mb s3://kyc-documents-dev
```

---

### Port Already in Use

**Error**: `Address already in use: 8000`

**Fix**:
```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>

# Or use different port
uvicorn src.main:app --reload --port 8001
```

---

## Deployment

### Deploy to Development Environment

```bash
# Authenticate to AWS
aws sso login --profile kyc-dev

# Deploy infrastructure (CDK)
cd infrastructure
npm install
cdk deploy DevStack --profile kyc-dev

# Deploy backend (build Docker image, push to ECR, update Lambda)
cd backend
./scripts/deploy-dev.sh

# Deploy frontend (build static files, sync to S3, invalidate CloudFront)
cd frontend
npm run build
aws s3 sync build/ s3://kyc-frontend-dev --profile kyc-dev
aws cloudfront create-invalidation --distribution-id E123456 --paths "/*" --profile kyc-dev
```

### Deploy to Staging/Production

```bash
# Requires approval workflow (GitHub Actions)
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will:
# 1. Run tests
# 2. Build Docker images
# 3. Deploy to staging
# 4. Run smoke tests
# 5. Wait for manual approval
# 6. Deploy to production
```

---

## Useful Commands Reference

### Backend

```bash
# Start backend
uvicorn src.main:app --reload

# Run tests
pytest

# Run linter
ruff check .

# Format code
black .

# Type checking
mypy src/

# Database migrations
alembic upgrade head
```

### Frontend

```bash
# Start frontend
npm start

# Run tests
npm test

# Lint
npm run lint

# Format
npm run format

# Build
npm run build
```

### Docker

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Reset everything (CAUTION: deletes data)
docker-compose down -v
```

### Database

```bash
# Connect to Postgres
psql postgresql://kyc_user:kyc_password@localhost:5432/kyc_db

# Backup database
pg_dump -U kyc_user kyc_db > backup.sql

# Restore database
psql -U kyc_user kyc_db < backup.sql
```

---

## Next Steps

1. **Read the Specification**: `specs/001-agentic-kyc-system/spec.md`
2. **Review Data Model**: `specs/001-agentic-kyc-system/data-model.md`
3. **Study API Contracts**: `specs/001-agentic-kyc-system/contracts/api.openapi.yaml`
4. **Explore Codebase**: Start with `backend/src/main.py` and `frontend/src/App.tsx`
5. **Run Tests**: `pytest` (backend), `npm test` (frontend)
6. **Create First Feature**: Follow TDD workflow from constitution

---

## Support

- **Technical Issues**: Create GitHub issue with `bug` label
- **Questions**: Use GitHub Discussions or Slack `#kyc-platform` channel
- **Documentation**: Update this guide if you discover missing steps

---

## Summary

You now have a fully functional local KYC system running:
- ✅ Backend API (`http://localhost:8000`)
- ✅ Frontend UI (`http://localhost:3000`)
- ✅ Postgres database (`localhost:5432`)
- ✅ LocalStack (AWS services mock)
- ✅ Test users and sample data

**Happy coding!** 🚀
