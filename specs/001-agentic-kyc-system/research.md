# Research & Technical Decisions: Agentic KYC System

**Feature**: 001-agentic-kyc-system  
**Date**: 2025-11-12  
**Phase**: 0 (Research & Architecture)

## Executive Summary

This document consolidates architectural research and technical decisions for the AI-powered agentic KYC system. All technical context was pre-defined in the implementation plan input, requiring validation rather than discovery. Key decisions include AWS serverless architecture with LangChain/LangGraph agent orchestration, multi-database strategy (RDS Postgres + DynamoDB), React frontend with FastAPI backend, and comprehensive observability/audit infrastructure.

---

## 1. Agent Framework & Orchestration

### Decision: LangChain + LangGraph

**Chosen Solution**: LangChain for agent primitives and LangGraph for workflow state machines

**Rationale**:
- LangChain provides mature abstractions for LLM agents with tools, memory, and chains
- LangGraph extends LangChain with stateful workflow graphs, enabling complex multi-step KYC processes
- Native AWS Bedrock integration via LangChain's `BedrockChat` and `BedrockEmbeddings` classes
- Supports agentic patterns: ReAct (reasoning + acting), tool calling, self-reflection
- Strong community, active development, extensive documentation

**Implementation Approach**:
- Each agent (screening, risk scoring, SOW review, etc.) implemented as LangChain `Agent` with custom tools
- Workflow orchestration via LangGraph `StateGraph` defining transitions between agents
- State persistence in DynamoDB for long-running workflows (EDD processes spanning days)
- Structured output parsing with Pydantic models for type safety

**Alternatives Considered**:
- **Semantic Kernel**: Microsoft framework, good .NET integration but weaker Python ecosystem
- **AutoGen**: Multi-agent conversation framework, more research-oriented, less production-ready
- **Custom orchestration**: Full control but significant development overhead, reinventing patterns

---

## 2. LLM Provider & Model Selection

### Decision: AWS Bedrock (Anthropic Claude + Amazon Titan)

**Chosen Solution**: AWS Bedrock with Claude 3.5 Sonnet for reasoning tasks and Titan Embeddings for vector search

**Rationale**:
- **Compliance & Security**: Bedrock provides enterprise-grade security, no data retention for model training, AWS-native encryption/IAM integration
- **Claude 3.5 Sonnet**: Excellent for structured reasoning (risk assessment, SOW analysis), 200K context window for document analysis, strong tool use capabilities
- **Titan Embeddings**: Cost-effective embeddings for document similarity and RAG applications
- **Regional Availability**: Bedrock available in us-east-1, us-west-2 supporting multi-region deployment
- **Managed Service**: No infrastructure management, automatic model updates, pay-per-use pricing

**Use Cases by Model**:
- **Claude 3.5 Sonnet**: Risk scoring rationale generation, source of wealth narrative summarization, adverse media analysis, entity relationship interpretation
- **Claude 3 Haiku**: Simple classification tasks (document type identification), faster responses for low-complexity tasks
- **Titan Embeddings**: Document similarity matching, semantic search for prior cases, embedding client descriptions for duplicate detection

**Alternatives Considered**:
- **OpenAI GPT-4**: Strong reasoning but data privacy concerns for financial services, no AWS-native integration
- **Self-hosted LLMs (Llama, Mistral)**: Full control but significant operational overhead, GPU infrastructure management, model versioning complexity
- **Azure OpenAI**: Similar capabilities to Bedrock but would require multi-cloud strategy

---

## 3. Database Architecture

### Decision: Multi-Database Strategy (RDS Postgres + DynamoDB + S3)

**Chosen Solution**: 
- Amazon RDS Postgres (Multi-AZ) for relational data
- Amazon DynamoDB for agent session state and embeddings
- Amazon S3 for document storage and audit snapshots

**Rationale**:

**RDS Postgres** (Primary relational store):
- **Transactional Integrity**: ACID guarantees for critical KYC data (cases, clients, approvals)
- **Complex Queries**: SQL joins for relationship graphs, audit trail queries, reporting
- **Data Relationships**: Foreign keys enforce referential integrity (case → documents → screening results)
- **Audit Compliance**: Proven audit capabilities, immutable snapshot via PostgreSQL serializable transactions
- **Multi-AZ**: High availability with automatic failover, read replicas for analytics workloads

