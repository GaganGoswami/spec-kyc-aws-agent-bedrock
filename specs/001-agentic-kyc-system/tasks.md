# Tasks: Agentic KYC System

**Feature**: 001-agentic-kyc-system  
**Date**: 2025-11-12  
**Input**: Design documents from `/specs/001-agentic-kyc-system/`

## Task Format: `- [ ] [TaskID] [P?] [Story?] Description`

- **[P]**: Parallelizable (different files, no blocking dependencies)
- **[Story]**: User story label (US1, US2, US3, US4)
- All tasks include specific file paths

---

## Phase 1: Project Setup & Infrastructure Initialization

**Purpose**: Create project structure, configure tooling, and establish development environment

- [ ] T001 Create project directory structure per plan.md (backend/, frontend/, infra/, scripts/, .github/)
- [ ] T002 Initialize backend Python project with Poetry in backend/pyproject.toml
- [ ] T003 [P] Initialize frontend Node.js project with package.json in frontend/
- [ ] T004 [P] Initialize infrastructure CDK project with tsconfig.json in infra/
- [ ] T005 [P] Configure Python linting and formatting (black, isort, flake8, mypy) in backend/.flake8, backend/pyproject.toml
- [ ] T006 [P] Configure TypeScript linting and formatting (eslint, prettier) in frontend/.eslintrc.js, frontend/.prettierrc
- [ ] T007 [P] Setup pre-commit hooks with .pre-commit-config.yaml for linting automation
- [ ] T008 Create Docker Compose configuration in docker-compose.yml for Postgres, LocalStack, Redis
- [ ] T009 Create LocalStack initialization script in scripts/localstack-init.sh for S3, DynamoDB setup
- [ ] T010 [P] Setup GitHub Actions CI workflow in .github/workflows/ci.yml (lint, test, build)
- [ ] T011 [P] Create environment templates (.env.example for backend, .env.example for frontend)

**Checkpoint**: Project structure established, all tooling configured, ready for foundational development

---

## Phase 2: Foundational Infrastructure (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database & Core Models

- [ ] T012 Setup Alembic migrations framework in backend/alembic/ with env.py, alembic.ini
- [ ] T013 Create database connection manager in backend/src/core/database.py with SQLAlchemy engine, session factory
- [ ] T014 [P] Create base SQLAlchemy model class in backend/src/models/base.py with UUID primary key, timestamps
- [ ] T015 Create Roles model in backend/src/models/role.py with permissions JSONB field
- [ ] T016 Create Users model in backend/src/models/user.py with password_hash, role_id foreign key
- [ ] T017 Create initial migration for Users and Roles tables with alembic revision
- [ ] T018 Create seed script in scripts/seed-test-data.py to populate 4 roles (case_officer, senior_officer, manager, administrator)

### Authentication & Authorization

- [ ] T019 Implement password hashing utilities in backend/src/core/security.py using bcrypt
- [ ] T020 Implement JWT token generation and validation in backend/src/core/auth.py with access/refresh tokens
- [ ] T021 Create authentication dependencies in backend/src/api/dependencies.py for FastAPI (get_current_user, require_role)
- [ ] T022 Create Pydantic schemas for auth in backend/src/schemas/auth.py (LoginRequest, TokenResponse, UserResponse)
- [ ] T023 Implement authentication endpoints in backend/src/api/v1/auth.py (POST /auth/login, POST /auth/refresh, POST /auth/logout)

### API Foundation

- [ ] T024 Create FastAPI application instance in backend/src/main.py with CORS, middleware, exception handlers
- [ ] T025 Setup structured logging in backend/src/utils/logging.py with JSON formatter, context injection
- [ ] T026 Create error response schemas in backend/src/schemas/error.py (ErrorResponse, ValidationError)
- [ ] T027 Implement global exception handlers in backend/src/api/middleware/error_handler.py
- [ ] T028 Setup AWS X-Ray tracing middleware in backend/src/api/middleware/tracing.py
- [ ] T029 Create base service class in backend/src/services/base.py with database session management

### AWS Infrastructure (CDK)

- [ ] T030 Create VPC stack in infra/lib/stacks/vpc-stack.ts with public/private subnets, NAT gateways
- [ ] T031 [P] Create RDS stack in infra/lib/stacks/rds-stack.ts with Postgres multi-AZ, security groups
- [ ] T032 [P] Create DynamoDB stack in infra/lib/stacks/dynamodb-stack.ts with AgentSessions and EmbeddingsStore tables
- [ ] T033 [P] Create S3 stack in infra/lib/stacks/s3-stack.ts with documents and audit-snapshots buckets, versioning enabled
- [ ] T034 Create Secrets Manager secrets in infra/lib/stacks/secrets-stack.ts for database credentials, JWT secret
- [ ] T035 Setup API Gateway in infra/lib/stacks/api-gateway-stack.ts with HTTP API and WebSocket API
- [ ] T036 Create CDK app entry point in infra/bin/app.ts with dev, staging, prod environments

