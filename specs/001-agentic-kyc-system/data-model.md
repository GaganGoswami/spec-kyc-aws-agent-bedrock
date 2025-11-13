# Data Model: Agentic KYC System

**Feature**: 001-agentic-kyc-system  
**Date**: 2025-11-12  
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the complete data model for the KYC system, including relational schemas (Postgres), document stores (DynamoDB), and object storage (S3). The model supports full audit traceability, complex entity relationships, workflow state management, and long-term compliance retention.

---

## Database Strategy

### Amazon RDS Postgres (Multi-AZ)
**Purpose**: Transactional data requiring ACID guarantees, complex queries, and referential integrity

**Tables**: Cases, Clients, Documents, RelatedParties, ScreeningResults, RiskAssessments, SourceOfWealthReviews, EntityRelationships, AgentInvocations, AuditEvents, ApprovalSnapshots, Users, Roles

### Amazon DynamoDB
**Purpose**: High-throughput agent session state, embeddings for similarity search

**Tables**: AgentSessions, EmbeddingsStore

### Amazon S3
**Purpose**: Binary document storage, immutable audit snapshots

**Buckets**: `kyc-documents-{env}`, `kyc-audit-snapshots-{env}`

---

## Postgres Schema

### 1. Users

**Purpose**: System users (compliance officers, managers, administrators)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,  -- bcrypt hashed
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  role_id UUID REFERENCES roles(id) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);
```

**Validations**:
- `username`: 3-50 characters, alphanumeric + underscore
- `email`: Valid email format
- `password_hash`: bcrypt with cost factor 12
- Soft delete via `is_active` flag

---

### 2. Roles

**Purpose**: Role-based access control (RBAC) definitions

```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) UNIQUE NOT NULL,  -- 'case_officer', 'senior_officer', 'manager', 'administrator'
  description TEXT,
  permissions JSONB NOT NULL,  -- {"cases": ["read", "write"], "approvals": ["execute"]}
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_roles_name ON roles(name);
```

**Permissions Structure**:
```json
{
  "cases": ["read", "write", "delete"],
  "documents": ["read", "upload", "delete"],
  "approvals": ["read", "execute"],
  "screening": ["read", "override"],
  "risk_assessment": ["read", "override"],
  "reports": ["read", "export"],
  "users": ["read", "write", "delete"]
}
```

---

### 3. Cases

**Purpose**: KYC review instances for clients

```sql
CREATE TABLE cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_number VARCHAR(50) UNIQUE NOT NULL,  -- e.g., "KYC-2025-001234"
  client_id UUID REFERENCES clients(id) NOT NULL,
  status VARCHAR(50) NOT NULL,  -- 'OPEN', 'UNDER_REVIEW', 'EDD_REQUIRED', 'APPROVED', 'REJECTED', 'CLOSED'
  assigned_officer_id UUID REFERENCES users(id),
  assigned_reviewer_id UUID REFERENCES users(id),
  priority VARCHAR(20) DEFAULT 'NORMAL',  -- 'LOW', 'NORMAL', 'HIGH', 'URGENT'
  due_date DATE,
  opened_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  closed_at TIMESTAMP,
  closure_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  CONSTRAINT valid_status CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'EDD_REQUIRED', 'APPROVED', 'REJECTED', 'CLOSED'))
);