**DynamoDB** (Agent state + embeddings):
- **High Throughput**: Low-latency reads/writes for agent session state (workflow checkpoints)
- **Schemaless**: Flexible structure for diverse agent execution contexts (each agent type has different state)
- **Scalability**: On-demand capacity auto-scales with workload, supports 1,000+ concurrent workflows
- **Point-in-Time Recovery**: Built-in backup for compliance
- **Vector Storage**: Store embeddings with case metadata for similarity search (using DynamoDB as lightweight vector DB)

**S3** (Document + snapshot storage):
- **Object Storage**: Optimized for large binary files (PDFs, images)
- **Versioning**: Built-in object versioning for document history
- **Encryption**: Server-side encryption with KMS, immutable with Object Lock for audit snapshots
- **Lifecycle Policies**: Automated transition to Glacier for long-term retention (7-year compliance)
- **Cost-Effective**: Pay only for storage used, minimal operational overhead

**Data Distribution**:
- **Postgres**: Cases, Clients, Documents (metadata), RelatedParties, ScreeningResults, RiskAssessments, AuditEvents
- **DynamoDB**: AgentSessions (workflow state), EmbeddingsStore (vector representations)
- **S3**: Document files (PDFs, images), ApprovalSnapshots (immutable JSON), audit exports

**Alternatives Considered**:
- **Single Postgres for everything**: Simpler but poor performance for agent state (high write contention), embeddings awkward in relational schema
- **MongoDB**: Document model fits agent state but weaker transactional guarantees, not AWS-native
- **Aurora Serverless**: Auto-scaling Postgres but higher cost, overkill for predictable workload

---

## 4. API Architecture & Communication Patterns

### Decision: REST API (FastAPI) + WebSocket for Real-Time Updates

**Chosen Solution**:
- FastAPI REST API for CRUD operations and agent invocations
- WebSocket connections for live case status updates
- AWS API Gateway (HTTP API) for REST, WebSocket API for real-time

**Rationale**:

**FastAPI (Python)**:
- **Performance**: Async/await support, comparable to Node.js performance
- **Type Safety**: Pydantic models for request/response validation, automatic OpenAPI generation
- **Developer Experience**: Auto-generated interactive docs (Swagger UI), excellent error messages
- **Ecosystem Fit**: Native Python integration with LangChain, boto3, SQLAlchemy
- **Lambda Compatible**: Works in AWS Lambda with Mangum adapter

**REST for CRUD**:
- Standard HTTP verbs (GET, POST, PUT, DELETE) for case operations
- Idempotent operations, stateless requests
- Easy to cache (CloudFront caching for read-heavy endpoints)
- Well-understood patterns, broad client support

**WebSocket for Real-Time**:
- Live updates for case status changes (OPEN → UNDER_REVIEW), document processing progress, risk score updates
- Bidirectional communication for interactive workflows (officer requests additional info → agent responds)
- Lower latency than polling (sub-second updates vs. 5-10s poll intervals)
- API Gateway WebSocket API with Lambda integrations for connection management

**Alternatives Considered**:
- **GraphQL**: Flexible queries but adds complexity, over-fetching rarely an issue for KYC workflows
- **gRPC**: Better performance for microservice communication but poor browser support, unnecessary for frontend-backend communication
- **Server-Sent Events (SSE)**: Simpler than WebSocket but unidirectional, doesn't support interactive workflows

---

## 5. Frontend Architecture

### Decision: React + TypeScript SPA with S3 + CloudFront Hosting

**Chosen Solution**:
- React 18 with TypeScript
- TanStack Query (React Query) for server state management
- D3.js for relationship graph visualization
- S3 + CloudFront for static hosting

**Rationale**:

**React + TypeScript**:
- **Type Safety**: TypeScript prevents runtime errors, improves IDE support
- **Component Reusability**: Case list, detail, document upload as reusable components
- **Ecosystem**: Mature ecosystem (React Router, React Query, testing libraries)
- **Developer Velocity**: Fast iteration, hot module replacement