### Frontend Foundation

- [ ] T037 Create React app structure in frontend/src/ with App.tsx, index.tsx
- [ ] T038 Setup React Router in frontend/src/App.tsx with route definitions
- [ ] T039 Setup TanStack Query in frontend/src/index.tsx with QueryClient, QueryClientProvider
- [ ] T040 [P] Create API client in frontend/src/services/api.ts with axios, interceptors for JWT
- [ ] T041 [P] Create WebSocket manager in frontend/src/services/websocket.ts with reconnection logic
- [ ] T042 Create authentication context in frontend/src/contexts/AuthContext.tsx with login, logout, token refresh
- [ ] T043 Create custom hook useAuth in frontend/src/hooks/useAuth.ts
- [ ] T044 [P] Create TypeScript types for API models in frontend/src/types/api.ts
- [ ] T045 Create Login page in frontend/src/pages/Login.tsx with form validation

### Testing Infrastructure

- [ ] T046 Setup pytest configuration in backend/pytest.ini with test discovery, coverage settings
- [ ] T047 [P] Setup Jest configuration in frontend/jest.config.js with React Testing Library
- [ ] T048 Create test database utilities in backend/tests/conftest.py with fixtures for database, test client
- [ ] T049 Create test data factories in backend/tests/factories/ using factory_boy for models
- [ ] T050 [P] Setup Playwright configuration in frontend/tests/e2e/playwright.config.ts

**Checkpoint**: Foundation complete - all core infrastructure ready for user story implementation

---

## Phase 3: User Story 1 - Client Intake and Basic Risk Assessment (Priority: P1) 🎯 MVP

**Goal**: Compliance officer creates KYC case, captures client data, uploads documents, receives risk assessment with screening results

**Independent Test**: Create new case, enter client data, upload passport/utility bill, verify system returns risk score, screening results, case status

### Data Models for User Story 1

- [ ] T051 [P] [US1] Create Clients model in backend/src/models/client.py with individual/entity fields, PEP flags, nationality
- [ ] T052 [P] [US1] Create Cases model in backend/src/models/case.py with status, assigned_officer, priority, due_date
- [ ] T053 [P] [US1] Create Documents model in backend/src/models/document.py with s3_key, content_hash, extracted_text, document_type
- [ ] T054 [P] [US1] Create ScreeningResults model in backend/src/models/screening_result.py with screening_type, matches JSONB, review_status
- [ ] T055 [P] [US1] Create RiskAssessments model in backend/src/models/risk_assessment.py with risk_score, risk_level, risk_drivers JSONB, rationale_text
- [ ] T056 [P] [US1] Create AuditEvents model in backend/src/models/audit_event.py with event_type, actor_type, before_value/after_value JSONB
- [ ] T057 [US1] Create migration for User Story 1 models with alembic revision (depends on T051-T056)

### Pydantic Schemas for User Story 1

- [ ] T058 [P] [US1] Create client schemas in backend/src/schemas/client.py (ClientCreate, ClientResponse, ClientUpdate)
- [ ] T059 [P] [US1] Create case schemas in backend/src/schemas/case.py (CaseCreate, CaseResponse, CaseUpdate, CaseListItem)
- [ ] T060 [P] [US1] Create document schemas in backend/src/schemas/document.py (DocumentUpload, DocumentResponse, DocumentMetadata)
- [ ] T061 [P] [US1] Create screening schemas in backend/src/schemas/screening.py (ScreeningRequest, ScreeningResultResponse, ScreeningMatch)
- [ ] T062 [P] [US1] Create risk assessment schemas in backend/src/schemas/risk.py (RiskAssessmentResponse, RiskDriver)

### Services for User Story 1

- [ ] T063 [US1] Implement ClientService in backend/src/services/client_service.py with create, get, update, duplicate detection methods
- [ ] T064 [US1] Implement CaseService in backend/src/services/case_service.py with create, get, update_status, assign methods
- [ ] T065 [US1] Implement DocumentService in backend/src/services/document_service.py with upload, get, generate_presigned_url methods
- [ ] T066 [US1] Implement ScreeningService in backend/src/services/screening_service.py with execute_screening, parse_results methods
- [ ] T067 [US1] Implement RiskScoringService in backend/src/services/risk_service.py with compute_risk, classify_level methods
- [ ] T068 [US1] Implement AuditService in backend/src/services/audit_service.py with log_event, get_timeline methods

### AI Agents for User Story 1