CREATE INDEX idx_cases_case_number ON cases(case_number);
CREATE INDEX idx_cases_client ON cases(client_id);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_cases_assigned_officer ON cases(assigned_officer_id);
CREATE INDEX idx_cases_opened_at ON cases(opened_at DESC);
CREATE INDEX idx_cases_status_opened ON cases(status, opened_at DESC);  -- Dashboard queries
```

**Business Rules**:
- `case_number` auto-generated: `KYC-{year}-{sequence}`
- `status` transitions follow workflow: OPEN → UNDER_REVIEW → [EDD_REQUIRED] → APPROVED/REJECTED → CLOSED
- `due_date` calculated based on risk level (LOW: 30 days, MEDIUM: 15 days, HIGH: 7 days)
- `assigned_reviewer_id` required for UNDER_REVIEW status

---

### 4. Clients

**Purpose**: Individual or entity undergoing KYC review

```sql
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_type VARCHAR(20) NOT NULL,  -- 'INDIVIDUAL', 'ENTITY'
  
  -- Common fields
  legal_name VARCHAR(500) NOT NULL,
  aliases JSONB,  -- ["John Smith", "J. Smith"]
  
  -- Individual-specific
  first_name VARCHAR(200),
  middle_name VARCHAR(200),
  last_name VARCHAR(200),
  date_of_birth DATE,
  place_of_birth VARCHAR(200),
  gender VARCHAR(20),
  nationality VARCHAR(100),
  national_id VARCHAR(100),
  passport_number VARCHAR(50),
  passport_expiry DATE,
  tax_id VARCHAR(100),
  
  -- Entity-specific
  registration_number VARCHAR(100),
  jurisdiction_of_incorporation VARCHAR(100),
  date_of_incorporation DATE,
  entity_type VARCHAR(100),  -- 'LLC', 'Corporation', 'Trust', 'Foundation'
  business_activity TEXT,
  
  -- Contact
  residential_address JSONB,  -- {"line1": "123 Main St", "city": "New York", "country": "USA", "postal_code": "10001"}
  registered_address JSONB,  -- For entities
  phone VARCHAR(50),
  email VARCHAR(255),
  
  -- Classification
  is_pep BOOLEAN DEFAULT false,
  pep_category VARCHAR(100),  -- 'Domestic', 'Foreign', 'International Organization'
  is_high_net_worth BOOLEAN DEFAULT true,
  estimated_net_worth_usd DECIMAL(20, 2),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  
  CONSTRAINT valid_client_type CHECK (client_type IN ('INDIVIDUAL', 'ENTITY'))
);

CREATE INDEX idx_clients_type ON clients(client_type);
CREATE INDEX idx_clients_legal_name ON clients(legal_name);
CREATE INDEX idx_clients_dob ON clients(date_of_birth);  -- For duplicate detection
CREATE INDEX idx_clients_nationality ON clients(nationality);
CREATE INDEX idx_clients_registration_number ON clients(registration_number);
CREATE INDEX idx_clients_is_pep ON clients(is_pep);
```

**Duplicate Detection Query**:
```sql
-- Find potential duplicates (fuzzy match on name + DOB ± 1 year)
SELECT * FROM clients 
WHERE client_type = 'INDIVIDUAL'
  AND similarity(legal_name, 'John Doe') > 0.8  -- pg_trgm extension
  AND date_of_birth BETWEEN '1980-01-01' AND '1982-01-01';
```

---

### 5. RelatedParties

**Purpose**: Individuals/entities related to primary client (beneficial owners, directors, family)

```sql
CREATE TABLE related_parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_client_id UUID REFERENCES clients(id) NOT NULL,
  related_client_id UUID REFERENCES clients(id),  -- NULL if not yet a full client
  relationship_type VARCHAR(100) NOT NULL,  -- 'beneficial_owner', 'director', 'shareholder', 'authorized_signatory', 'family_member', 'associate'
  ownership_percentage DECIMAL(5, 2),  -- For beneficial owners (0-100)
  role_description TEXT,  -- e.g., "Chief Financial Officer"
  
  -- If related party not a full client
  name VARCHAR(500),
  date_of_birth DATE,
  nationality VARCHAR(100),
  identifiers JSONB,  -- {"passport": "P123456", "tax_id": "123-45-6789"}
  
  effective_from DATE,
  effective_to DATE,  -- NULL if current
  evidence_documents UUID[],  -- Array of document IDs
  confidence_score DECIMAL(3, 2),  -- AI-extracted confidence (0.00-1.00)
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  
  CONSTRAINT ownership_percentage_valid CHECK (ownership_percentage IS NULL OR (ownership_percentage >= 0 AND ownership_percentage <= 100))
);