**TanStack Query**:
- **Server State Management**: Automatic caching, refetching, optimistic updates
- **Stale-While-Revalidate**: Display cached data instantly, refresh in background
- **Mutation Handling**: Simplifies POST/PUT operations with automatic cache invalidation
- **WebSocket Integration**: Works alongside WebSocket for real-time updates

**D3.js for Graphs**:
- **Relationship Visualization**: Force-directed graphs for entity ownership structures
- **Interactivity**: Zoom, pan, node expansion for exploring complex relationships
- **Customization**: Full control over graph layout, styling, animations

**S3 + CloudFront**:
- **Scalability**: CDN serves static assets globally, handles traffic spikes
- **Cost-Effective**: No server management, pay only for storage + bandwidth
- **Security**: CloudFront supports TLS, origin access identity (OAI) restricts direct S3 access
- **Deployment**: Simple CI/CD (build → sync to S3 → invalidate CloudFront cache)

**Alternatives Considered**:
- **Vue.js**: Similar capabilities but smaller ecosystem, team familiarity with React
- **Angular**: More opinionated, steeper learning curve, heavier framework
- **Server-Side Rendering (Next.js)**: Adds complexity, not necessary for internal compliance tool (no SEO requirements)

---

## 6. Infrastructure as Code

### Decision: AWS CDK (TypeScript)

**Chosen Solution**: AWS CDK with TypeScript for all infrastructure definitions

**Rationale**:
- **Type Safety**: TypeScript provides compile-time validation, IDE autocomplete
- **Abstraction**: Higher-level constructs vs. raw CloudFormation (e.g., `ApplicationLoadBalancedFargateService` vs. 10+ CFN resources)
- **Modularity**: Reusable constructs (e.g., `SecureS3Bucket` with encryption + versioning), stack composition
- **Testing**: CDK supports snapshot tests, assertion tests for infrastructure
- **AWS Native**: First-class AWS support, immediate access to new services
- **Consistency**: Same language (TypeScript) as frontend reduces context switching

**Stack Organization**:
- **VPC Stack**: Networking (VPC, subnets, NAT gateways, VPC endpoints)
- **RDS Stack**: PostgreSQL cluster, security groups, parameter groups
- **DynamoDB Stack**: Tables for agent sessions and embeddings
- **S3 Stack**: Buckets for documents and audit snapshots with lifecycle policies
- **Lambda Stack**: API Lambda functions, layers for shared dependencies
- **Fargate Stack**: Long-running agent tasks (EDD enrichment, batch processing)
- **Step Functions Stack**: Workflow state machines
- **API Gateway Stack**: REST + WebSocket APIs
- **Frontend Stack**: S3 bucket, CloudFront distribution, certificate
- **Monitoring Stack**: CloudWatch dashboards, alarms, log groups

**Deployment Stages**:
- **Dev**: Single-AZ RDS, minimal resources, no CloudFront caching
- **Staging**: Multi-AZ RDS, full resources, mirrors production
- **Prod**: Multi-AZ, read replicas, aggressive caching, alarming

**Alternatives Considered**:
- **Terraform**: Multi-cloud flexibility but inferior AWS support (CDK has L2/L3 constructs, Terraform is L1-equivalent)
- **Serverless Framework**: Good for Lambda but weak for other AWS services, YAML configuration less type-safe
- **Pulumi**: Similar to CDK but smaller community, less mature AWS support

---

## 7. Observability & Monitoring

### Decision: CloudWatch Logs/Metrics + X-Ray + Prometheus/Grafana

**Chosen Solution**:
- CloudWatch Logs for centralized logging
- CloudWatch Metrics for standard metrics (Lambda duration, API latency)
- AWS X-Ray for distributed tracing
- Prometheus + Grafana on Fargate for custom metrics and dashboards

**Rationale**:

**CloudWatch Logs**:
- **Native Integration**: Automatic Lambda logging, API Gateway logs, RDS logs
- **Structured Logging**: JSON log format with consistent schema (timestamp, level, service, trace_id)
- **Insights Queries**: SQL-like queries for log analysis (e.g., "find all HIGH risk cases in last 24h")
- **Retention**: Configurable retention (7 years for audit logs, 30 days for debug logs)