- [ ] T069 [US1] Create base agent class in backend/src/agents/base_agent.py with LangChain Agent setup, logging, error handling
- [ ] T070 [P] [US1] Implement IntakeAgent in backend/src/agents/intake.py with client data validation, entity extraction
- [ ] T071 [P] [US1] Implement DocumentIngestAgent in backend/src/agents/document_ingest.py with Textract integration, entity extraction via Bedrock
- [ ] T072 [P] [US1] Implement ScreeningAgent in backend/src/agents/screening.py with external API calls, circuit breaker, result parsing
- [ ] T073 [P] [US1] Implement RiskScoringAgent in backend/src/agents/risk_scoring.py with Bedrock Claude prompt, feature engineering, score calculation
- [ ] T074 [US1] Create AgentInvocations model in backend/src/models/agent_invocation.py with input_parameters, output_results, provenance

### External Integrations for User Story 1

- [ ] T075 [P] [US1] Create Bedrock client wrapper in backend/src/integrations/bedrock.py with Claude/Titan model invocation, retry logic
- [ ] T076 [P] [US1] Create Textract client wrapper in backend/src/integrations/textract.py with OCR extraction, confidence parsing
- [ ] T077 [P] [US1] Create screening API client in backend/src/integrations/sanctions_api.py with Dow Jones/World-Check integration, circuit breaker
- [ ] T078 [US1] Create DynamoDB agent session manager in backend/src/integrations/agent_sessions.py with state persistence, TTL

### API Endpoints for User Story 1

- [ ] T079 [US1] Implement cases endpoints in backend/src/api/v1/cases.py (POST /cases, GET /cases, GET /cases/{id}, PATCH /cases/{id})
- [ ] T080 [US1] Implement clients endpoints in backend/src/api/v1/clients.py (POST /clients, GET /clients/{id}, PATCH /clients/{id})
- [ ] T081 [US1] Implement documents endpoints in backend/src/api/v1/documents.py (POST /cases/{id}/documents, GET /documents/{id}, GET /documents/{id}/download)
- [ ] T082 [US1] Implement screening endpoints in backend/src/api/v1/screening.py (POST /cases/{id}/screening, GET /screening-results/{id})
- [ ] T083 [US1] Implement risk assessment endpoints in backend/src/api/v1/risk.py (GET /cases/{id}/risk-assessment)

### Frontend Components for User Story 1

- [ ] T084 [P] [US1] Create Dashboard page in frontend/src/pages/Dashboard.tsx with case statistics, recent cases list
- [ ] T085 [P] [US1] Create CaseList page in frontend/src/pages/CaseList.tsx with filtering, sorting, pagination
- [ ] T086 [US1] Create CaseDetail page in frontend/src/pages/CaseDetail.tsx with tabs for client, documents, screening, risk
- [ ] T087 [P] [US1] Create CaseForm component in frontend/src/components/CaseForm/CaseForm.tsx with client data fields, validation
- [ ] T088 [P] [US1] Create DocumentUpload component in frontend/src/components/DocumentUpload/DocumentUpload.tsx with drag-drop, progress
- [ ] T089 [P] [US1] Create RiskBadge component in frontend/src/components/RiskBadge/RiskBadge.tsx with LOW/MEDIUM/HIGH styling
- [ ] T090 [P] [US1] Create ScreeningResults component in frontend/src/components/ScreeningResults/ScreeningResults.tsx with matches display
- [ ] T091 [P] [US1] Create AuditTimeline component in frontend/src/components/AuditTimeline/AuditTimeline.tsx with event history

### Frontend Hooks for User Story 1

- [ ] T092 [P] [US1] Create useCases hook in frontend/src/hooks/useCases.ts with TanStack Query (useQuery for list, useMutation for create)
- [ ] T093 [P] [US1] Create useDocuments hook in frontend/src/hooks/useDocuments.ts with upload mutation, presigned URL fetching
- [ ] T094 [P] [US1] Create useScreening hook in frontend/src/hooks/useScreening.ts with trigger screening mutation
- [ ] T095 [P] [US1] Create useRiskAssessment hook in frontend/src/hooks/useRiskAssessment.ts with fetch risk assessment query

### WebSocket Integration for User Story 1

- [ ] T096 [US1] Implement WebSocket connection handler in backend/src/api/websocket/connection.py with JWT validation, channel subscriptions
- [ ] T097 [US1] Implement WebSocket event publisher in backend/src/services/websocket_service.py with case.status_changed, document.processing_completed events
- [ ] T098 [US1] Create useWebSocket hook in frontend/src/hooks/useWebSocket.ts with auto-reconnection, event handlers
- [ ] T099 [US1] Integrate WebSocket events in CaseDetail page for real-time status updates

### Testing for User Story 1

