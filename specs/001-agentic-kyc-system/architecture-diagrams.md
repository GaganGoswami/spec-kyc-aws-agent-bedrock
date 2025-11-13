# Architecture Diagrams: Agentic KYC System

**Feature**: 001-agentic-kyc-system  
**Version**: 1.0.0  
**Date**: 2025-11-12

This document contains comprehensive architecture and design diagrams for the AI-powered KYC system using Mermaid notation.

---

## Table of Contents

1. [System Context Diagram](#1-system-context-diagram)
2. [High-Level Architecture](#2-high-level-architecture)
3. [Component Architecture](#3-component-architecture)
4. [Data Flow Diagrams](#4-data-flow-diagrams)
5. [Agent Workflow Diagrams](#5-agent-workflow-diagrams)
6. [Database Schema Diagrams](#6-database-schema-diagrams)
7. [Deployment Architecture](#7-deployment-architecture)
8. [Sequence Diagrams](#8-sequence-diagrams)
9. [State Machine Diagrams](#9-state-machine-diagrams)
10. [Network Architecture](#10-network-architecture)

---

## 1. System Context Diagram

### 1.1 External Systems and Actors

```mermaid
graph TB
    subgraph "External Actors"
        CO[Case Officer]
        SO[Senior Officer]
        MGR[Manager]
        ADMIN[Administrator]
    end
    
    subgraph "KYC Agent System"
        SYS[KYC Platform]
    end
    
    subgraph "External Systems"
        SCREEN[Screening APIs<br/>Dow Jones, World-Check]
        REG[Corporate Registries<br/>Companies House, etc.]
        BEDROCK[AWS Bedrock<br/>Claude 3.5, Titan]
        TEXTRACT[AWS Textract<br/>OCR Service]
    end
    
    CO -->|Create cases, Upload docs| SYS
    SO -->|Review, Approve/Reject| SYS
    MGR -->|View reports, Audit| SYS
    ADMIN -->|Manage users, Config| SYS
    
    SYS -->|Sanctions/PEP checks| SCREEN
    SYS -->|Entity enrichment| REG
    SYS -->|LLM inference| BEDROCK
    SYS -->|Document OCR| TEXTRACT
    
    SCREEN -->|Match results| SYS
    REG -->|Company data| SYS
    BEDROCK -->|Risk scores, SOW analysis| SYS
    TEXTRACT -->|Extracted text| SYS
    
    style SYS fill:#4A90E2,stroke:#2E5C8A,stroke-width:3px,color:#fff
    style CO fill:#50C878,stroke:#2E7D4E,color:#fff
    style SO fill:#50C878,stroke:#2E7D4E,color:#fff
    style MGR fill:#50C878,stroke:#2E7D4E,color:#fff
    style ADMIN fill:#50C878,stroke:#2E7D4E,color:#fff
```

---

## 2. High-Level Architecture

### 2.1 Three-Tier Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[React Frontend<br/>TypeScript SPA]
        CDN[CloudFront CDN]
    end
    
    subgraph "Application Layer"
        APIGW[API Gateway<br/>REST + WebSocket]
        LAMBDA[Lambda Functions<br/>API Handlers]
        FARGATE[Fargate Containers<br/>Long-running Agents]
        SF[Step Functions<br/>Workflow Orchestration]
    end
    
    subgraph "Data Layer"
        RDS[(RDS Postgres<br/>Multi-AZ)]
        DDB[(DynamoDB<br/>Agent Sessions)]
        S3[(S3 Buckets<br/>Documents, Snapshots)]
    end
    
    subgraph "AI/ML Layer"
        BEDROCK[AWS Bedrock<br/>Claude + Titan]
        TEXTRACT[AWS Textract<br/>OCR]
    end
    
    subgraph "Integration Layer"
        SCREEN_API[Screening APIs]
        REG_API[Registry APIs]
    end
    
    UI --> CDN
    CDN --> APIGW
    APIGW --> LAMBDA
    APIGW --> FARGATE
    LAMBDA --> SF
    FARGATE --> SF
    
    LAMBDA --> RDS
    LAMBDA --> DDB
    LAMBDA --> S3
    FARGATE --> RDS
    FARGATE --> DDB
    FARGATE --> S3
    
    LAMBDA --> BEDROCK
    FARGATE --> BEDROCK
    LAMBDA --> TEXTRACT
    
    LAMBDA --> SCREEN_API
    FARGATE --> REG_API
    
    style UI fill:#61DAFB,stroke:#20232A,color:#20232A
    style LAMBDA fill:#FF9900,stroke:#CC7A00,color:#fff
    style FARGATE fill:#FF9900,stroke:#CC7A00,color:#fff
    style RDS fill:#527FFF,stroke:#3D5FCC,color:#fff
    style DDB fill:#527FFF,stroke:#3D5FCC,color:#fff
    style S3 fill:#569A31,stroke:#3D6B22,color:#fff
    style BEDROCK fill:#8B4789,stroke:#6B2F69,color:#fff
```

### 2.2 Microservices Architecture

```mermaid
graph LR
    subgraph "API Gateway Layer"
        APIGW[API Gateway]
    end
    
    subgraph "Agent Microservices"
        INTAKE[Intake Agent]
        DOC_INGEST[Document Ingest Agent]
        SCREENING[Screening Agent]
        ENTITY_RES[Entity Resolution Agent]
        ENRICH[Enrichment Agent]
        RISK[Risk Scoring Agent]
        SOW[SOW Review Agent]
        WORKFLOW[Workflow Agent]
        AUDIT[Audit Agent]
    end
    
    subgraph "Shared Services"
        AUTH[Auth Service]
        NOTIF[Notification Service]
        CACHE[Cache Service<br/>Redis]
    end
    
    subgraph "Data Stores"
        RDS[(Postgres)]
        DDB[(DynamoDB)]
        S3[(S3)]
    end
    
    APIGW --> INTAKE
    APIGW --> DOC_INGEST
    APIGW --> SCREENING
    APIGW --> ENTITY_RES
    APIGW --> ENRICH
    APIGW --> RISK
    APIGW --> SOW
    APIGW --> WORKFLOW
    
    INTAKE --> AUTH
    DOC_INGEST --> AUTH
    SCREENING --> AUTH
    ENTITY_RES --> AUTH
    ENRICH --> AUTH
    RISK --> AUTH
    SOW --> AUTH
    WORKFLOW --> AUTH
    
    INTAKE -.-> AUDIT
    DOC_INGEST -.-> AUDIT
    SCREENING -.-> AUDIT
    ENTITY_RES -.-> AUDIT
    ENRICH -.-> AUDIT
    RISK -.-> AUDIT
    SOW -.-> AUDIT
    WORKFLOW -.-> AUDIT
    
    WORKFLOW --> NOTIF
    
    INTAKE --> RDS
    DOC_INGEST --> S3
    SCREENING --> RDS
    ENTITY_RES --> RDS
    ENRICH --> RDS
    RISK --> RDS
    SOW --> RDS
    WORKFLOW --> DDB
    AUDIT --> RDS
    
    AUTH --> CACHE
    
    style APIGW fill:#FF6B35,stroke:#C54A23,color:#fff
    style INTAKE fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style DOC_INGEST fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style SCREENING fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style ENTITY_RES fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style ENRICH fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style RISK fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style SOW fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style WORKFLOW fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style AUDIT fill:#4ECDC4,stroke:#3AA39B,color:#fff
```

---

## 3. Component Architecture

### 3.1 Backend Component Diagram

```mermaid
graph TB
    subgraph "API Layer"
        ROUTES[FastAPI Routes<br/>/v1/cases, /v1/documents, etc.]
        WS[WebSocket Handler]
    end
    
    subgraph "Service Layer"
        CASE_SVC[CaseService]
        CLIENT_SVC[ClientService]
        DOC_SVC[DocumentService]
        SCREEN_SVC[ScreeningService]
        RISK_SVC[RiskService]
        SOW_SVC[SOWService]
        WORKFLOW_SVC[WorkflowService]
        AUDIT_SVC[AuditService]
    end
    
    subgraph "Agent Layer"
        AGENTS[LangGraph Agents<br/>Intake, Screening, Risk, SOW, etc.]
    end
    
    subgraph "Data Access Layer"
        MODELS[SQLAlchemy Models]
        REPOS[Repository Pattern]
    end
    
    subgraph "Integration Layer"
        BEDROCK_CLIENT[Bedrock Client]
        SCREEN_CLIENT[Screening API Client]
        REG_CLIENT[Registry API Client]
        TEXTRACT_CLIENT[Textract Client]
    end
    
    subgraph "Core Layer"
        AUTH[Authentication]
        CONFIG[Configuration]
        LOGGING[Logging & Tracing]
        VALIDATION[Pydantic Schemas]
    end
    
    ROUTES --> CASE_SVC
    ROUTES --> CLIENT_SVC
    ROUTES --> DOC_SVC
    ROUTES --> SCREEN_SVC
    ROUTES --> RISK_SVC
    ROUTES --> SOW_SVC
    ROUTES --> WORKFLOW_SVC
    
    WS --> WORKFLOW_SVC
    
    CASE_SVC --> AGENTS
    DOC_SVC --> AGENTS
    SCREEN_SVC --> AGENTS
    RISK_SVC --> AGENTS
    SOW_SVC --> AGENTS
    WORKFLOW_SVC --> AGENTS
    
    AGENTS --> BEDROCK_CLIENT
    AGENTS --> SCREEN_CLIENT
    AGENTS --> REG_CLIENT
    AGENTS --> TEXTRACT_CLIENT
    
    CASE_SVC --> REPOS
    CLIENT_SVC --> REPOS
    DOC_SVC --> REPOS
    SCREEN_SVC --> REPOS
    RISK_SVC --> REPOS
    SOW_SVC --> REPOS
    
    REPOS --> MODELS
    
    CASE_SVC -.-> AUDIT_SVC
    CLIENT_SVC -.-> AUDIT_SVC
    DOC_SVC -.-> AUDIT_SVC
    SCREEN_SVC -.-> AUDIT_SVC
    RISK_SVC -.-> AUDIT_SVC
    SOW_SVC -.-> AUDIT_SVC
    WORKFLOW_SVC -.-> AUDIT_SVC
    
    ROUTES --> AUTH
    ROUTES --> VALIDATION
    AGENTS --> LOGGING
    AGENTS --> CONFIG
    
    style ROUTES fill:#FF6B6B,stroke:#CC5656,color:#fff
    style CASE_SVC fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style AGENTS fill:#95E1D3,stroke:#6BB8A5,color:#333
    style BEDROCK_CLIENT fill:#8B4789,stroke:#6B2F69,color:#fff
```

### 3.2 Frontend Component Diagram

```mermaid
graph TB
    subgraph "Pages"
        DASHBOARD[Dashboard Page]
        CASE_LIST[Case List Page]
        CASE_DETAIL[Case Detail Page]
        LOGIN[Login Page]
    end
    
    subgraph "Components"
        CASE_CARD[CaseCard]
        DOC_UPLOAD[DocumentUpload]
        RISK_BADGE[RiskBadge]
        REL_GRAPH[RelationshipGraph<br/>D3.js]
        AUDIT_TIMELINE[AuditTimeline]
        APPROVAL_MODAL[ApprovalModal]
    end
    
    subgraph "State Management"
        QUERY[TanStack Query<br/>Server State]
        CONTEXT[React Context<br/>Auth, Theme]
    end
    
    subgraph "Services"
        API_CLIENT[API Client<br/>Axios]
        WS_CLIENT[WebSocket Client]
    end
    
    subgraph "Hooks"
        USE_CASE[useCases]
        USE_DOCS[useDocuments]
        USE_WS[useWebSocket]
        USE_AUTH[useAuth]
    end
    
    DASHBOARD --> CASE_CARD
    CASE_LIST --> CASE_CARD
    CASE_DETAIL --> DOC_UPLOAD
    CASE_DETAIL --> RISK_BADGE
    CASE_DETAIL --> REL_GRAPH
    CASE_DETAIL --> AUDIT_TIMELINE
    CASE_DETAIL --> APPROVAL_MODAL
    
    CASE_CARD --> USE_CASE
    DOC_UPLOAD --> USE_DOCS
    CASE_DETAIL --> USE_WS
    
    USE_CASE --> QUERY
    USE_DOCS --> QUERY
    USE_WS --> WS_CLIENT
    USE_AUTH --> CONTEXT
    
    QUERY --> API_CLIENT
    WS_CLIENT --> API_CLIENT
    
    LOGIN --> USE_AUTH
    
    style DASHBOARD fill:#61DAFB,stroke:#20232A,color:#20232A
    style CASE_DETAIL fill:#61DAFB,stroke:#20232A,color:#20232A
    style QUERY fill:#FF4154,stroke:#CC3443,color:#fff
    style API_CLIENT fill:#00C851,stroke:#007E33,color:#fff
```

---

## 4. Data Flow Diagrams

### 4.1 Case Creation Flow

```mermaid
flowchart TD
    START([User Creates Case]) --> VALIDATE[Validate Input<br/>Pydantic Schema]
    VALIDATE --> CHECK_DUP{Duplicate<br/>Client?}
    CHECK_DUP -->|Yes| LINK[Link to Existing Client]
    CHECK_DUP -->|No| CREATE_CLIENT[Create New Client]
    
    LINK --> CREATE_CASE[Create Case Record<br/>Status: OPEN]
    CREATE_CLIENT --> CREATE_CASE
    
    CREATE_CASE --> AUDIT_EVENT[Log Audit Event<br/>case_created]
    AUDIT_EVENT --> TRIGGER_INTAKE[Trigger Intake Agent]
    
    TRIGGER_INTAKE --> INTAKE_ANALYSIS[Agent: Analyze Client Data<br/>Extract entities, Check data quality]
    INTAKE_ANALYSIS --> SAVE_SESSION[Save Agent Session<br/>DynamoDB]
    SAVE_SESSION --> WS_NOTIFY[WebSocket Notify<br/>case.status_changed]
    
    WS_NOTIFY --> END([Case Created<br/>Return case_id])
    
    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
    style TRIGGER_INTAKE fill:#9C27B0,stroke:#7B1FA2,color:#fff
    style INTAKE_ANALYSIS fill:#9C27B0,stroke:#7B1FA2,color:#fff
```

### 4.2 Document Processing Flow

```mermaid
flowchart TD
    START([Document Upload]) --> UPLOAD_S3[Upload to S3<br/>Versioned bucket]
    UPLOAD_S3 --> HASH[Compute SHA-256 Hash]
    HASH --> SAVE_META[Save Document Metadata<br/>Postgres]
    
    SAVE_META --> TRIGGER_OCR[Trigger Lambda<br/>S3 Event Notification]
    TRIGGER_OCR --> TEXTRACT[AWS Textract<br/>OCR Processing]
    
    TEXTRACT --> EXTRACT_TEXT[Extract Text<br/>Confidence scores]
    EXTRACT_TEXT --> LLM_ENTITY[Bedrock Claude<br/>Extract entities<br/>name, DOB, IDs, etc.]
    
    LLM_ENTITY --> UPDATE_META[Update Document Metadata<br/>extracted_text, extracted_entities]
    UPDATE_META --> AUDIT[Log Audit Event<br/>document_uploaded]
    
    AUDIT --> WS_PROGRESS[WebSocket Notify<br/>document.processing_progress]
    WS_PROGRESS --> COMPLETE{Processing<br/>Complete?}
    
    COMPLETE -->|Yes| WS_COMPLETE[WebSocket Notify<br/>document.processing_completed]
    COMPLETE -->|Error| WS_FAILED[WebSocket Notify<br/>document.processing_failed]
    
    WS_COMPLETE --> END([Document Ready])
    WS_FAILED --> RETRY{Retry?}
    RETRY -->|Yes| TRIGGER_OCR
    RETRY -->|No| END
    
    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style TEXTRACT fill:#FF9800,stroke:#F57C00,color:#fff
    style LLM_ENTITY fill:#9C27B0,stroke:#7B1FA2,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
```

### 4.3 Screening Flow

```mermaid
flowchart TD
    START([Trigger Screening]) --> PREPARE[Prepare Search Query<br/>name, DOB, nationality, etc.]
    PREPARE --> PARALLEL{Screen Types}
    
    PARALLEL -->|Sanctions| SANCTIONS_API[Call Sanctions API<br/>OFAC, UN, EU lists]
    PARALLEL -->|PEP| PEP_API[Call PEP API<br/>Domestic, Foreign, IO]
    PARALLEL -->|Adverse Media| MEDIA_API[Call Adverse Media API<br/>News, Court records]
    
    SANCTIONS_API --> SANCTIONS_RESULT[Parse Results<br/>Match score, Evidence]
    PEP_API --> PEP_RESULT[Parse Results<br/>PEP category, Dates]
    MEDIA_API --> MEDIA_RESULT[Parse Results<br/>Articles, Dates]
    
    SANCTIONS_RESULT --> SAVE_RESULTS[Save Screening Results<br/>Postgres]
    PEP_RESULT --> SAVE_RESULTS
    MEDIA_RESULT --> SAVE_RESULTS
    
    SAVE_RESULTS --> EVALUATE{Any Hits?}
    EVALUATE -->|Yes| FLAG_REVIEW[Mark for Review<br/>review_status: PENDING]
    EVALUATE -->|No| AUTO_CLEAR[No hits found<br/>match_status: NO_HIT]
    
    FLAG_REVIEW --> WS_HIT[WebSocket Notify<br/>case.screening_completed<br/>requires_review: true]
    AUTO_CLEAR --> WS_CLEAR[WebSocket Notify<br/>case.screening_completed<br/>requires_review: false]
    
    WS_HIT --> END([Screening Complete])
    WS_CLEAR --> END
    
    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style SANCTIONS_API fill:#F44336,stroke:#D32F2F,color:#fff
    style PEP_API fill:#FF9800,stroke:#F57C00,color:#fff
    style MEDIA_API fill:#2196F3,stroke:#1976D2,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
```

### 4.4 Risk Assessment Flow

```mermaid
flowchart TD
    START([Compute Risk]) --> GATHER["Gather Data<br/>Client, Screening, Documents, SOW"]
    GATHER --> FEATURE_ENG["Feature Engineering<br/>PEP flag, Jurisdiction risk, etc."]

    FEATURE_ENG --> LLM_PROMPT["Prepare LLM Prompt<br/>Structured data + Instructions"]
    LLM_PROMPT --> BEDROCK["Bedrock Claude 3.5<br/>Risk scoring + Reasoning"]

    BEDROCK --> PARSE["Parse LLM Response<br/>Risk score (0-100)<br/>Risk drivers<br/>Rationale"]

    PARSE --> CLASSIFY{Risk Level}
    CLASSIFY -->|0-33| LOW["Risk Level: LOW"]
    CLASSIFY -->|34-66| MEDIUM["Risk Level: MEDIUM"]
    CLASSIFY -->|67-100| HIGH["Risk Level: HIGH"]

    LOW --> SAVE["Save Risk Assessment<br/>Postgres"]
    MEDIUM --> SAVE
    HIGH --> SAVE

    SAVE --> AUDIT["Log Audit Event<br/>risk_computed"]
    AUDIT --> WS_NOTIFY["WebSocket Notify<br/>case.risk_computed"]

    WS_NOTIFY --> CHECK_HIGH{Risk Level<br/>HIGH?}
    CHECK_HIGH -->|Yes| ESCALATE["Auto-transition to<br/>EDD_REQUIRED"]
    CHECK_HIGH -->|No| END([Risk Assessment Complete])

    ESCALATE --> WS_STATUS["WebSocket Notify<br/>case.status_changed"]
    WS_STATUS --> END

    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style BEDROCK fill:#9C27B0,stroke:#7B1FA2,color:#fff
    style HIGH fill:#F44336,stroke:#D32F2F,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
```

---

## 5. Agent Workflow Diagrams

### 5.1 LangGraph Agent State Machine

```mermaid
stateDiagram-v2
    [*] --> Initialize
    Initialize --> GatherContext: Load case data
    GatherContext --> ExecuteTools: Call external APIs
    ExecuteTools --> LLMReasoning: Bedrock inference
    LLMReasoning --> ParseResponse: Extract structured output
    ParseResponse --> ValidateOutput: Schema validation
    
    ValidateOutput --> SaveResults: Valid
    ValidateOutput --> ErrorHandling: Invalid
    
    SaveResults --> AuditLog: Record execution
    AuditLog --> [*]: Complete
    
    ErrorHandling --> Retry: Retryable error
    ErrorHandling --> FailureLog: Non-retryable
    FailureLog --> [*]: Failed
    
    Retry --> ExecuteTools: Attempt < 3
    Retry --> FailureLog: Max retries
    
    note right of LLMReasoning
        Claude 3.5 Sonnet
        Temperature: 0.2
        Max tokens: 4096
    end note
```

### 5.2 Entity Resolution Agent Workflow

```mermaid
flowchart TD
    START([Entity Resolution Triggered]) --> LOAD[Load Client Data<br/>Primary + Related Parties]
    LOAD --> FUZZY[Fuzzy Name Matching<br/>pg_trgm similarity]
    
    FUZZY --> CANDIDATES[Identify Candidate Matches<br/>similarity > 0.8]
    CANDIDATES --> CHECK{Candidates<br/>Found?}
    
    CHECK -->|No| NO_MATCH[No duplicates]
    CHECK -->|Yes| COMPARE[Compare Attributes<br/>DOB ±1 year, Nationality, IDs]
    
    COMPARE --> SCORE[Calculate Match Score<br/>Weighted algorithm]
    SCORE --> THRESHOLD{Score > 0.9?}
    
    THRESHOLD -->|Yes| HIGH_CONF[High Confidence Match]
    THRESHOLD -->|No| LOW_CONF[Potential Match<br/>Manual review needed]
    
    HIGH_CONF --> AUTO_LINK[Auto-link Entities<br/>Create relationship record]
    LOW_CONF --> FLAG[Flag for Human Review]
    
    AUTO_LINK --> REGISTRY[Enrich from Registry<br/>Corporate data, UBOs]
    FLAG --> REGISTRY
    NO_MATCH --> REGISTRY
    
    REGISTRY --> GRAPH[Update Relationship Graph<br/>Ownership, Control, Family]
    GRAPH --> END([Resolution Complete])
    
    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style HIGH_CONF fill:#8BC34A,stroke:#689F38,color:#fff
    style LOW_CONF fill:#FF9800,stroke:#F57C00,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
```

### 5.3 Source of Wealth Review Agent

```mermaid
flowchart TD
    START([SOW Review Triggered]) --> EXTRACT[Extract SOW Claims<br/>From documents + client data]
    EXTRACT --> CLAIMED[Identify Claimed Sources<br/>Inheritance, Business sale, etc.]
    
    CLAIMED --> LLM_PROMPT[Prepare LLM Prompt<br/>Claims + Supporting docs]
    LLM_PROMPT --> BEDROCK[Bedrock Claude 3.5<br/>Analyze consistency]
    
    BEDROCK --> PARSE[Parse LLM Response<br/>Summary, Gaps, Recommendations]
    PARSE --> CONSISTENCY[Consistency Analysis<br/>Align claims with evidence]
    
    CONSISTENCY --> GAPS{Gaps<br/>Identified?}
    GAPS -->|Yes| MAJOR{Major gaps?}
    GAPS -->|No| HIGH_CONF[High Confidence<br/>Evidence supports claims]
    
    MAJOR -->|Yes| LOW_CONF[Low Confidence<br/>Significant gaps]
    MAJOR -->|No| MEDIUM_CONF[Medium Confidence<br/>Minor gaps]
    
    LOW_CONF --> FLAG_EDD[Flag for EDD<br/>requires_further_review: true]
    MEDIUM_CONF --> RECOMMEND[Generate Recommendations<br/>Additional documents needed]
    HIGH_CONF --> CLEAR[No further action]
    
    FLAG_EDD --> SAVE[Save SOW Review<br/>Postgres]
    RECOMMEND --> SAVE
    CLEAR --> SAVE
    
    SAVE --> AUDIT[Log Audit Event<br/>sow_reviewed]
    AUDIT --> WS[WebSocket Notify<br/>case.sow_reviewed]
    WS --> END([SOW Review Complete])
    
    style START fill:#4CAF50,stroke:#388E3C,color:#fff
    style BEDROCK fill:#9C27B0,stroke:#7B1FA2,color:#fff
    style LOW_CONF fill:#F44336,stroke:#D32F2F,color:#fff
    style HIGH_CONF fill:#8BC34A,stroke:#689F38,color:#fff
    style END fill:#4CAF50,stroke:#388E3C,color:#fff
```

---

## 6. Database Schema Diagrams

### 6.1 Core Entity Relationships

```mermaid
erDiagram
    USERS ||--o{ CASES : "assigned_to"
    USERS ||--o{ CASES : "reviews"
    USERS }o--|| ROLES : "has"
    
    CASES ||--|| CLIENTS : "belongs_to"
    CASES ||--o{ DOCUMENTS : "contains"
    CASES ||--o{ SCREENING_RESULTS : "has"
    CASES ||--o{ RISK_ASSESSMENTS : "has"
    CASES ||--o{ SOW_REVIEWS : "has"
    CASES ||--o{ AGENT_INVOCATIONS : "tracks"
    CASES ||--o{ AUDIT_EVENTS : "records"
    CASES ||--o{ APPROVAL_SNAPSHOTS : "creates"
    
    CLIENTS ||--o{ RELATED_PARTIES : "has"
    CLIENTS ||--o{ ENTITY_RELATIONSHIPS : "source"
    CLIENTS ||--o{ ENTITY_RELATIONSHIPS : "target"
    
    USERS {
        uuid id PK
        varchar username UK
        varchar email UK
        varchar password_hash
        uuid role_id FK
        boolean is_active
        timestamp created_at
    }
    
    ROLES {
        uuid id PK
        varchar name UK
        jsonb permissions
    }
    
    CASES {
        uuid id PK
        varchar case_number UK
        uuid client_id FK
        varchar status
        uuid assigned_officer_id FK
        uuid assigned_reviewer_id FK
        date due_date
        timestamp opened_at
    }
    
    CLIENTS {
        uuid id PK
        varchar client_type
        varchar legal_name
        date date_of_birth
        varchar nationality
        boolean is_pep
        boolean is_high_net_worth
        decimal estimated_net_worth_usd
    }
    
    DOCUMENTS {
        uuid id PK
        uuid case_id FK
        varchar document_type
        varchar s3_key
        varchar content_hash
        text extracted_text
        jsonb extracted_entities
    }
    
    SCREENING_RESULTS {
        uuid id PK
        uuid case_id FK
        uuid client_id FK
        varchar screening_type
        varchar match_status
        jsonb matches
        varchar review_status
    }
    
    RISK_ASSESSMENTS {
        uuid id PK
        uuid case_id FK
        uuid client_id FK
        int risk_score
        varchar risk_level
        jsonb risk_drivers
        text rationale_text
    }
```

### 6.2 Audit and Compliance Schema

```mermaid
erDiagram
    CASES ||--o{ AUDIT_EVENTS : "generates"
    CASES ||--o{ AGENT_INVOCATIONS : "executes"
    CASES ||--o{ APPROVAL_SNAPSHOTS : "finalizes"
    
    USERS ||--o{ AUDIT_EVENTS : "performs"
    USERS ||--o{ APPROVAL_SNAPSHOTS : "approves"
    
    AUDIT_EVENTS {
        uuid id PK
        varchar event_type
        uuid case_id FK
        uuid client_id FK
        varchar actor_type
        uuid actor_id FK
        text description
        jsonb before_value
        jsonb after_value
        jsonb metadata
        timestamp event_timestamp
    }
    
    AGENT_INVOCATIONS {
        uuid id PK
        uuid case_id FK
        varchar agent_type
        jsonb input_parameters
        jsonb output_results
        decimal confidence_score
        varchar model_identifier
        jsonb tool_calls
        int execution_duration_ms
        varchar status
    }
    
    APPROVAL_SNAPSHOTS {
        uuid id PK
        uuid case_id FK
        varchar snapshot_type
        uuid approver_id FK
        timestamp approval_timestamp
        text decision_rationale
        jsonb case_data
        jsonb client_data
        jsonb documents
        jsonb screening_results
        jsonb risk_assessment
        varchar snapshot_hash
        varchar s3_backup_key
    }
```

### 6.3 DynamoDB Table Design

```mermaid
graph TB
    subgraph "AgentSessions Table"
        PK1[PK: session_id]
        ATTR1[Attributes:<br/>case_id, agent_type, status,<br/>current_step, state, conversation_history]
        GSI1[GSI1: case_id + status]
        GSI2[GSI2: status + last_updated_at]
        TTL1[TTL: 30 days]
    end
    
    subgraph "EmbeddingsStore Table"
        PK2[PK: embedding_id]
        ATTR2[Attributes:<br/>entity_type, entity_id,<br/>embedding_vector[1536], text_content]
        GSI3[GSI1: entity_type + entity_id]
    end
    
    PK1 --> ATTR1
    ATTR1 --> GSI1
    ATTR1 --> GSI2
    ATTR1 --> TTL1
    
    PK2 --> ATTR2
    ATTR2 --> GSI3
    
    style PK1 fill:#FF9900,stroke:#CC7A00,color:#fff
    style PK2 fill:#FF9900,stroke:#CC7A00,color:#fff
    style GSI1 fill:#527FFF,stroke:#3D5FCC,color:#fff
    style GSI2 fill:#527FFF,stroke:#3D5FCC,color:#fff
    style GSI3 fill:#527FFF,stroke:#3D5FCC,color:#fff
```

---

## 7. Deployment Architecture

### 7.1 AWS Infrastructure

```mermaid
graph TB
    subgraph "Users"
        USERS[Compliance Officers<br/>Browsers]
    end
    
    subgraph "Edge"
        R53[Route 53<br/>DNS]
        CF[CloudFront<br/>CDN]
        WAF[AWS WAF<br/>Firewall]
    end
    
    subgraph "Public Subnets"
        ALB[Application Load Balancer]
        NATGW[NAT Gateway]
    end
    
    subgraph "Private Subnets - AZ1"
        LAMBDA1[Lambda Functions]
        FARGATE1[Fargate Tasks]
        RDS1[RDS Primary]
    end
    
    subgraph "Private Subnets - AZ2"
        LAMBDA2[Lambda Functions]
        FARGATE2[Fargate Tasks]
        RDS2[RDS Standby]
    end
    
    subgraph "Data Layer"
        DDB[DynamoDB]
        S3_DOCS[S3 Documents]
        S3_SNAP[S3 Snapshots]
    end
    
    subgraph "AWS Services"
        BEDROCK[Bedrock]
        TEXTRACT[Textract]
        XRAY[X-Ray]
        CW[CloudWatch]
        SM[Secrets Manager]
    end
    
    USERS --> R53
    R53 --> WAF
    WAF --> CF
    CF --> ALB
    
    ALB --> LAMBDA1
    ALB --> LAMBDA2
    ALB --> FARGATE1
    ALB --> FARGATE2
    
    LAMBDA1 --> RDS1
    LAMBDA2 --> RDS2
    FARGATE1 --> RDS1
    FARGATE2 --> RDS2
    
    RDS1 -.Replication.-> RDS2
    
    LAMBDA1 --> DDB
    LAMBDA2 --> DDB
    FARGATE1 --> DDB
    FARGATE2 --> DDB
    
    LAMBDA1 --> S3_DOCS
    LAMBDA2 --> S3_DOCS
    FARGATE1 --> S3_SNAP
    FARGATE2 --> S3_SNAP
    
    LAMBDA1 --> BEDROCK
    LAMBDA2 --> BEDROCK
    FARGATE1 --> BEDROCK
    FARGATE2 --> BEDROCK
    
    LAMBDA1 --> TEXTRACT
    LAMBDA2 --> TEXTRACT
    
    LAMBDA1 -.-> NATGW
    LAMBDA2 -.-> NATGW
    FARGATE1 -.-> NATGW
    FARGATE2 -.-> NATGW
    
    NATGW -.External APIs.-> Internet((Internet))
    
    LAMBDA1 -.Traces.-> XRAY
    LAMBDA2 -.Traces.-> XRAY
    FARGATE1 -.Traces.-> XRAY
    FARGATE2 -.Traces.-> XRAY
    
    LAMBDA1 -.Logs/Metrics.-> CW
    LAMBDA2 -.Logs/Metrics.-> CW
    FARGATE1 -.Logs/Metrics.-> CW
    FARGATE2 -.Logs/Metrics.-> CW
    
    LAMBDA1 --> SM
    LAMBDA2 --> SM
    FARGATE1 --> SM
    FARGATE2 --> SM
    
    style USERS fill:#50C878,stroke:#2E7D4E,color:#fff
    style CF fill:#FF9900,stroke:#CC7A00,color:#fff
    style ALB fill:#FF6B35,stroke:#C54A23,color:#fff
    style LAMBDA1 fill:#FF9900,stroke:#CC7A00,color:#fff
    style LAMBDA2 fill:#FF9900,stroke:#CC7A00,color:#fff
    style FARGATE1 fill:#FF9900,stroke:#CC7A00,color:#fff
    style FARGATE2 fill:#FF9900,stroke:#CC7A00,color:#fff
    style RDS1 fill:#527FFF,stroke:#3D5FCC,color:#fff
    style RDS2 fill:#527FFF,stroke:#3D5FCC,color:#fff
    style DDB fill:#527FFF,stroke:#3D5FCC,color:#fff
    style BEDROCK fill:#8B4789,stroke:#6B2F69,color:#fff
```

### 7.2 Multi-Environment Deployment

```mermaid
graph LR
    subgraph "GitHub Repository"
        CODE[Source Code]
        TESTS[Tests]
        CDK[CDK Stacks]
    end
    
    subgraph "CI/CD Pipeline"
        GH_ACTIONS[GitHub Actions]
        BUILD[Build & Test]
        SCAN[Security Scan]
    end
    
    subgraph "Dev Environment"
        DEV_VPC[VPC]
        DEV_RDS[(RDS)]
        DEV_LAMBDA[Lambda]
    end
    
    subgraph "Staging Environment"
        STG_VPC[VPC]
        STG_RDS[(RDS)]
        STG_LAMBDA[Lambda]
        STG_SMOKE[Smoke Tests]
    end
    
    subgraph "Production Environment"
        PROD_VPC[VPC]
        PROD_RDS[(RDS Multi-AZ)]
        PROD_LAMBDA[Lambda]
        PROD_MONITOR[Monitoring]
    end
    
    CODE --> GH_ACTIONS
    TESTS --> GH_ACTIONS
    CDK --> GH_ACTIONS
    
    GH_ACTIONS --> BUILD
    BUILD --> SCAN
    
    SCAN -->|Auto Deploy| DEV_VPC
    DEV_VPC --> DEV_RDS
    DEV_VPC --> DEV_LAMBDA
    
    DEV_LAMBDA -->|Manual Approval| STG_VPC
    STG_VPC --> STG_RDS
    STG_VPC --> STG_LAMBDA
    STG_LAMBDA --> STG_SMOKE
    
    STG_SMOKE -->|Manual Approval| PROD_VPC
    PROD_VPC --> PROD_RDS
    PROD_VPC --> PROD_LAMBDA
    PROD_LAMBDA --> PROD_MONITOR
    
    style CODE fill:#4A90E2,stroke:#2E5C8A,color:#fff
    style GH_ACTIONS fill:#2088FF,stroke:#1566BF,color:#fff
    style DEV_VPC fill:#4CAF50,stroke:#388E3C,color:#fff
    style STG_VPC fill:#FF9800,stroke:#F57C00,color:#fff
    style PROD_VPC fill:#F44336,stroke:#D32F2F,color:#fff
```

---

## 8. Sequence Diagrams

### 8.1 Case Approval Sequence

```mermaid
sequenceDiagram
    actor Officer as Senior Officer
    participant UI as React Frontend
    participant API as API Gateway
    participant Lambda as Approval Lambda
    participant RDS as Postgres
    participant S3 as S3 Snapshots
    participant WS as WebSocket
    participant Audit as Audit Service
    
    Officer->>UI: Click "Approve Case"
    UI->>Officer: Show approval modal
    Officer->>UI: Enter rationale
    UI->>API: POST /cases/{id}/approve
    
    API->>Lambda: Validate JWT token
    Lambda->>RDS: Load complete case data
    RDS-->>Lambda: Case + Client + Docs + Screening + Risk
    
    Lambda->>Lambda: Validate approval<br/>(All checks passed?)
    
    alt Validation Failed
        Lambda-->>API: 400 Bad Request
        API-->>UI: Show error
    else Validation Passed
        Lambda->>RDS: BEGIN TRANSACTION
        Lambda->>RDS: UPDATE cases<br/>SET status='APPROVED'
        
        Lambda->>Lambda: Generate snapshot JSON<br/>(Complete case state)
        Lambda->>Lambda: Compute SHA-256 hash
        
        Lambda->>S3: PUT snapshot file<br/>(Object Lock enabled)
        S3-->>Lambda: S3 key
        
        Lambda->>RDS: INSERT approval_snapshot
        Lambda->>RDS: COMMIT TRANSACTION
        
        Lambda->>Audit: Log audit_event<br/>(case_approved)
        Lambda->>WS: Notify subscribers<br/>(case.approved)
        
        Lambda-->>API: 200 OK + snapshot_id
        API-->>UI: Success response
        UI->>Officer: Show success message
        
        WS-->>UI: Real-time update
        UI->>UI: Refresh case details
    end
```

### 8.2 Document Upload and Processing

```mermaid
sequenceDiagram
    actor Officer as Case Officer
    participant UI as React Frontend
    participant API as API Gateway
    participant Lambda as Upload Lambda
    participant S3 as S3 Documents
    participant EventBridge as EventBridge
    participant OCR as OCR Lambda
    participant Textract as AWS Textract
    participant Bedrock as AWS Bedrock
    participant RDS as Postgres
    participant WS as WebSocket
    
    Officer->>UI: Select file + document type
    UI->>API: POST /cases/{id}/documents<br/>(multipart/form-data)
    
    API->>Lambda: Forward request
    Lambda->>Lambda: Validate file<br/>(type, size, hash)
    
    Lambda->>S3: PUT file<br/>(with versioning)
    S3-->>Lambda: S3 key + version_id
    
    Lambda->>RDS: INSERT document metadata
    Lambda->>WS: Notify<br/>(document.uploaded)
    Lambda-->>API: 201 Created + document_id
    API-->>UI: Success
    
    S3->>EventBridge: S3 Event Notification
    EventBridge->>OCR: Trigger processing
    
    OCR->>WS: Notify<br/>(document.processing_started)
    OCR->>Textract: Start document analysis
    
    loop Pages
        Textract-->>OCR: Page text + confidence
        OCR->>WS: Notify<br/>(document.processing_progress)
    end
    
    OCR->>OCR: Combine extracted text
    OCR->>Bedrock: Extract entities<br/>(name, DOB, IDs)
    Bedrock-->>OCR: Structured entities + confidence
    
    OCR->>RDS: UPDATE document<br/>SET extracted_text, extracted_entities
    OCR->>WS: Notify<br/>(document.processing_completed)
    
    WS-->>UI: Real-time update
    UI->>UI: Show extracted data
```

### 8.3 WebSocket Connection and Subscription

```mermaid
sequenceDiagram
    actor User as User
    participant UI as React Frontend
    participant APIGW as API Gateway WebSocket
    participant Lambda as Connection Lambda
    participant DDB as DynamoDB Connections
    participant Auth as Auth Service
    
    User->>UI: Login successful
    UI->>UI: Store JWT token
    UI->>APIGW: Connect WebSocket<br/>ws://...?token={jwt}
    
    APIGW->>Lambda: $connect
    Lambda->>Auth: Validate JWT
    Auth-->>Lambda: User ID + Permissions
    
    Lambda->>DDB: Store connection<br/>(connection_id, user_id)
    Lambda-->>APIGW: 200 OK
    APIGW-->>UI: Connection established
    
    UI->>APIGW: Send message<br/>{"type":"subscribe","channel":"case.123"}
    APIGW->>Lambda: Process message
    
    Lambda->>Auth: Check permission<br/>(can read case 123?)
    Auth-->>Lambda: Authorized
    
    Lambda->>DDB: Add subscription<br/>(connection_id, channel)
    Lambda->>APIGW: Send ACK<br/>{"type":"ack","status":"success"}
    APIGW->>UI: ACK received
    
    Note over Lambda,DDB: Case status changes...
    
    Lambda->>DDB: Query subscriptions<br/>(channel="case.123")
    DDB-->>Lambda: [connection_ids]
    
    loop Each connection
        Lambda->>APIGW: Post to connection<br/>{"type":"event","event_name":"case.status_changed"}
        APIGW->>UI: Push event
    end
    
    UI->>UI: Update UI (status badge)
```

---

## 9. State Machine Diagrams

### 9.1 Case Status State Machine

```mermaid
stateDiagram-v2
    [*] --> OPEN: Case created
    
    OPEN --> UNDER_REVIEW: Officer starts review
    UNDER_REVIEW --> EDD_REQUIRED: High risk detected
    UNDER_REVIEW --> APPROVED: Senior Officer approves
    UNDER_REVIEW --> REJECTED: Senior Officer rejects
    
    EDD_REQUIRED --> UNDER_REVIEW: Additional docs submitted
    EDD_REQUIRED --> REJECTED: Cannot satisfy EDD
    
    APPROVED --> CLOSED: Case finalized
    REJECTED --> CLOSED: Case finalized
    
    CLOSED --> [*]
    
    note right of OPEN
        Initial state
        Documents can be uploaded
        Screening can be triggered
    end note
    
    note right of UNDER_REVIEW
        Assigned to reviewer
        Risk assessment computed
        SOW review generated
    end note
    
    note right of EDD_REQUIRED
        Enhanced Due Diligence
        Additional documentation required
        Manual investigation
    end note
    
    note right of APPROVED
        Creates immutable snapshot
        S3 Object Lock enabled
        7-year retention
    end note
```

### 9.2 Document Processing State Machine

```mermaid
stateDiagram-v2
    [*] --> UPLOADED: File uploaded to S3
    
    UPLOADED --> PROCESSING: Lambda triggered
    PROCESSING --> OCR_IN_PROGRESS: Textract started
    
    OCR_IN_PROGRESS --> EXTRACTING: Text extraction complete
    EXTRACTING --> ENTITY_EXTRACTION: LLM entity extraction
    
    ENTITY_EXTRACTION --> COMPLETED: Success
    ENTITY_EXTRACTION --> FAILED: Error
    
    FAILED --> RETRY: Retryable error
    RETRY --> PROCESSING: Attempt < 3
    RETRY --> PERMANENTLY_FAILED: Max retries
    
    COMPLETED --> [*]
    PERMANENTLY_FAILED --> [*]
    
    note right of PROCESSING
        WebSocket: processing_started
        Progress: 0%
    end note
    
    note right of OCR_IN_PROGRESS
        WebSocket: processing_progress
        Progress: 10-50%
    end note
    
    note right of ENTITY_EXTRACTION
        WebSocket: processing_progress
        Progress: 50-90%
    end note
    
    note right of COMPLETED
        WebSocket: processing_completed
        Progress: 100%
        extracted_text and entities saved
    end note
```

### 9.3 Screening Review State Machine

```mermaid
stateDiagram-v2
    [*] --> PENDING: Screening results received
    
    PENDING --> CONFIRMED: Officer confirms true positive
    PENDING --> FALSE_POSITIVE: Officer confirms false positive
    PENDING --> NEEDS_INVESTIGATION: Unclear, needs research
    
    NEEDS_INVESTIGATION --> CONFIRMED: Investigation confirms match
    NEEDS_INVESTIGATION --> FALSE_POSITIVE: Investigation clears
    
    CONFIRMED --> EDD_TRIGGERED: Auto-escalate case
    FALSE_POSITIVE --> CLEARED: No action needed
    
    EDD_TRIGGERED --> [*]
    CLEARED --> [*]
    
    note right of PENDING
        Requires human review
        Match score available
        Evidence URLs provided
    end note
    
    note right of CONFIRMED
        True positive match
        Triggers case escalation
        Logged in audit trail
    end note
    
    note right of FALSE_POSITIVE
        Not a real match
        Common name, etc.
        Rationale documented
    end note
```

---

## 10. Network Architecture

### 10.1 VPC Design

```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "VPC 10.0.0.0/16"
            subgraph "Public Subnets"
                PUB_AZ1[Public Subnet AZ1<br/>10.0.1.0/24]
                PUB_AZ2[Public Subnet AZ2<br/>10.0.2.0/24]
                
                ALB[Application Load Balancer]
                NAT1[NAT Gateway AZ1]
                NAT2[NAT Gateway AZ2]
            end
            
            subgraph "Private Subnets - App Tier"
                PRIV_APP_AZ1[Private App AZ1<br/>10.0.10.0/24]
                PRIV_APP_AZ2[Private App AZ2<br/>10.0.11.0/24]
                
                LAMBDA1[Lambda Functions]
                LAMBDA2[Lambda Functions]
                FARGATE1[Fargate Tasks]
                FARGATE2[Fargate Tasks]
            end
            
            subgraph "Private Subnets - Data Tier"
                PRIV_DATA_AZ1[Private Data AZ1<br/>10.0.20.0/24]
                PRIV_DATA_AZ2[Private Data AZ2<br/>10.0.21.0/24]
                
                RDS_PRIMARY[(RDS Primary)]
                RDS_STANDBY[(RDS Standby)]
            end
        end
        
        IGW[Internet Gateway]
        
        subgraph "VPC Endpoints"
            S3_EP[S3 Gateway Endpoint]
            DDB_EP[DynamoDB Gateway Endpoint]
            BEDROCK_EP[Bedrock Interface Endpoint]
            SM_EP[Secrets Manager Endpoint]
        end
    end
    
    Internet((Internet)) --> IGW
    IGW --> PUB_AZ1
    IGW --> PUB_AZ2
    
    PUB_AZ1 --> ALB
    PUB_AZ2 --> ALB
    PUB_AZ1 --> NAT1
    PUB_AZ2 --> NAT2
    
    ALB --> PRIV_APP_AZ1
    ALB --> PRIV_APP_AZ2
    
    PRIV_APP_AZ1 --> LAMBDA1
    PRIV_APP_AZ1 --> FARGATE1
    PRIV_APP_AZ2 --> LAMBDA2
    PRIV_APP_AZ2 --> FARGATE2
    
    LAMBDA1 --> NAT1
    LAMBDA2 --> NAT2
    FARGATE1 --> NAT1
    FARGATE2 --> NAT2
    
    LAMBDA1 --> PRIV_DATA_AZ1
    LAMBDA2 --> PRIV_DATA_AZ2
    FARGATE1 --> PRIV_DATA_AZ1
    FARGATE2 --> PRIV_DATA_AZ2
    
    PRIV_DATA_AZ1 --> RDS_PRIMARY
    PRIV_DATA_AZ2 --> RDS_STANDBY
    
    RDS_PRIMARY -.Sync Replication.-> RDS_STANDBY
    
    LAMBDA1 --> S3_EP
    LAMBDA2 --> S3_EP
    LAMBDA1 --> DDB_EP
    LAMBDA2 --> DDB_EP
    LAMBDA1 --> BEDROCK_EP
    LAMBDA2 --> BEDROCK_EP
    LAMBDA1 --> SM_EP
    LAMBDA2 --> SM_EP
    
    style PUB_AZ1 fill:#FFE5B4,stroke:#FFA500,color:#333
    style PUB_AZ2 fill:#FFE5B4,stroke:#FFA500,color:#333
    style PRIV_APP_AZ1 fill:#B4D7FF,stroke:#4A90E2,color:#333
    style PRIV_APP_AZ2 fill:#B4D7FF,stroke:#4A90E2,color:#333
    style PRIV_DATA_AZ1 fill:#D4EDDA,stroke:#28A745,color:#333
    style PRIV_DATA_AZ2 fill:#D4EDDA,stroke:#28A745,color:#333
```

### 10.2 Security Groups

```mermaid
graph TB
    subgraph "Security Groups"
        SG_ALB[ALB Security Group<br/>Ingress: 443 from Internet<br/>Egress: All to App SG]
        
        SG_APP[Application Security Group<br/>Ingress: 8000 from ALB SG<br/>Egress: All to Data SG, VPC Endpoints]
        
        SG_DATA[Database Security Group<br/>Ingress: 5432 from App SG<br/>Egress: None]
        
        SG_VPC_EP[VPC Endpoint Security Group<br/>Ingress: 443 from App SG<br/>Egress: None]
    end
    
    Internet((Internet)) -->|HTTPS 443| SG_ALB
    SG_ALB -->|HTTP 8000| SG_APP
    SG_APP -->|PostgreSQL 5432| SG_DATA
    SG_APP -->|HTTPS 443| SG_VPC_EP
    
    style SG_ALB fill:#FF6B6B,stroke:#CC5656,color:#fff
    style SG_APP fill:#4ECDC4,stroke:#3AA39B,color:#fff
    style SG_DATA fill:#95E1D3,stroke:#6BB8A5,color:#333
    style SG_VPC_EP fill:#F38181,stroke:#C25E5E,color:#fff
```

### 10.3 Data Flow Security

```mermaid
flowchart LR
    subgraph "Edge Security"
        WAF[AWS WAF<br/>Rate limiting, SQL injection, XSS]
        SHIELD[AWS Shield<br/>DDoS protection]
    end
    
    subgraph "Application Security"
        JWT[JWT Validation<br/>HMAC-SHA256]
        RBAC[Role-Based Access Control<br/>4 roles, granular permissions]
        RATE[Rate Limiting<br/>API Gateway throttling]
    end
    
    subgraph "Data Security"
        ENC_TRANSIT[TLS 1.3<br/>In-transit encryption]
        ENC_REST[KMS Encryption<br/>At-rest encryption]
        MASKING[PII Masking<br/>Log redaction]
    end
    
    subgraph "Secrets Management"
        SM[Secrets Manager<br/>Auto-rotation]
        IAM[IAM Roles<br/>Least privilege]
    end
    
    WAF --> JWT
    SHIELD --> JWT
    JWT --> RBAC
    RBAC --> RATE
    
    RATE --> ENC_TRANSIT
    ENC_TRANSIT --> ENC_REST
    ENC_REST --> MASKING
    
    JWT -.Uses.-> SM
    RBAC -.Enforced by.-> IAM
    
    style WAF fill:#F44336,stroke:#D32F2F,color:#fff
    style JWT fill:#4CAF50,stroke:#388E3C,color:#fff
    style ENC_TRANSIT fill:#2196F3,stroke:#1976D2,color:#fff
    style ENC_REST fill:#9C27B0,stroke:#7B1FA2,color:#fff
    style SM fill:#FF9800,stroke:#F57C00,color:#fff
```

---

## Summary

This document provides comprehensive visual documentation of the KYC Agent System architecture across multiple dimensions:

- **System Context**: External actors, systems, and integrations
- **Architecture**: Three-tier, microservices, component diagrams
- **Data Flow**: Case creation, document processing, screening, risk assessment
- **Agent Workflows**: LangGraph state machines, entity resolution, SOW review
- **Database**: ER diagrams, schema relationships, DynamoDB design
- **Deployment**: AWS infrastructure, multi-environment CI/CD
- **Sequences**: Approval flows, document processing, WebSocket subscriptions
- **State Machines**: Case status, document processing, screening review
- **Network**: VPC design, security groups, data flow security

**Usage**: Reference these diagrams during:
- Architecture reviews
- Technical onboarding
- System design discussions
- Troubleshooting and debugging
- Documentation updates
- Stakeholder presentations

**Maintenance**: Update diagrams when:
- Adding new microservices
- Changing data flows
- Modifying infrastructure
- Introducing new integrations
- Refactoring components

---

**Last Updated**: 2025-11-12  
**Version**: 1.0.0  
**Branch**: `001-agentic-kyc-system`