**AWS X-Ray**:
- **Distributed Tracing**: Track request through API Gateway → Lambda → Bedrock → RDS
- **Service Map**: Visualize dependencies, identify bottlenecks
- **Annotations**: Custom metadata (case_id, risk_level) for filtering traces
- **SDK Integration**: Python X-Ray SDK instruments SQLAlchemy, boto3, requests automatically

**CloudWatch Metrics**:
- **Standard Metrics**: Lambda invocations, errors, duration; API Gateway 4xx/5xx; RDS connections
- **Custom Metrics**: Agent execution time, risk score distribution, screening API success rate
- **Alarms**: SNS notifications for SLA violations (API latency >2s, error rate >5%)

**Prometheus + Grafana (on Fargate)**:
- **Advanced Dashboards**: Custom visualizations (case pipeline funnel, team workload heatmap)
- **Alertmanager**: Sophisticated alert routing (escalation policies, on-call rotation)
- **Exporters**: Scrape metrics from application endpoints (/metrics), RDS exporter for database stats
- **Long-Term Storage**: Prometheus for 30-day retention, export to S3 for long-term analysis

**Alternatives Considered**:
- **CloudWatch only**: Sufficient for basic monitoring but limited dashboard customization, expensive for high-cardinality metrics
- **Datadog/New Relic**: Powerful but adds significant cost (~$15-30/host/month), vendor lock-in
- **ELK Stack**: Flexible but high operational overhead (Elasticsearch cluster management), overkill for logging use case

---

## 8. Authentication & Authorization

### Decision: Username/Password with JWT + RBAC

**Chosen Solution**:
- Username/password authentication with bcrypt hashing
- JWT tokens for session management
- Role-based access control (RBAC) with 4 roles: Case Officer, Senior Officer, Manager, Administrator

**Rationale**:

**Username/Password**:
- **Simplicity**: No external IdP integration, faster initial implementation
- **Control**: Full control over user lifecycle, password policies
- **Security**: bcrypt with cost factor 12, password complexity rules (12+ chars, upper/lower/digit/special)
- **Future-Proof**: Can migrate to SSO later without frontend changes (API contract stays same)

**JWT Tokens**:
- **Stateless**: No server-side session storage, scales horizontally
- **Claims**: Embed user ID, roles, expiration in token
- **Refresh Tokens**: Long-lived refresh token (7 days) + short-lived access token (1 hour)
- **Revocation**: Maintain token blacklist in DynamoDB for emergency revocation

**RBAC Roles**:
- **Case Officer**: Create cases, upload documents, view assigned cases, request EDD
- **Senior Officer**: All Case Officer permissions + approve/reject cases, override risk scores
- **Manager**: Read-only access to all cases, view team workload, access reports
- **Administrator**: All permissions + user management, system configuration

**Alternatives Considered**:
- **AWS Cognito**: Managed authentication but adds external dependency, overkill for initial MVP, harder to customize
- **SAML/OIDC SSO**: Better for large enterprises but requires IdP integration, more complex, deferred to post-MVP

---

## 9. CI/CD Pipeline

### Decision: GitHub Actions with Multi-Stage Deployment

**Chosen Solution**:
- GitHub Actions for CI/CD automation
- Trunk-based development with feature branches
- Deployment stages: dev → staging → prod with approval gates

**Pipeline Workflow**:

**CI (on every PR)**:
1. **Lint**: `black`, `isort`, `flake8` (Python), `eslint`, `prettier` (TypeScript)
2. **Test**: 
   - Backend: `pytest` with coverage report
   - Frontend: `jest` + `react-testing-library`
   - Contract: `schemathesis` validates OpenAPI spec
3. **Build**: 
   - Backend: Package Lambda deployment zips, build Docker images for Fargate
   - Frontend: `npm run build`, optimize bundle size
4. **Security Scan**: 
   - `safety` (Python deps), `npm audit` (JS deps)
   - `bandit` (Python SAST), `semgrep` (multi-language SAST)