CREATE INDEX idx_related_parties_primary ON related_parties(primary_client_id);
CREATE INDEX idx_related_parties_related ON related_parties(related_client_id);
CREATE INDEX idx_related_parties_type ON related_parties(relationship_type);
CREATE INDEX idx_related_parties_ownership ON related_parties(ownership_percentage DESC) WHERE ownership_percentage IS NOT NULL;
```

---

### 6. Documents

**Purpose**: Metadata for uploaded documents (files stored in S3)

```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  document_type VARCHAR(100) NOT NULL,  -- 'passport', 'driver_license', 'utility_bill', 'bank_statement', 'incorporation_certificate', 'shareholder_register', 'other'
  file_name VARCHAR(500) NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  s3_bucket VARCHAR(255) NOT NULL,
  s3_key VARCHAR(1024) NOT NULL,
  s3_version_id VARCHAR(255),
  content_hash VARCHAR(64) NOT NULL,  -- SHA-256 of file content
  
  -- OCR/Extraction results
  extracted_text TEXT,
  extraction_confidence DECIMAL(3, 2),  -- 0.00-1.00
  extracted_entities JSONB,  -- {"name": "John Doe", "dob": "1980-01-15", "passport_number": "P123456"}
  extraction_model VARCHAR(100),  -- 'aws-textract', 'bedrock-claude-3'
  
  uploaded_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP,
  uploaded_by UUID REFERENCES users(id),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_documents_case ON documents(case_id);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_uploaded_at ON documents(uploaded_at DESC);
CREATE INDEX idx_documents_s3_key ON documents(s3_bucket, s3_key);
CREATE INDEX idx_documents_content_hash ON documents(content_hash);  -- Detect duplicate uploads
```

**S3 Path Convention**: `s3://{bucket}/cases/{case_id}/documents/{document_id}/{filename}`

---

### 7. ScreeningResults

**Purpose**: Sanctions, PEP, and adverse media screening outcomes

```sql
CREATE TABLE screening_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  client_id UUID REFERENCES clients(id) NOT NULL,
  screening_type VARCHAR(50) NOT NULL,  -- 'SANCTIONS', 'PEP', 'ADVERSE_MEDIA'
  provider VARCHAR(100) NOT NULL,  -- 'dow_jones', 'world_check', 'comply_advantage'
  
  -- Query details
  search_query JSONB NOT NULL,  -- {"name": "John Doe", "dob": "1980-01-15", "nationality": "USA"}
  search_timestamp TIMESTAMP DEFAULT NOW(),
  
  -- Results
  match_status VARCHAR(20) NOT NULL,  -- 'NO_HIT', 'HIT', 'POTENTIAL_MATCH'
  match_count INTEGER DEFAULT 0,
  matches JSONB,  -- Array of match details
  /*
  [
    {
      "match_id": "WC-123456",
      "name": "John Doe",
      "match_score": 0.95,
      "category": "Sanctions",
      "list": "OFAC SDN",
      "date_added": "2020-03-15",
      "evidence_url": "https://...",
      "evidence_text": "Individual sanctioned for..."
    }
  ]
  */
  
  -- Review status
  review_status VARCHAR(50) DEFAULT 'PENDING',  -- 'PENDING', 'CONFIRMED', 'FALSE_POSITIVE', 'NEEDS_INVESTIGATION'
  reviewed_at TIMESTAMP,
  reviewed_by UUID REFERENCES users(id),
  review_notes TEXT,
  
  -- API metadata
  api_request_id VARCHAR(255),
  api_response_time_ms INTEGER,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_match_status CHECK (match_status IN ('NO_HIT', 'HIT', 'POTENTIAL_MATCH')),
  CONSTRAINT valid_review_status CHECK (review_status IN ('PENDING', 'CONFIRMED', 'FALSE_POSITIVE', 'NEEDS_INVESTIGATION'))
);

CREATE INDEX idx_screening_case ON screening_results(case_id);
CREATE INDEX idx_screening_client ON screening_results(client_id);
CREATE INDEX idx_screening_type ON screening_results(screening_type);
CREATE INDEX idx_screening_match_status ON screening_results(match_status);
CREATE INDEX idx_screening_review_status ON screening_results(review_status);
CREATE INDEX idx_screening_timestamp ON screening_results(search_timestamp DESC);
```

---

### 8. RiskAssessments

**Purpose**: AI-computed risk scores with explainability

