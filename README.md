# AI-Powered Agentic KYC System

An intelligent, multi-agent system for Know Your Customer (KYC) due diligence processing for high-wealth clients, powered by AWS Bedrock and LangGraph.

## 🎯 Project Overview

This system automates complex KYC workflows using autonomous AI agents that collaborate to:
- Process client intake and document verification
- Perform entity screening against sanctions/PEP lists
- Conduct risk assessments and source of wealth (SOW) reviews
- Orchestrate escalations and approvals
- Maintain comprehensive audit trails

## 🏗️ Architecture

### System Components

- **Backend**: Python 3.11+ with FastAPI, LangChain/LangGraph
- **Frontend**: React 18 with TypeScript 5.0, TanStack Query
- **Infrastructure**: AWS (Lambda, Fargate, RDS, DynamoDB, S3, Bedrock)
- **AI Models**: Claude 3.5 Sonnet (reasoning), Titan Embeddings (search)

### Agent Microservices

1. **Intake Agent**: Initial client data processing
2. **Document Ingest Agent**: Document extraction and validation
3. **Screening Agent**: Sanctions/PEP/adverse media checks
4. **Entity Resolution Agent**: Duplicate detection and linking
5. **Enrichment Agent**: External data integration
6. **Risk Scoring Agent**: ML-based risk assessment
7. **SOW Review Agent**: Source of wealth analysis
8. **Workflow Agent**: Multi-agent orchestration
9. **Audit Agent**: Compliance logging and traceability

## 📋 Prerequisites

- **Python**: 3.11 or higher
- **Node.js**: 18 or higher
- **Docker**: 24.0+ and Docker Compose
- **AWS CLI**: v2 configured
- **Poetry**: Python dependency management
- **AWS CDK**: 2.x for infrastructure

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd spec-kyc-aws-agent-bedrock

# Copy environment configuration
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 2. Local Development with Docker

```bash
# Start LocalStack and databases
docker-compose up -d

# Wait for services to be ready
./scripts/wait-for-services.sh

# Initialize LocalStack resources
./scripts/localstack-init.sh
```

### 3. Backend Setup

```bash
cd backend

# Install dependencies with Poetry
poetry install

# Activate virtual environment
poetry shell

# Run database migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --port 8000
```

### 4. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

### 5. Infrastructure (AWS CDK)

```bash
cd infra

# Install dependencies
npm install

# Bootstrap CDK (first time only)
cdk bootstrap

# Deploy to AWS
cdk deploy --all
```

## 🧪 Testing

### Backend Tests

```bash
cd backend

# Run all tests with coverage
pytest --cov=app --cov-report=html

# Run specific test types
pytest tests/unit/          # Unit tests only
pytest tests/integration/   # Integration tests
pytest tests/e2e/          # End-to-end tests
```

### Frontend Tests

```bash
cd frontend

# Run unit tests
npm test

# Run E2E tests with Playwright
npm run test:e2e
```

### Contract Testing

```bash
# API contract validation with schemathesis
schemathesis run specs/001-agentic-kyc-system/contracts/api.openapi.yaml \
  --base-url http://localhost:8000
```

## 📁 Project Structure

```
spec-kyc-aws-agent-bedrock/
├── backend/                 # Python FastAPI backend
│   ├── app/
│   │   ├── agents/         # LangGraph agent implementations
│   │   ├── api/            # REST API endpoints
│   │   ├── core/           # Configuration, auth, logging
│   │   ├── db/             # Database models and repositories
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── main.py         # Application entry point
│   ├── alembic/            # Database migrations
│   ├── tests/              # Test suite
│   └── pyproject.toml      # Python dependencies
├── frontend/               # React TypeScript frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page components
│   │   ├── hooks/          # Custom React hooks
│   │   ├── services/       # API clients
│   │   ├── contexts/       # React contexts
│   │   └── types/          # TypeScript types
│   └── package.json        # Node dependencies
├── infra/                  # AWS CDK infrastructure
│   ├── lib/
│   │   ├── stacks/         # CDK stack definitions
│   │   └── constructs/     # Reusable CDK constructs
│   └── bin/                # CDK app entry point
├── scripts/                # Utility scripts
│   ├── localstack-init.sh  # LocalStack initialization
│   └── wait-for-services.sh
├── .github/
│   └── workflows/          # GitHub Actions CI/CD
├── specs/                  # Feature specifications
│   └── 001-agentic-kyc-system/
├── docker-compose.yml      # Local development services
└── .env.example            # Environment template
```

## 🔑 Key Features

### User Story 1: Client Intake and Basic Risk Assessment (MVP)
- Client profile creation
- Document upload and extraction (passport, utility bill)
- Automated sanctions/PEP screening
- Initial risk scoring
- Audit trail generation

### User Story 2: Enhanced Due Diligence (EDD)
- Entity resolution and duplicate detection
- External data enrichment (corporate registry, news)
- Source of wealth (SOW) review
- Advanced risk assessment

### User Story 3: Approval Workflows
- Case escalation routing
- Compliance officer review interface
- Approval/rejection with reasoning
- Multi-stage workflow orchestration

### User Story 4: Ongoing Monitoring
- Periodic re-screening (90-day cycles)
- Automated alerts on adverse media
- Risk score recalculation
- Historical case snapshots

## 🔐 Authentication

The system uses JWT-based authentication with role-based access control (RBAC):

- **Admin**: Full system access
- **Compliance Officer**: Case review and approval
- **KYC Analyst**: Case creation and management
- **Auditor**: Read-only audit access

## 📊 Monitoring and Observability

- **Tracing**: LangSmith integration for agent execution traces
- **Logging**: Structured JSON logs with correlation IDs
- **Metrics**: Custom CloudWatch metrics for agent performance
- **Dashboards**: Grafana dashboards for system health

## 🛡️ Security and Compliance

- Data encryption at rest (S3, RDS) and in transit (TLS 1.3)
- AWS KMS for key management
- PII anonymization in logs and traces
- 7-year data retention policy
- SOC 2 Type II aligned audit trails

## 📚 Documentation

- **API Documentation**: Auto-generated OpenAPI docs at `/docs`
- **Architecture**: See `specs/001-agentic-kyc-system/architecture-diagrams.md`
- **Data Model**: See `specs/001-agentic-kyc-system/data-model.md`
- **API Contracts**: See `specs/001-agentic-kyc-system/contracts/api.openapi.yaml`
- **Quickstart Guide**: See `specs/001-agentic-kyc-system/quickstart.md`

## 🤝 Contributing

1. Create a feature branch from `main`
2. Follow the spec-driven workflow in `.specify/`
3. Write tests for new features
4. Ensure all CI checks pass
5. Submit a pull request

## 📝 License

[Add your license here]

## 🆘 Support

For issues or questions:
- Check the [quickstart guide](specs/001-agentic-kyc-system/quickstart.md)
- Review [architectural diagrams](specs/001-agentic-kyc-system/architecture-diagrams.md)
- Open an issue in this repository

## 🚦 Project Status

**Current Phase**: Phase 1 - Project Setup ✅

- [x] Project structure and configuration
- [ ] Phase 2: Foundational Infrastructure
- [ ] Phase 3: User Story 1 (MVP)
- [ ] Phase 4: User Story 2 (EDD)
- [ ] Phase 5: User Story 3 (Approvals)
- [ ] Phase 6: User Story 4 (Monitoring)
- [ ] Phase 7: Polish and Documentation

---

Built with ❤️ using LangGraph, AWS Bedrock, and modern web technologies.