**CD (on merge to main)**:
1. **Deploy Dev**: 
   - `cdk deploy DevStack --require-approval never`
   - Run smoke tests (health check endpoints, sample case creation)
2. **Deploy Staging** (manual trigger):
   - `cdk deploy StagingStack --require-approval never`
   - Run integration tests (full case workflow, screening API mocks)
3. **Deploy Prod** (manual approval required):
   - `cdk deploy ProdStack --require-approval never`
   - Blue-green deployment using Lambda aliases
   - Post-deployment verification (synthetic monitoring)

**Deployment Strategy**:
- **Lambda**: Blue-green with aliases (10% → 50% → 100% traffic shift over 30 min)
- **Fargate**: Rolling update with health checks
- **Frontend**: Atomic deployment (S3 sync + CloudFront invalidation)
- **Database**: Alembic migrations run automatically in init containers

**Alternatives Considered**:
- **AWS CodePipeline**: AWS-native but GitHub Actions more flexible, better community, easier local testing
- **Jenkins**: Self-hosted flexibility but operational overhead, less cloud-native
- **GitLab CI**: Similar to GitHub Actions but would require repo migration

---

## 10. Testing Strategy

### Decision: TDD with Multi-Layer Testing (Unit → Contract → Integration → E2E)

**Testing Pyramid**:

**Unit Tests (70% of tests)**:
- **Scope**: Individual functions, classes, business logic
- **Backend**: pytest for service layer, agent logic, data transformations
- **Frontend**: Jest + RTL for components, hooks, utilities
- **Coverage Target**: 80% line coverage for backend critical paths, 70% for frontend
- **Speed**: Fast (<1ms per test), run on every file save

**Contract Tests (15% of tests)**:
- **Scope**: API endpoint contracts match OpenAPI specification
- **Tool**: `schemathesis` generates test cases from OpenAPI schema
- **Coverage**: Every endpoint (request/response validation), every status code
- **CI Integration**: Run on every PR to catch breaking changes

**Integration Tests (10% of tests)**:
- **Scope**: End-to-end user workflows across services
- **Setup**: Testcontainers for Postgres, localstack for AWS services (S3, DynamoDB)
- **Examples**: 
  - Case intake → document upload → screening → risk score → approval
  - EDD workflow with corporate registry enrichment
  - Human override triggering dependent agent re-runs
- **Speed**: Slower (5-30s per test), run in CI only

**E2E Tests (5% of tests)**:
- **Scope**: Full system with real UI interactions
- **Tool**: Playwright with TypeScript
- **Environment**: Staging environment with test data fixtures
- **Examples**:
  - Officer creates case, uploads passport, reviews risk score in UI
  - Senior officer overrides risk, approves case, verifies audit trail
- **Speed**: Slowest (1-5min per test), run nightly or pre-production

**TDD Workflow**:
1. Write failing test for new feature (e.g., `test_risk_scoring_for_high_risk_jurisdiction`)
2. Implement minimal code to pass test
3. Refactor for quality (maintain passing tests)
4. Commit with test + implementation together

**Mocking Strategy**:
- **External APIs**: Mock screening APIs (sanctions, PEP) in unit/integration tests, use real APIs in staging E2E
- **Bedrock LLM**: Record real LLM responses with `pytest-vcr`, replay in tests (deterministic, fast)
- **Database**: Real Postgres in integration tests (testcontainers), SQLite in-memory for unit tests

**Alternatives Considered**:
- **BDD (Cucumber)**: Good for stakeholder collaboration but adds overhead, plain pytest sufficient for internal tool
- **Property-Based Testing (Hypothesis)**: Valuable for data validation but overkill for initial MVP, add later for hardening

---

## 11. Document Processing Pipeline

### Decision: S3 Trigger → Lambda → Textract/Bedrock → Store Metadata

**Chosen Solution**:
- S3 event notification triggers Lambda on document upload
- AWS Textract for OCR (printed text extraction)
- AWS Bedrock for document classification and entity extraction
- Extracted text and metadata stored in Postgres `Documents` table