```sql
CREATE TABLE risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  client_id UUID REFERENCES clients(id) NOT NULL,
  
  -- Score
  risk_score INTEGER NOT NULL,  -- 0-100
  risk_level VARCHAR(20) NOT NULL,  -- 'LOW' (0-33), 'MEDIUM' (34-66), 'HIGH' (67-100)
  
  -- Explainability
  risk_drivers JSONB NOT NULL,  -- Array of contributing factors
  /*
  [
    {"factor": "PEP match", "weight": 0.35, "description": "Client identified as Politically Exposed Person"},
    {"factor": "High-risk jurisdiction", "weight": 0.25, "description": "Nationality in FATF high-risk list"},
    {"factor": "Complex ownership", "weight": 0.20, "description": "5 layers of beneficial ownership"},
    {"factor": "Unclear SOW", "weight": 0.20, "description": "Source of wealth documentation incomplete"}
  ]
  */
  rationale_text TEXT NOT NULL,  -- Natural language explanation
  
  -- Model info
  model_version VARCHAR(100) NOT NULL,  -- 'risk-model-v2.1', 'bedrock-claude-3.5-sonnet-20250101'
  confidence_score DECIMAL(3, 2) NOT NULL,  -- 0.00-1.00
  data_provenance JSONB,  -- Sources used (screening results, documents, enrichment data)
  
  -- Override
  is_overridden BOOLEAN DEFAULT false,
  override_score INTEGER,
  override_level VARCHAR(20),
  override_reason TEXT,
  overridden_at TIMESTAMP,
  overridden_by UUID REFERENCES users(id),
  
  computed_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_risk_score CHECK (risk_score >= 0 AND risk_score <= 100),
  CONSTRAINT valid_risk_level CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT valid_override_score CHECK (override_score IS NULL OR (override_score >= 0 AND override_score <= 100)),
  CONSTRAINT valid_override_level CHECK (override_level IS NULL OR override_level IN ('LOW', 'MEDIUM', 'HIGH'))
);

CREATE INDEX idx_risk_case ON risk_assessments(case_id);
CREATE INDEX idx_risk_client ON risk_assessments(client_id);
CREATE INDEX idx_risk_level ON risk_assessments(risk_level);
CREATE INDEX idx_risk_overridden ON risk_assessments(is_overridden);
CREATE INDEX idx_risk_computed_at ON risk_assessments(computed_at DESC);
```

---

### 9. SourceOfWealthReviews

**Purpose**: AI-generated source of wealth analysis

```sql
CREATE TABLE source_of_wealth_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  client_id UUID REFERENCES clients(id) NOT NULL,
  
  -- Claimed sources
  claimed_sources JSONB NOT NULL,  -- ["Inheritance", "Sale of business", "Investment income"]
  claimed_amount_usd DECIMAL(20, 2),
  
  -- Analysis
  summary_text TEXT NOT NULL,  -- AI-generated narrative
  consistency_analysis TEXT,  -- "Claimed inheritance of $5M aligns with probate documents dated 2020-03-15"
  identified_gaps JSONB,  -- ["No tax returns provided for investment income", "Business sale agreement missing"]
  recommendations JSONB,  -- ["Request probate court documents", "Obtain certified tax returns for 2019-2023"]
  
  -- Supporting documents
  referenced_documents UUID[],  -- Array of document IDs
  
  -- Assessment
  confidence_level VARCHAR(20) NOT NULL,  -- 'LOW', 'MEDIUM', 'HIGH'
  confidence_score DECIMAL(3, 2),  -- 0.00-1.00
  requires_further_review BOOLEAN DEFAULT false,
  
  -- Model info
  model_version VARCHAR(100) NOT NULL,
  reviewed_at TIMESTAMP DEFAULT NOW(),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_confidence_level CHECK (confidence_level IN ('LOW', 'MEDIUM', 'HIGH'))
);

CREATE INDEX idx_sow_case ON source_of_wealth_reviews(case_id);
CREATE INDEX idx_sow_client ON source_of_wealth_reviews(client_id);
CREATE INDEX idx_sow_confidence ON source_of_wealth_reviews(confidence_level);
CREATE INDEX idx_sow_reviewed_at ON source_of_wealth_reviews(reviewed_at DESC);
```

---

### 10. EntityRelationships

**Purpose**: Graph connections between clients (ownership, control, family)