- [ ] T100 [P] [US1] Create unit tests for CaseService in backend/tests/unit/services/test_case_service.py (create, update status, assign)
- [ ] T101 [P] [US1] Create unit tests for RiskScoringAgent in backend/tests/unit/agents/test_risk_scoring.py (score calculation, classification)
- [ ] T102 [P] [US1] Create contract tests for cases API in backend/tests/contract/test_cases_api.py using schemathesis
- [ ] T103 [US1] Create integration test for case intake workflow in backend/tests/integration/test_case_intake.py (create case → upload doc → screening → risk)
- [ ] T104 [P] [US1] Create component tests for CaseForm in frontend/tests/unit/CaseForm.test.tsx with React Testing Library
- [ ] T105 [US1] Create E2E test for case creation in frontend/tests/e2e/case-creation.spec.ts with Playwright

**Checkpoint**: User Story 1 complete - officers can create cases, upload documents, receive automated risk assessments

---

## Phase 4: User Story 2 - Enhanced Due Diligence and Source of Wealth Review (Priority: P2)

**Goal**: For medium/high-risk cases, officer requests EDD, system enriches data via registries, generates SOW review with AI analysis

**Independent Test**: Flag case for EDD, trigger enrichment and SOW analysis, verify corporate structure, beneficial owners, wealth source summary returned

### Data Models for User Story 2

- [ ] T106 [P] [US2] Create RelatedParties model in backend/src/models/related_party.py with relationship_type, ownership_percentage, confidence_score
- [ ] T107 [P] [US2] Create EntityRelationships model in backend/src/models/entity_relationship.py with source/target clients, relationship graph
- [ ] T108 [P] [US2] Create SourceOfWealthReviews model in backend/src/models/sow_review.py with claimed_sources, consistency_analysis, identified_gaps JSONB
- [ ] T109 [US2] Create migration for User Story 2 models with alembic revision (depends on T106-T108)

### Pydantic Schemas for User Story 2

- [ ] T110 [P] [US2] Create related party schemas in backend/src/schemas/related_party.py (RelatedPartyCreate, RelatedPartyResponse)
- [ ] T111 [P] [US2] Create entity relationship schemas in backend/src/schemas/relationship.py (RelationshipResponse, RelationshipGraph)
- [ ] T112 [P] [US2] Create SOW review schemas in backend/src/schemas/sow.py (SOWReviewResponse, SOWGap, SOWRecommendation)

### Services for User Story 2

- [ ] T113 [US2] Implement RelatedPartyService in backend/src/services/related_party_service.py with add, get, link_to_existing_client methods
- [ ] T114 [US2] Implement EntityResolutionService in backend/src/services/entity_resolution_service.py with fuzzy_match, resolve_identity methods
- [ ] T115 [US2] Implement EnrichmentService in backend/src/services/enrichment_service.py with fetch_corporate_data, extract_beneficial_owners methods
- [ ] T116 [US2] Implement SOWReviewService in backend/src/services/sow_service.py with analyze_consistency, identify_gaps, generate_recommendations methods

### AI Agents for User Story 2

- [ ] T117 [P] [US2] Implement EntityResolutionAgent in backend/src/agents/entity_resolution.py with fuzzy matching, registry lookup
- [ ] T118 [P] [US2] Implement EnrichmentAgent in backend/src/agents/enrichment.py with corporate registry API integration, UBO extraction
- [ ] T119 [P] [US2] Implement SOWReviewAgent in backend/src/agents/sow_review.py with Bedrock Claude prompt for consistency analysis
- [ ] T120 [US2] Implement WorkflowAgent in backend/src/agents/workflow.py with LangGraph state machine for EDD orchestration

### External Integrations for User Story 2

- [ ] T121 [P] [US2] Create corporate registry API client in backend/src/integrations/registry_api.py with Companies House, similar registries
- [ ] T122 [US2] Create graph traversal utilities in backend/src/utils/graph_utils.py with recursive CTE queries for UBO chains, cycle detection

### API Endpoints for User Story 2

- [ ] T123 [US2] Implement EDD endpoints in backend/src/api/v1/edd.py (POST /cases/{id}/edd, GET /cases/{id}/edd-status)
- [ ] T124 [US2] Implement relationships endpoints in backend/src/api/v1/relationships.py (GET /clients/{id}/relationships, GET /clients/{id}/graph)
- [ ] T125 [US2] Implement SOW review endpoints in backend/src/api/v1/sow.py (GET /cases/{id}/sow-review)

### Frontend Components for User Story 2