**Pipeline Stages**:
1. **Upload**: Frontend uploads file to S3 pre-signed URL, triggers S3 event
2. **OCR**: Lambda invokes Textract `DetectDocumentText` (synchronous for <100 pages)
3. **Classification**: Bedrock Claude classifies document type (passport, bank statement, etc.)
4. **Extraction**: Structured extraction (name, DOB from passport; transaction amounts from bank statement)
5. **Storage**: Text content, confidence scores, extracted entities saved to `Documents` table
6. **Notification**: WebSocket event sent to frontend (document processed, display extracted data)

**Document Types & Extraction**:
- **Passport**: Name, DOB, nationality, passport number, expiration date
- **Driver License**: Similar to passport
- **Utility Bill**: Address, date, account holder name
- **Bank Statement**: Account number, transaction history, balance
- **Corporate Documents**: Entity name, registration number, directors

**Textract vs. Custom OCR**:
- **Textract**: Managed service, handles tables/forms, 99%+ accuracy for printed text
- **Tesseract (open-source)**: Would require Lambda with custom runtime, lower accuracy, more maintenance

**Large Document Handling**:
- **Async Processing**: Documents >100 pages use Textract asynchronous API (submit job → poll for completion)
- **Fargate Task**: Long-running extraction (large PDFs with hundreds of pages) runs in Fargate instead of Lambda
- **Progress Updates**: WebSocket sends progress (10% → 50% → 100%) for better UX

**Alternatives Considered**:
- **Google Document AI**: Comparable to Textract but multi-cloud dependency, data residency concerns
- **Custom ML Model**: Full control but requires training data, model hosting, ongoing maintenance
- **Manual Entry**: Defeats automation purpose, falls back only for corrupted/unsupported documents

---

## 12. Screening API Integration

### Decision: Third-Party Screening APIs with Circuit Breaker Pattern

**Chosen Solution**:
- Integrate third-party screening APIs (Dow Jones, World-Check, or equivalents) for sanctions, PEP, adverse media
- Circuit breaker pattern with exponential backoff for API failures
- Cache screening results for 24 hours (reduce redundant API calls for same entity)

**Integration Architecture**:
- **ScreeningAgent** invokes external APIs via HTTP clients (using `requests` with retry logic)
- **Circuit Breaker**: Open (fail fast) after 5 consecutive failures, half-open (test) after 60s, close (normal) on success
- **Fallback**: Queue screening request to SQS, retry later if API unavailable
- **Caching**: DynamoDB cache with 24-hour TTL (key: entity name + DOB + nationality)

**API Providers (examples)**:
- **Dow Jones Risk & Compliance**: Sanctions, PEP, adverse media, watchlists
- **Refinitiv World-Check**: Global screening database
- **ComplyAdvantage**: Real-time risk data, adverse media monitoring