```sql
CREATE TABLE entity_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_client_id UUID REFERENCES clients(id) NOT NULL,
  target_client_id UUID REFERENCES clients(id) NOT NULL,
  relationship_type VARCHAR(100) NOT NULL,  -- 'OWNERSHIP', 'CONTROL', 'FAMILY', 'BUSINESS_ASSOCIATE'
  
  ownership_percentage DECIMAL(5, 2),  -- For OWNERSHIP relationships
  control_mechanism VARCHAR(200),  -- 'Voting rights', 'Board membership', 'Management agreement'
  
  effective_from DATE,
  effective_to DATE,  -- NULL if current
  
  evidence_documents UUID[],  -- Array of document IDs
  evidence_source VARCHAR(200),  -- 'corporate_registry', 'shareholder_register', 'client_declaration'
  confidence_score DECIMAL(3, 2) NOT NULL,  -- 0.00-1.00
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  
  CONSTRAINT no_self_relationship CHECK (source_client_id != target_client_id),
  CONSTRAINT valid_ownership_percentage CHECK (ownership_percentage IS NULL OR (ownership_percentage >= 0 AND ownership_percentage <= 100))
);

CREATE INDEX idx_entity_rel_source ON entity_relationships(source_client_id);
CREATE INDEX idx_entity_rel_target ON entity_relationships(target_client_id);
CREATE INDEX idx_entity_rel_type ON entity_relationships(relationship_type);
CREATE INDEX idx_entity_rel_both ON entity_relationships(source_client_id, target_client_id);  -- Bidirectional queries
```

**Recursive Query (Find Ultimate Beneficial Owners)**:
```sql
WITH RECURSIVE ownership_chain AS (
  -- Base case: direct ownership
  SELECT source_client_id, target_client_id, ownership_percentage, 1 AS depth, ARRAY[source_client_id] AS path
  FROM entity_relationships
  WHERE target_client_id = :client_id
    AND relationship_type = 'OWNERSHIP'
    AND (effective_to IS NULL OR effective_to > NOW())
  
  UNION ALL
  
  -- Recursive case: traverse up the chain
  SELECT er.source_client_id, er.target_client_id, er.ownership_percentage, oc.depth + 1, oc.path || er.source_client_id
  FROM entity_relationships er
  JOIN ownership_chain oc ON er.target_client_id = oc.source_client_id
  WHERE er.relationship_type = 'OWNERSHIP'
    AND (er.effective_to IS NULL OR er.effective_to > NOW())
    AND NOT (er.source_client_id = ANY(oc.path))  -- Detect cycles
    AND oc.depth < 10  -- Limit depth
)
SELECT DISTINCT ON (source_client_id) 
  source_client_id, 
  c.legal_name,
  ownership_percentage,
  depth,
  path
FROM ownership_chain oc
JOIN clients c ON c.id = oc.source_client_id
WHERE ownership_percentage >= 25.0  -- Beneficial ownership threshold
ORDER BY source_client_id, depth DESC;
```

---

### 11. AgentInvocations

**Purpose**: Audit trail of all AI agent executions

```sql
CREATE TABLE agent_invocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  agent_type VARCHAR(100) NOT NULL,  -- 'intake', 'document_ingest', 'screening', 'entity_resolution', 'enrichment', 'risk_scoring', 'sow_review', 'workflow', 'audit'
  
  -- Execution details
  input_parameters JSONB NOT NULL,
  output_results JSONB NOT NULL,
  confidence_score DECIMAL(3, 2),
  
  -- Model/tool info
  model_identifier VARCHAR(200),  -- 'bedrock:anthropic.claude-3-5-sonnet-20250101'
  tool_calls JSONB,  -- Array of tool invocations
  /*
  [
    {"tool": "screening_api", "input": {...}, "output": {...}, "duration_ms": 1234},
    {"tool": "corporate_registry", "input": {...}, "output": {...}, "duration_ms": 567}
  ]
  */
  
  -- Provenance
  data_sources JSONB,  -- ["screening_result:uuid", "document:uuid", "external_api:dow_jones"]
  
  -- Performance
  execution_duration_ms INTEGER NOT NULL,
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP DEFAULT NOW(),
  
  -- Error handling
  status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',  -- 'SUCCESS', 'FAILED', 'TIMEOUT', 'RETRY'
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('SUCCESS', 'FAILED', 'TIMEOUT', 'RETRY'))
);

CREATE INDEX idx_agent_inv_case ON agent_invocations(case_id);
CREATE INDEX idx_agent_inv_type ON agent_invocations(agent_type);
CREATE INDEX idx_agent_inv_started ON agent_invocations(started_at DESC);
CREATE INDEX idx_agent_inv_status ON agent_invocations(status);
CREATE INDEX idx_agent_inv_duration ON agent_invocations(execution_duration_ms DESC);  -- Performance monitoring
```

---

### 12. AuditEvents

**Purpose**: Complete timeline of all case activities (data captures, state transitions, user actions)