- [ ] T126 [P] [US2] Create RelationshipGraph component in frontend/src/components/RelationshipGraph/RelationshipGraph.tsx using D3.js force-directed layout
- [ ] T127 [P] [US2] Create SOWReview component in frontend/src/components/SOWReview/SOWReview.tsx with claimed sources, gaps, recommendations
- [ ] T128 [P] [US2] Create EDDStatus component in frontend/src/components/EDDStatus/EDDStatus.tsx with progress indicator, agent steps
- [ ] T129 [US2] Add EDD tab to CaseDetail page in frontend/src/pages/CaseDetail.tsx with enrichment results, relationship graph

### Frontend Hooks for User Story 2

- [ ] T130 [P] [US2] Create useEDD hook in frontend/src/hooks/useEDD.ts with trigger EDD mutation, status polling
- [ ] T131 [P] [US2] Create useRelationships hook in frontend/src/hooks/useRelationships.ts with fetch graph query
- [ ] T132 [P] [US2] Create useSOWReview hook in frontend/src/hooks/useSOWReview.ts with fetch review query

### Testing for User Story 2

- [ ] T133 [P] [US2] Create unit tests for EnrichmentAgent in backend/tests/unit/agents/test_enrichment.py (registry lookup, UBO extraction)
- [ ] T134 [P] [US2] Create unit tests for SOWReviewAgent in backend/tests/unit/agents/test_sow_review.py (consistency analysis, gap identification)
- [ ] T135 [US2] Create integration test for EDD workflow in backend/tests/integration/test_edd_workflow.py (trigger EDD → enrichment → SOW → results)
- [ ] T136 [P] [US2] Create component tests for RelationshipGraph in frontend/tests/unit/RelationshipGraph.test.tsx with D3 rendering mocks

**Checkpoint**: User Story 2 complete - EDD workflows automate entity enrichment, relationship mapping, SOW analysis

---

## Phase 5: User Story 3 - Human Review, Override, and Case Approval (Priority: P3)

**Goal**: Senior officer reviews case, examines AI recommendations, overrides if needed with justification, approves/rejects with complete audit trail

**Independent Test**: Assign case to reviewer, examine evidence, override risk rating with justification, approve case, verify audit trail captures all actions

### Data Models for User Story 3

- [ ] T137 [US3] Create ApprovalSnapshots model in backend/src/models/approval_snapshot.py with snapshot_type, complete case data JSONB, snapshot_hash
- [ ] T138 [US3] Create migration for User Story 3 models with alembic revision (depends on T137)

### Pydantic Schemas for User Story 3

- [ ] T139 [P] [US3] Create approval schemas in backend/src/schemas/approval.py (ApprovalRequest, RejectionRequest, ApprovalResponse)
- [ ] T140 [P] [US3] Create override schemas in backend/src/schemas/override.py (RiskOverrideRequest, ScreeningOverrideRequest)

### Services for User Story 3

- [ ] T141 [US3] Implement ApprovalService in backend/src/services/approval_service.py with approve_case, reject_case, create_snapshot methods
- [ ] T142 [US3] Implement OverrideService in backend/src/services/override_service.py with override_risk, override_screening, log_justification methods
- [ ] T143 [US3] Implement SnapshotService in backend/src/services/snapshot_service.py with generate_snapshot_json, compute_hash, upload_to_s3 methods

### AI Agents for User Story 3

- [ ] T144 [US3] Implement AuditAgent in backend/src/agents/audit.py with comprehensive audit trail generation, snapshot validation

### API Endpoints for User Story 3

- [ ] T145 [US3] Implement approval endpoints in backend/src/api/v1/approvals.py (POST /cases/{id}/approve, POST /cases/{id}/reject)
- [ ] T146 [US3] Implement override endpoints in backend/src/api/v1/overrides.py (POST /cases/{id}/override-risk, POST /screening-results/{id}/override)
- [ ] T147 [US3] Implement audit endpoints in backend/src/api/v1/audit.py (GET /cases/{id}/audit-trail, GET /cases/{id}/snapshot)

### Frontend Components for User Story 3

- [ ] T148 [P] [US3] Create ApprovalModal component in frontend/src/components/ApprovalModal/ApprovalModal.tsx with approve/reject actions, rationale input
- [ ] T149 [P] [US3] Create OverrideModal component in frontend/src/components/OverrideModal/OverrideModal.tsx with risk/screening override, justification textarea
- [ ] T150 [P] [US3] Create CaseReview component in frontend/src/components/CaseReview/CaseReview.tsx with complete case summary, all evidence
- [ ] T151 [US3] Update CaseDetail page with approval/override buttons for senior officers

### Frontend Hooks for User Story 3

- [ ] T152 [P] [US3] Create useApprovals hook in frontend/src/hooks/useApprovals.ts with approve/reject mutations
- [ ] T153 [P] [US3] Create useOverrides hook in frontend/src/hooks/useOverrides.ts with override risk/screening mutations
- [ ] T154 [P] [US3] Create useAuditTrail hook in frontend/src/hooks/useAuditTrail.ts with fetch timeline query