**Rationale for Circuit Breaker**:
- **Resilience**: System degrades gracefully when external APIs fail (don't block case intake)
- **Cost Control**: Avoid hammering failing APIs (reduce wasted API call costs)
- **User Experience**: Provide immediate feedback ("Screening pending") vs. hanging requests

**Alternatives Considered**:
- **Build In-House Screening**: Massive undertaking (curate sanctions lists, media scraping), not differentiating capability
- **Bulk Import Lists**: Static lists (OFAC, UN) but miss PEP and adverse media, no real-time updates

---

## 13. Relationship Graph Storage & Visualization

### Decision: Postgres Adjacency List + D3.js Force-Directed Graph

**Chosen Solution**:
- Store entity relationships in Postgres `EntityRelationship` table (adjacency list: source_id, target_id, relationship_type, ownership_percentage)
- Recursive SQL queries (CTEs) to traverse ownership chains
- Export graph as JSON to frontend
- D3.js force-directed layout for visualization

**Schema Design**:
```sql
CREATE TABLE entity_relationships (
  id UUID PRIMARY KEY,
  source_client_id UUID REFERENCES clients(id),
  target_client_id UUID REFERENCES clients(id),
  relationship_type VARCHAR(50), -- 'ownership', 'control', 'family'
  ownership_percentage DECIMAL(5,2),
  confidence_score DECIMAL(3,2),
  evidence_documents UUID[],
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Graph Queries**:
- **Find Ultimate Beneficial Owners**: Recursive CTE traverses ownership chain until no further parents
- **Circular Ownership Detection**: Detect cycles using CTE with visited node tracking
- **Relationship Path**: Find shortest path between two entities (breadth-first search in SQL)

**Frontend Visualization**:
- **D3.js Force Simulation**: Nodes repel, links attract (organic layout)
- **Interactions**: Click node to expand (load related entities), hover for details tooltip
- **Styling**: Color by entity type (individual blue, company green), size by ownership %

**Alternatives Considered**:
- **Neo4j (Graph Database)**: Optimal for complex graph traversal but adds operational complexity (new database to manage), overkill for relatively small graphs (dozens of entities per case)
- **DynamoDB Adjacency List**: Cheaper but weaker query capabilities (no recursive queries), would need to traverse in application code

---

## 14. Agent Memory & Context Management

### Decision: DynamoDB for Short-Term Agent State + Postgres for Long-Term History

**Chosen Solution**:
- **Short-Term (Active Workflow)**: DynamoDB `AgentSessions` table stores current workflow state, in-progress analysis, conversation history
- **Long-Term (Audit Trail)**: Postgres `AgentInvocations` table stores completed agent executions, inputs/outputs, provenance

**DynamoDB Schema**:
```json
{
  "session_id": "uuid",  // Partition key
  "agent_type": "risk_scoring",
  "case_id": "uuid",
  "state": {
    "current_step": "enrichment",
    "collected_data": {...},
    "intermediate_results": {...}
  },
  "conversation_history": [...],
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "ttl": "timestamp"  // Auto-delete after 30 days
}
```

**Postgres Schema**:
```sql
CREATE TABLE agent_invocations (
  id UUID PRIMARY KEY,
  case_id UUID REFERENCES cases(id),
  agent_type VARCHAR(50),
  input_parameters JSONB,
  output_results JSONB,
  confidence_score DECIMAL(3,2),
  model_identifier VARCHAR(100),
  provenance_sources JSONB,
  execution_duration_ms INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Why Dual Storage**:
- **DynamoDB**: Fast writes for frequent state updates during workflow execution, auto-scaling, TTL for cleanup
- **Postgres**: Relational integrity for audit queries (JOIN cases, clients, documents), complex analytics, long-term retention

**Context Window Management**:
- **Conversation Summarization**: After 20 messages, summarize older messages to fit in Claude's 200K context
- **Relevant Context Retrieval**: Use embeddings to retrieve most relevant prior case details (similar clients, past decisions)

**Alternatives Considered**:
- **Redis for Agent State**: Faster than DynamoDB but requires cluster management, higher cost, less durable
- **Postgres for Everything**: Single database simpler but poor performance for high-write agent state

---

## 15. Error Handling & Retries

### Decision: Exponential Backoff with Dead Letter Queues

**Chosen Solution**:
- Exponential backoff for transient failures (API rate limits, network timeouts)
- Dead Letter Queues (DLQ) for unrecoverable errors
- CloudWatch alarms on DLQ depth

**Retry Logic**:
- **API Calls**: 3 retries with exponential backoff (1s, 2s, 4s), then DLQ
- **Lambda Invocations**: Built-in retry (2 attempts), then SQS DLQ
- **Step Functions**: Retry state with backoff, catch errors, transition to error handling state

**Error Categories**:
- **Transient**: Retry (rate limit, timeout, 503)
- **Client Error**: No retry (400, 401, 422 validation error), alert user
- **Unrecoverable**: Send to DLQ (malformed data, unsupported document type), manual intervention

**Monitoring**:
- **CloudWatch Alarms**: DLQ depth >5 messages, send SNS to on-call
- **Dashboard**: Error rate by service, error type distribution
- **PagerDuty Integration**: Critical errors (database unavailable, Bedrock quota exceeded) page on-call engineer

**Alternatives Considered**:
- **No Retries**: Fail fast, simpler but poor resilience
- **Infinite Retries**: Would hide underlying issues, waste resources

---

## Summary of Key Technologies

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Agent Framework** | LangChain + LangGraph | Mature agentic AI patterns, AWS Bedrock integration |
| **LLM** | AWS Bedrock (Claude 3.5 Sonnet) | Compliance, security, structured reasoning |
| **Backend API** | FastAPI (Python 3.11) | Performance, type safety, async support |
| **Frontend** | React + TypeScript | Type safety, ecosystem, developer velocity |
| **Database (Relational)** | RDS Postgres (Multi-AZ) | ACID, complex queries, audit compliance |
| **Database (NoSQL)** | DynamoDB | Agent state, high throughput, auto-scaling |
| **Document Storage** | S3 (versioned, encrypted) | Object storage, immutable snapshots |
| **Workflow Orchestration** | AWS Step Functions | Managed state machines, visual workflows |
| **Infrastructure** | AWS CDK (TypeScript) | Type safety, modularity, testing |
| **CI/CD** | GitHub Actions | Flexibility, community, cloud-native |
| **Observability** | CloudWatch + X-Ray + Prometheus/Grafana | Logging, tracing, custom metrics |
| **Authentication** | Username/Password + JWT | Simplicity, control, future SSO migration |
| **Document Processing** | AWS Textract | Managed OCR, high accuracy |
| **Screening** | Third-Party APIs (Dow Jones, World-Check) | Real-time data, PEP, adverse media |
| **Graph Visualization** | D3.js | Force-directed layout, interactivity |

---

## Risk Mitigation Strategies

### Technical Risks

1. **Bedrock Rate Limits**: 
   - **Risk**: High concurrency exceeds Bedrock quotas
   - **Mitigation**: Request quota increase, queue LLM calls, use Haiku for low-priority tasks

2. **Screening API Availability**:
   - **Risk**: External APIs fail, block case processing
   - **Mitigation**: Circuit breaker, queue + retry, cache results

3. **RDS Connection Pool Exhaustion**:
   - **Risk**: Too many Lambda connections overwhelm Postgres
   - **Mitigation**: RDS Proxy (connection pooling), limit Lambda concurrency

4. **WebSocket Connection Limits**:
   - **Risk**: API Gateway WebSocket limits (10K concurrent connections)
   - **Mitigation**: Monitor connection count, graceful fallback to polling

### Compliance Risks

1. **Audit Log Tampering**:
   - **Risk**: Malicious actor modifies audit trail
   - **Mitigation**: Immutable S3 snapshots with Object Lock, cryptographic hashing

2. **PII Exposure in Logs**:
   - **Risk**: Personally identifiable information logged
   - **Mitigation**: Log scrubbing middleware, automated PII detection

3. **Data Retention Violations**:
   - **Risk**: Data retained longer/shorter than required
   - **Mitigation**: Automated lifecycle policies, quarterly compliance audit

---

## Next Steps (Phase 1: Design)

1. **Data Model Definition** (data-model.md):
   - Full Postgres schema with indexes, constraints
   - DynamoDB table designs with access patterns
   - Entity relationship diagrams

2. **API Contract Definition** (contracts/api.openapi.yaml):
   - OpenAPI 3.0 specification for all REST endpoints
   - Request/response schemas, error codes
   - Authentication/authorization requirements

3. **Quickstart Guide** (quickstart.md):
   - Local development setup (Docker Compose for Postgres, localstack)
   - Running tests, deploying to dev environment
   - Common workflows (create case, upload document, approve)

4. **Agent Context Update**:
   - Run `.specify/scripts/bash/update-agent-context.sh copilot`
   - Add technology choices to agent-specific context file

---

## Appendix: Useful References

- **LangChain Docs**: https://python.langchain.com/docs/
- **LangGraph Guide**: https://langchain-ai.github.io/langgraph/
- **AWS Bedrock**: https://docs.aws.amazon.com/bedrock/
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **AWS CDK Docs**: https://docs.aws.amazon.com/cdk/
- **Textract**: https://docs.aws.amazon.com/textract/
- **Step Functions**: https://docs.aws.amazon.com/step-functions/
- **D3.js Force Layout**: https://d3js.org/d3-force