```sql
CREATE TABLE audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,  -- 'case_created', 'document_uploaded', 'screening_executed', 'risk_computed', 'status_transition', 'override_applied', 'case_approved', 'case_rejected'
  case_id UUID REFERENCES cases(id),
  client_id UUID REFERENCES clients(id),
  
  -- Actor
  actor_type VARCHAR(50) NOT NULL,  -- 'USER', 'SYSTEM', 'AGENT'
  actor_id UUID,  -- user_id or agent_invocation_id
  actor_name VARCHAR(200),  -- Human-readable (e.g., "John Smith", "RiskScoringAgent")
  
  -- Event details
  description TEXT NOT NULL,  -- "Case status changed from OPEN to UNDER_REVIEW"
  before_value JSONB,  -- Previous state
  after_value JSONB,  -- New state
  metadata JSONB,  -- Additional context
  
  event_timestamp TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_actor_type CHECK (actor_type IN ('USER', 'SYSTEM', 'AGENT'))
);

CREATE INDEX idx_audit_case ON audit_events(case_id);
CREATE INDEX idx_audit_client ON audit_events(client_id);
CREATE INDEX idx_audit_type ON audit_events(event_type);
CREATE INDEX idx_audit_timestamp ON audit_events(event_timestamp DESC);
CREATE INDEX idx_audit_actor ON audit_events(actor_type, actor_id);
```

**Example Event**:
```json
{
  "event_type": "risk_override_applied",
  "case_id": "123e4567-e89b-12d3-a456-426614174000",
  "actor_type": "USER",
  "actor_id": "789e4567-e89b-12d3-a456-426614174999",
  "actor_name": "Jane Doe (Senior Officer)",
  "description": "Risk level manually overridden from HIGH to MEDIUM",
  "before_value": {"risk_score": 72, "risk_level": "HIGH"},
  "after_value": {"risk_score": 55, "risk_level": "MEDIUM"},
  "metadata": {
    "justification": "Adverse media relates to civil dispute from 2015, not ongoing financial crime activity. Client has clean record since then.",
    "override_timestamp": "2025-11-12T15:30:00Z"
  }
}
```

---

### 13. ApprovalSnapshots

**Purpose**: Immutable records of case state at approval/rejection

```sql
CREATE TABLE approval_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES cases(id) NOT NULL,
  snapshot_type VARCHAR(20) NOT NULL,  -- 'APPROVED', 'REJECTED'
  
  -- Decision
  approver_id UUID REFERENCES users(id) NOT NULL,
  approver_name VARCHAR(200) NOT NULL,
  approval_timestamp TIMESTAMP DEFAULT NOW(),
  decision_rationale TEXT,
  
  -- Complete case state (JSON export)
  case_data JSONB NOT NULL,  -- Full case details
  client_data JSONB NOT NULL,  -- Full client details
  documents JSONB NOT NULL,  -- All document metadata + hashes
  screening_results JSONB NOT NULL,
  risk_assessment JSONB NOT NULL,
  sow_review JSONB,
  entity_relationships JSONB,
  agent_invocations JSONB,  -- Summary of all agent executions
  audit_trail JSONB NOT NULL,  -- Complete timeline
  
  -- Integrity
  snapshot_hash VARCHAR(64) NOT NULL,  -- SHA-256 of entire snapshot JSON
  s3_backup_key VARCHAR(1024),  -- Path to S3 backup (with Object Lock)
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_snapshot_type CHECK (snapshot_type IN ('APPROVED', 'REJECTED'))
);

CREATE INDEX idx_approval_case ON approval_snapshots(case_id);
CREATE INDEX idx_approval_approver ON approval_snapshots(approver_id);
CREATE INDEX idx_approval_timestamp ON approval_snapshots(approval_timestamp DESC);
CREATE INDEX idx_approval_hash ON approval_snapshots(snapshot_hash);
```

**S3 Backup**: Stored in S3 with Object Lock (WORM - Write Once Read Many) for immutability, retained for 7 years per compliance requirements.

---

## DynamoDB Tables

### 1. AgentSessions

**Purpose**: Workflow state for long-running agent processes

**Primary Key**: `session_id` (Partition Key)  
**Sort Key**: N/A (single-item per session)