### Testing for User Story 3

- [ ] T155 [P] [US3] Create unit tests for ApprovalService in backend/tests/unit/services/test_approval_service.py (snapshot generation, hash computation)
- [ ] T156 [US3] Create integration test for approval workflow in backend/tests/integration/test_approval_workflow.py (review → override → approve → snapshot)
- [ ] T157 [P] [US3] Create component tests for ApprovalModal in frontend/tests/unit/ApprovalModal.test.tsx with form validation
- [ ] T158 [US3] Create E2E test for case approval in frontend/tests/e2e/case-approval.spec.ts with override and audit verification

**Checkpoint**: User Story 3 complete - human oversight with overrides, approvals, immutable audit snapshots

---

## Phase 6: User Story 4 - Live Case Monitoring and Workflow Orchestration (Priority: P4)

**Goal**: Team monitors all cases via dashboard with real-time status, workflow orchestrator manages agent handoffs, escalates stalled cases

**Independent Test**: Open dashboard with multiple cases, verify real-time updates, trigger escalation for stalled case, confirm workload distribution

### Services for User Story 4

- [ ] T159 [US4] Implement DashboardService in backend/src/services/dashboard_service.py with case_statistics, team_workload, stalled_cases methods
- [ ] T160 [US4] Implement WorkflowOrchestrationService in backend/src/services/workflow_orchestration_service.py with state_transition, trigger_agent, escalate_stalled methods
- [ ] T161 [US4] Implement NotificationService in backend/src/services/notification_service.py with send_notification, escalation_alert methods

### API Endpoints for User Story 4

- [ ] T162 [US4] Implement dashboard endpoints in backend/src/api/v1/dashboard.py (GET /dashboard/statistics, GET /dashboard/workload, GET /dashboard/stalled-cases)
- [ ] T163 [US4] Implement workflow endpoints in backend/src/api/v1/workflow.py (POST /workflow/transition, GET /workflow/status)

### Frontend Components for User Story 4

- [ ] T164 [P] [US4] Create DashboardStats component in frontend/src/components/DashboardStats/DashboardStats.tsx with case count charts, risk distribution
- [ ] T165 [P] [US4] Create WorkloadChart component in frontend/src/components/WorkloadChart/WorkloadChart.tsx with officer case assignments
- [ ] T166 [P] [US4] Create StalledCasesList component in frontend/src/components/StalledCasesList/StalledCasesList.tsx with flagged cases
- [ ] T167 [US4] Update Dashboard page with User Story 4 components, real-time WebSocket updates

### Frontend Hooks for User Story 4

- [ ] T168 [P] [US4] Create useDashboard hook in frontend/src/hooks/useDashboard.ts with statistics, workload, stalled cases queries
- [ ] T169 [US4] Update useWebSocket hook to subscribe to dashboard channels (user.*, case.*)

### Background Jobs for User Story 4

- [ ] T170 [US4] Create nightly workflow check job in backend/src/jobs/workflow_check.py with stalled case detection, auto-escalation
- [ ] T171 [US4] Create Lambda function for scheduled workflow checks in infra/lib/stacks/scheduler-stack.ts with EventBridge rule

### Testing for User Story 4

- [ ] T172 [P] [US4] Create unit tests for WorkflowOrchestrationService in backend/tests/unit/services/test_workflow_orchestration.py (state transitions, escalations)
- [ ] T173 [US4] Create integration test for workflow orchestration in backend/tests/integration/test_workflow_orchestration.py (automatic agent handoffs)
- [ ] T174 [US4] Create E2E test for dashboard monitoring in frontend/tests/e2e/dashboard-monitoring.spec.ts with real-time updates

**Checkpoint**: User Story 4 complete - operational visibility, workflow automation, team management

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: System-wide improvements, documentation, performance optimization

### Performance & Optimization

- [ ] T175 [P] Add database query optimization with indexes per data-model.md (cases_dashboard, screening_pending, risk_high indexes)
- [ ] T176 [P] Implement API response caching in backend/src/api/middleware/cache.py for read-heavy endpoints
- [ ] T177 [P] Add connection pooling with RDS Proxy in infra/lib/stacks/rds-stack.ts
- [ ] T178 [P] Optimize frontend bundle size with code splitting, lazy loading in frontend/src/App.tsx

### Security Hardening

- [ ] T179 [P] Implement rate limiting middleware in backend/src/api/middleware/rate_limiter.py with Redis backend
- [ ] T180 [P] Add PII masking for logs in backend/src/utils/logging.py with regex patterns
- [ ] T181 [P] Setup Secrets Manager rotation in infra/lib/stacks/secrets-stack.ts for database credentials
- [ ] T182 [P] Add Content Security Policy headers in frontend hosting (CloudFront custom headers)

