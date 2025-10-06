# Federated Imputation - Simple Architecture

## High-Level Conceptual View (Like Your Whiteboard)

```mermaid
graph TB
    subgraph AZURE["☁️ AZURE"]
        DNS[DNAstack<br/>DRS/WesKIT]
        AZ_DOCKER[Docker]
        DNS --> AZ_DOCKER
    end

    subgraph MALI["🏢 ON-PREM MALI"]
        MALI_DRS[DRS]
        MALI_WES[WesKIT]
        MALI_NF[NEXTFLOW<br/>Docker]
        MALI_DRS --> MALI_NF
        MALI_WES --> MALI_NF
    end

    subgraph ILIFU["🏢 ON-PREM ILIFU"]
        ILIFU_DRS[DRS/WesKIT?]
        ILIFU_ATT[Attestation<br/>☑️ Tasks<br/>☑️ Data Connect<br/>DATA SPA]
        ILIFU_DRS --> ILIFU_ATT
    end

    subgraph CENTRAL["🖥️ CENTRAL UI"]
        UI[User Interface<br/>React Frontend]
        DB[(Database<br/>PostgreSQL)]
        UI --> DB
    end

    subgraph EXT_API["📊 EXTERNAL APIs"]
        H3_API[H3Africa<br/>Imputation<br/>API]
        MICH_API[Michigan<br/>Routes<br/>API]
    end

    %% Connections to Central
    AZ_DOCKER -->|WesKIT| UI
    MALI_NF -->|Data Flow| UI
    ILIFU_ATT -->|Attestation| UI

    %% Central to APIs
    UI --> H3_API
    UI --> MICH_API

    %% Data residency question
    MALI_NF -.->|DR?| ILIFU_ATT

    classDef azure fill:#1E90FF,stroke:#000,stroke-width:3px,color:#fff
    classDef onprem fill:#32CD32,stroke:#000,stroke-width:3px,color:#000
    classDef central fill:#FFD700,stroke:#000,stroke-width:4px,color:#000
    classDef api fill:#FF6347,stroke:#000,stroke-width:2px,color:#fff

    class AZURE,DNS,AZ_DOCKER azure
    class MALI,MALI_DRS,MALI_WES,MALI_NF,ILIFU,ILIFU_DRS,ILIFU_ATT onprem
    class CENTRAL,UI,DB central
    class EXT_API,H3_API,MICH_API api
```

## Simplified System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     FEDERATED ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────┘

    CLOUD SITES                 CENTRAL HUB           ON-PREMISES

┌─────────────┐              ┌─────────────┐        ┌─────────────┐
│   AZURE     │              │             │        │    MALI     │
│             │              │   CENTRAL   │        │             │
│  DNAstack   │─────────────▶│     UI      │◀───────│ DRS+WesKIT  │
│  DRS/WesKIT │   WesKIT     │             │  Data  │  Nextflow   │
│   Docker    │              │  • React    │  Flow  │   Docker    │
│             │              │  • Database │        │             │
└─────────────┘              │  • APIs     │        └─────────────┘
                             │             │
┌─────────────┐              └──────┬──────┘        ┌─────────────┐
│  MICHIGAN   │                     │               │    ILIFU    │
│             │                     │               │             │
│ Imputation  │◀────────────────────┤               │ DRS/WesKIT  │
│   Server    │      API Calls      │               │             │
│             │                     │               │ Attestation │
└─────────────┘                     │               │ Data SPA    │
                                    │               │             │
┌─────────────┐                     │               └─────────────┘
│  H3AFRICA   │                     │                      ▲
│             │                     │                      │
│ Historical  │◀────────────────────┘                      │
│  Impute API │                                    Data Residency?
│             │                                            │
└─────────────┘                                   ─────────┘


KEY CONCEPTS:
═════════════

🌍 FEDERATED MODEL
   • Central UI coordinates jobs
   • Data stays at source institutions (Mali, ILIFU)
   • Computation happens at remote sites
   • Results flow back to central

☁️ CLOUD vs ON-PREMISE
   • Azure: Cloud-based DNAstack with Docker
   • Mali: On-premises with Nextflow workflow
   • ILIFU: On-premises with attestation/governance

📊 WORKFLOW ENGINES
   • DRS: Data Repository Service (GA4GH standard)
   • WesKIT: Workflow Execution Service
   • Nextflow: Workflow orchestration
   • Docker: Containerized execution

🔐 DATA GOVERNANCE
   • Attestation: User verification for data access
   • Tasks: Compliance checkpoints
   • Data Connect: Secure data federation
   • DR (Data Residency): Where data physically resides
```

## What This Architecture Does

**1. USER SUBMITS JOB** at Central UI
   ↓
**2. CENTRAL ROUTES** job to appropriate service:
   - Azure DNAstack (cloud)
   - Mali H3Africa (on-prem Africa)
   - ILIFU H3Africa (on-prem South Africa)
   - Michigan Server (cloud USA)
   ↓
**3. SERVICE EXECUTES** imputation on their infrastructure:
   - DNAstack uses WesKIT → Docker
   - Mali uses DRS → WesKIT → Nextflow → Docker
   - ILIFU uses DRS/WesKIT → Attestation → Data SPA
   ↓
**4. RESULTS RETURN** to Central UI
   ↓
**5. USER DOWNLOADS** results

## Comparison to Your Whiteboard

**Your Sketch Shows:**
- ✅ Azure (DNAstack with DRS/WesKIT/Docker)
- ✅ Mali on-prem (DRS, WesKIT, Nextflow/Docker)
- ✅ ILIFU on-prem (DRS/WesKIT?, Attestation, Data SPA)
- ✅ Central UI coordinating everything
- ✅ External APIs (H3Africa Impute, Michigan Routes)
- ✅ Data residency question (DR?) between Mali and ILIFU

**This Matches the Federated Pattern:**
```
Multiple compute sites → Central coordinator → User interface
     (do the work)         (orchestrates)        (submits/views)
```

The "DR?" line in your sketch likely refers to **Data Residency** compliance -
ensuring Mali data doesn't leave Africa and stays compliant with regulations
like POPIA (Protection of Personal Information Act).