**Schema**:
```json
{
  "session_id": "uuid",  // Partition key
  "case_id": "uuid",
  "agent_type": "entity_resolution | enrichment | edd_workflow",
  "status": "RUNNING | COMPLETED | FAILED | PAUSED",
  "current_step": "fetch_corporate_registry",
  "total_steps": 5,
  "progress_percentage": 60,
  
  "state": {
    "collected_data": {
      "corporate_registry_response": {...},
      "beneficial_owners": [...]
    },
    "intermediate_results": {...},
    "pending_decisions": [...]
  },
  
  "conversation_history": [
    {"role": "user", "content": "Enrich entity ABC Corp"},
    {"role": "assistant", "content": "Fetching corporate registry data..."},
    {"role": "tool", "tool_name": "registry_api", "content": "{...}"}
  ],
  
  "metadata": {
    "model_version": "bedrock:claude-3.5-sonnet",
    "started_at": "2025-11-12T10:00:00Z",
    "last_updated_at": "2025-11-12T10:05:30Z"
  },
  
  "ttl": 1699900800  // Auto-delete after 30 days (Unix timestamp)
}
```

**Indexes**:
- GSI1: `case_id` (PK) + `status` (SK) - Query all sessions for a case
- GSI2: `status` (PK) + `last_updated_at` (SK) - Find stalled sessions

---

### 2. EmbeddingsStore

**Purpose**: Vector embeddings for similarity search (prior cases, documents)

**Primary Key**: `embedding_id` (Partition Key)  
**Sort Key**: N/A

**Schema**:
```json
{
  "embedding_id": "uuid",  // Partition key
  "entity_type": "case | document | client_description",
  "entity_id": "uuid",  // Reference to Cases, Documents, or Clients table
  
  "embedding_vector": [0.123, -0.456, 0.789, ...],  // 1536 dimensions (Titan Embeddings)
  
  "text_content": "High-net-worth individual from Switzerland, inheritance as source of wealth...",
  
  "metadata": {
    "model": "amazon.titan-embed-text-v1",
    "created_at": "2025-11-12T10:00:00Z",
    "version": 1
  },
  
  "ttl": null  // No auto-delete (keep for similarity search)
}
```

**Similarity Search Strategy**:
- Use DynamoDB as lightweight vector store for ~10K embeddings (MVP scale)
- For >100K embeddings, migrate to Amazon OpenSearch or Pinecone
- Similarity search: Fetch all embeddings, compute cosine similarity in-memory (acceptable for small dataset)

**Indexes**:
- GSI1: `entity_type` (PK) + `entity_id` (SK) - Lookup embedding by entity

---

## S3 Storage

### Bucket 1: `kyc-documents-{env}`

**Purpose**: Store uploaded document files

**Bucket Configuration**:
- **Versioning**: Enabled (track all document versions)
- **Encryption**: AES-256 with AWS KMS customer-managed key
- **Lifecycle Policy**:
  - Transition to Standard-IA after 90 days
  - Transition to Glacier Flexible Retrieval after 1 year
  - Retain for 7 years minimum
- **Access**: Private (pre-signed URLs for uploads/downloads, Lambda IAM role for processing)

**Path Structure**:
```
s3://kyc-documents-{env}/
  cases/
    {case_id}/
      documents/
        {document_id}/
          {original_filename}
          extracted_text.txt
          metadata.json
```

---

### Bucket 2: `kyc-audit-snapshots-{env}`

**Purpose**: Immutable approval/rejection snapshots

**Bucket Configuration**:
- **Versioning**: Enabled
- **Encryption**: AES-256 with KMS
- **Object Lock**: Enabled with Governance mode (cannot delete without elevated permissions)
- **Retention**: 7 years minimum (compliance mode)
- **Lifecycle Policy**: Transition to Glacier Deep Archive after 1 year

**Path Structure**:
```
s3://kyc-audit-snapshots-{env}/
  snapshots/
    {year}/
      {month}/
        {case_id}_{approval_timestamp}.json
```

**Snapshot JSON Structure**:
```json
{
  "snapshot_id": "uuid",
  "case_id": "uuid",
  "snapshot_type": "APPROVED",
  "approver": {
    "id": "uuid",
    "name": "Jane Doe",
    "email": "jane.doe@bank.com"
  },
  "approval_timestamp": "2025-11-12T16:45:00Z",
  "case": {...},
  "client": {...},
  "documents": [...],
  "screening": [...],
  "risk_assessment": {...},
  "sow_review": {...},
  "relationships": [...],
  "audit_trail": [...],
  "hash": "sha256:abcdef123456..."
}
```

---

## Data Retention & Archival

### Retention Policies