### Monitoring & Observability

- [ ] T183 [P] Create CloudWatch dashboards in infra/lib/stacks/monitoring-stack.ts with key metrics (API latency, error rates, agent duration)
- [ ] T184 [P] Setup CloudWatch alarms in infra/lib/stacks/monitoring-stack.ts with SNS notifications (API errors >5%, RDS CPU >80%)
- [ ] T185 [P] Implement Prometheus metrics exporters in backend/src/utils/metrics.py with case processing throughput, risk score distribution
- [ ] T186 [P] Deploy Grafana on Fargate in infra/lib/stacks/monitoring-stack.ts with custom dashboards

### Documentation

- [ ] T187 [P] Create API documentation with OpenAPI spec validation, publish Swagger UI at /docs
- [ ] T188 [P] Write developer documentation in docs/development.md with setup, testing, deployment workflows
- [ ] T189 [P] Create architecture decision records in docs/adr/ for key technical choices
- [ ] T190 [P] Update README.md with project overview, quick start, contribution guidelines

### Deployment & CI/CD

- [ ] T191 Create deployment workflow in .github/workflows/deploy-dev.yml for automatic dev deployment on main branch
- [ ] T192 [P] Create deployment workflow in .github/workflows/deploy-staging.yml with manual approval
- [ ] T193 [P] Create deployment workflow in .github/workflows/deploy-prod.yml with manual approval, blue-green Lambda deployment
- [ ] T194 [P] Setup CloudFront frontend deployment in infra/lib/stacks/frontend-stack.ts with S3 sync, cache invalidation
- [ ] T195 Create smoke tests in scripts/smoke-tests.sh for post-deployment validation

### Additional Testing

- [ ] T196 [P] Create load tests with Locust in backend/tests/load/locustfile.py for 1,000 concurrent cases target
- [ ] T197 [P] Create security tests with OWASP ZAP in scripts/security-scan.sh for vulnerability scanning
- [ ] T198 [P] Add snapshot tests for CDK infrastructure in infra/test/stacks.test.ts
- [ ] T199 Run quickstart.md validation to verify local setup instructions are accurate

### Code Quality

- [ ] T200 [P] Add type checking with mypy to CI pipeline, fix all type errors
- [ ] T201 [P] Achieve 80% backend test coverage (verify with pytest-cov)
- [ ] T202 [P] Achieve 70% frontend test coverage (verify with Jest coverage report)
- [ ] T203 Refactor duplicate code across agents into shared utilities in backend/src/agents/utils/

**Checkpoint**: Production-ready system with comprehensive testing, monitoring, documentation

---

## Dependencies & Execution Order

### Phase Dependencies

```
Setup (Phase 1)
  ↓
Foundational (Phase 2) - BLOCKS ALL USER STORIES
  ↓
  ├── User Story 1 (Phase 3) - MVP - Independent ✅
  ├── User Story 2 (Phase 4) - Independent (can integrate with US1)
  ├── User Story 3 (Phase 5) - Independent (builds on US1/US2)
  └── User Story 4 (Phase 6) - Independent (orchestrates all)
  ↓
Polish (Phase 7)
```

### Critical Path

1. **Must Complete First**: Setup (T001-T011) → Foundational (T012-T050)
2. **Can Start After Foundation**: All 4 user stories (Phase 3-6 in parallel if team capacity allows)
3. **Recommended Order**: US1 → US2 → US3 → US4 (by priority, each independently testable)
4. **Final**: Polish phase after desired user stories complete

### Within Each User Story

- **Models First**: Data models before services/agents
- **Services Next**: Business logic before API endpoints
- **Agents Parallel**: All agents for a story can be built in parallel (T070-T073 for US1)
- **API Layer**: After services complete
- **Frontend**: Can start when API contracts are defined (even before backend implementation)
- **Tests**: Unit tests can be written alongside implementation, integration tests after API complete

### Parallel Opportunities (Examples)

**Phase 1 (Setup) - 4 parallel tasks**:
```
T003 (frontend npm init) || T004 (infra CDK init) || T005 (Python linting) || T006 (TS linting)
```

**Phase 2 (Foundation) - Database Models - 3 parallel tasks**:
```
T015 (Roles model) || T016 (Users model) [before T017 migration]
```

**User Story 1 - AI Agents - 4 parallel tasks**:
```
T070 (IntakeAgent) || T071 (DocumentIngestAgent) || T072 (ScreeningAgent) || T073 (RiskScoringAgent)
```

**User Story 1 - Frontend Components - 6 parallel tasks**:
```
T084 (Dashboard) || T085 (CaseList) || T087 (CaseForm) || T088 (DocumentUpload) || T089 (RiskBadge) || T090 (ScreeningResults)
```

**Polish Phase - All tasks can run in parallel**: T175-T203 (29 parallel tasks)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

**Goal**: Deliver core KYC intake functionality as fast as possible

**Steps**:
1. ✅ Complete Phase 1: Setup (T001-T011)
2. ✅ Complete Phase 2: Foundational (T012-T050) - Critical blocking phase
3. ✅ Complete Phase 3: User Story 1 (T051-T105)
4. 🎯 **STOP and VALIDATE**: Test case creation → document upload → screening → risk assessment end-to-end
5. 🚀 **Deploy MVP**: Officers can immediately start using basic KYC intake

**Timeline**: ~4-6 weeks with 3-4 engineers (1 backend, 1 frontend, 1 infrastructure, 1 testing)

### Incremental Delivery

**After MVP, add features incrementally**:

**Iteration 2** (MVP + EDD):
- Add User Story 2 (T106-T136)
- Deploy and validate EDD workflows
- Timeline: +2-3 weeks

**Iteration 3** (MVP + EDD + Approvals):
- Add User Story 3 (T137-T158)
- Deploy and validate approval workflows with audit
- Timeline: +2-3 weeks

**Iteration 4** (Full System):
- Add User Story 4 (T159-T174)
- Deploy and validate dashboard, workflow orchestration
- Timeline: +2 weeks

**Iteration 5** (Production Hardening):
- Complete Phase 7: Polish (T175-T203)
- Deploy to production with full monitoring
- Timeline: +2-3 weeks

**Total Estimated Timeline**: 12-17 weeks (3-4 months) for complete system

### Parallel Team Strategy

**With 6 engineers, work on multiple user stories simultaneously after foundation**:

**Weeks 1-2**: All hands on Setup + Foundational (T001-T050)

**Weeks 3-6**: Parallel user story development
- **Team A** (2 engineers): User Story 1 (T051-T105)
- **Team B** (2 engineers): User Story 2 (T106-T136)
- **Team C** (2 engineers): User Story 3 (T137-T158)

**Weeks 7-8**: Integration + User Story 4
- **All teams**: User Story 4 (T159-T174) + integration testing

**Weeks 9-10**: Polish + Production Readiness
- **All teams**: Phase 7 (T175-T203)

**Accelerated Timeline**: 10 weeks with 6 engineers

---

## Task Summary

- **Total Tasks**: 203
- **Phase 1 (Setup)**: 11 tasks
- **Phase 2 (Foundational)**: 39 tasks (BLOCKING)
- **Phase 3 (User Story 1)**: 55 tasks (MVP)
- **Phase 4 (User Story 2)**: 31 tasks
- **Phase 5 (User Story 3)**: 22 tasks
- **Phase 6 (User Story 4)**: 16 tasks
- **Phase 7 (Polish)**: 29 tasks

### Tasks by User Story

- **US1 (Client Intake & Risk)**: 55 tasks (27% of total)
- **US2 (EDD & SOW)**: 31 tasks (15% of total)
- **US3 (Approval & Override)**: 22 tasks (11% of total)
- **US4 (Monitoring & Orchestration)**: 16 tasks (8% of total)
- **Shared Infrastructure**: 79 tasks (39% of total)

### Parallelizable Tasks

- **Phase 1**: 7 of 11 tasks marked [P] (64%)
- **Phase 2**: 24 of 39 tasks marked [P] (62%)
- **User Story 1**: 36 of 55 tasks marked [P] (65%)
- **User Story 2**: 20 of 31 tasks marked [P] (65%)
- **User Story 3**: 13 of 22 tasks marked [P] (59%)
- **User Story 4**: 9 of 16 tasks marked [P] (56%)
- **Polish**: 29 of 29 tasks marked [P] (100%)

### Estimated Effort

- **MVP (Setup + Foundation + US1)**: ~105 tasks
- **Full System (All user stories)**: ~174 tasks
- **Production Ready (With polish)**: 203 tasks

---

## Notes

- All tasks follow strict checklist format: `- [ ] [TaskID] [P?] [Story?] Description with file path`
- [P] indicates tasks that can be worked on in parallel (different files, no blocking dependencies)
- [Story] labels (US1, US2, US3, US4) enable tracing tasks back to user stories in spec.md
- Each user story is independently testable and can be deployed separately
- Constitution Principle VI (TDD) enforced: tests written alongside/before implementation
- Foundational phase (T012-T050) is critical path - blocks all user story work
- MVP = Setup + Foundational + User Story 1 (delivers immediate value)
- After MVP, user stories can be added incrementally or in parallel
- All file paths match project structure from plan.md (backend/, frontend/, infra/)