| Data Type | Hot Storage | Warm Storage | Cold Storage | Total Retention |
|-----------|-------------|--------------|--------------|-----------------|
| Active Cases | RDS | N/A | N/A | Until closed |
| Closed Cases (metadata) | RDS (1 year) | RDS (7 years) | Export to S3 Glacier (7+ years) | 7+ years |
| Documents (files) | S3 Standard (90 days) | S3 Standard-IA (1 year) | S3 Glacier (7+ years) | 7+ years |
| Audit Snapshots | S3 Standard (1 year) | S3 Glacier Deep Archive (7+ years) | N/A | 7+ years |
| Agent Sessions | DynamoDB (30 days) | Deleted (TTL) | N/A | 30 days |
| Logs | CloudWatch (30 days) | S3 (1 year) | S3 Glacier (7 years) | 7 years |

### Archival Process

1. **Monthly Job**: Export closed cases >12 months old to S3 (JSON + Parquet for analytics)
2. **Postgres Cleanup**: Delete closed case details after export (retain case_id, client_id, status, closed_at)
3. **S3 Lifecycle**: Automatic transition to Glacier Deep Archive
4. **Restore Process**: On-demand restore from Glacier (5-12 hours for standard retrieval)

---

## Indexes & Performance Optimization

### Composite Indexes (Query Patterns)

```sql
-- Dashboard: Open cases for officer, sorted by due date
CREATE INDEX idx_cases_dashboard ON cases(assigned_officer_id, status, due_date) 
WHERE status IN ('OPEN', 'UNDER_REVIEW', 'EDD_REQUIRED');

-- Search: Find cases by client name
CREATE INDEX idx_clients_name_trgm ON clients USING gin(legal_name gin_trgm_ops);

-- Audit: Recent events for case
CREATE INDEX idx_audit_case_recent ON audit_events(case_id, event_timestamp DESC);

-- Screening: Pending review items
CREATE INDEX idx_screening_pending ON screening_results(review_status, search_timestamp DESC)
WHERE review_status = 'PENDING';

-- Risk: High-risk cases requiring EDD
CREATE INDEX idx_risk_high ON risk_assessments(risk_level, computed_at DESC)
WHERE risk_level = 'HIGH' AND is_overridden = false;
```

### Database Performance Tuning

- **Connection Pooling**: RDS Proxy (max 100 connections per Lambda, prevents exhaustion)
- **Read Replicas**: 2 read replicas for reporting queries (avoid impacting OLTP workload)
- **Partitioning**: Partition `audit_events` by month (improve query performance for large tables)
- **VACUUM**: Automated VACUUM ANALYZE nightly (reclaim space, update statistics)

---

## Data Migration Scripts

### Initial Schema Deployment

```bash
# Apply Alembic migrations
cd backend
alembic upgrade head
```

### Seed Test Data

```python
# scripts/seed-test-data.py
from backend.src.models import User, Role, Case, Client
from backend.src.core.database import SessionLocal

def seed_roles():
    db = SessionLocal()
    roles = [
        Role(name="case_officer", permissions={"cases": ["read", "write"]}),
        Role(name="senior_officer", permissions={"cases": ["read", "write"], "approvals": ["execute"]}),
        Role(name="manager", permissions={"cases": ["read"], "reports": ["read"]}),
        Role(name="administrator", permissions={"*": ["*"]}),
    ]
    db.add_all(roles)
    db.commit()

def seed_test_user():
    db = SessionLocal()
    officer_role = db.query(Role).filter_by(name="case_officer").first()
    test_user = User(
        username="test_officer",
        email="test@example.com",
        password_hash=bcrypt.hash("TestPassword123!"),
        first_name="Test",
        last_name="Officer",
        role_id=officer_role.id
    )
    db.add(test_user)
    db.commit()
```

---

## Summary

This data model provides:
- **Transactional Integrity**: Postgres for ACID-critical KYC data
- **Scalability**: DynamoDB for high-throughput agent state
- **Auditability**: Complete audit trails with immutable snapshots
- **Performance**: Optimized indexes for dashboard and search queries
- **Compliance**: 7-year retention with automated lifecycle policies
- **Explainability**: Risk drivers, SOW analysis stored for regulatory review
- **Flexibility**: JSONB fields for evolving agent outputs without schema migrations

**Next Steps**: Generate OpenAPI contracts mapping these models to REST endpoints.
