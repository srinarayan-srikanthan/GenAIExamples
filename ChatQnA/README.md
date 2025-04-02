# ChatQnA Application

Chatbots are the most widely adopted use case for leveraging the powerful chat and reasoning capabilities of large language models (LLMs). The retrieval augmented generation (RAG) architecture is quickly becoming the industry standard for chatbots development. It combines the benefits of a knowledge base (via a vector store) and generative models to reduce hallucinations, maintain up-to-date information, and leverage domain-specific knowledge.

RAG bridges the knowledge gap by dynamically fetching relevant information from external sources, ensuring that responses generated remain factual and current. The core of this architecture are vector databases, which are instrumental in enabling efficient and semantic retrieval of information. These databases store data as vectors, allowing RAG to swiftly access the most pertinent documents or data points based on semantic similarity.

# Table of contents

1. [Architecture and Deploy Details](#architecture-and-deploy-details)
2. [Deployment Options](#deployment-options)
3. [Automated Terraform Deployment](#automated-deployment-to-ubuntu-based-systemif-not-using-terraform-using-intel-optimized-cloud-modules-for-ansible)
4. [Automated Deployment to Ubuntu based system](#automated-deployment-to-ubuntu-based-systemif-not-using-terraform-using-intel-optimized-cloud-modules-for-ansible)
5. [Monitoring and Tracing](#monitoring-opea-service-with-prometheus-and-grafana-dashboard)

## Architecture

The ChatQnA application is a customizable end to end workflow that leverages the capablities of LLM's and RAG effeciently. ChatQnA architecture shows below:

![architecture](./assets/img/chatqna_architecture.png)

This application is modular as it leverages each component as a microservice(as defined in [GenAIComps](https://github.com/opea-project/GenAIComps)) that can scale independently. It compises of data preparation, embedding , retrival, reranker(optinal) and LLM microservices. All these microservices are stiched together by the Chatqna megaservice that orchestrates the data through these microservices.The flow chart below shows the information flow between different microservices for this example.

```mermaid
---
config:
  flowchart:
    nodeSpacing: 400
    rankSpacing: 100
    curve: linear
  themeVariables:
    fontSize: 50px
---
flowchart LR
    %% Colors %%
    classDef blue fill:#ADD8E6,stroke:#ADD8E6,stroke-width:2px,fill-opacity:0.5
    classDef orange fill:#FBAA60,stroke:#ADD8E6,stroke-width:2px,fill-opacity:0.5
    classDef orchid fill:#C26DBC,stroke:#ADD8E6,stroke-width:2px,fill-opacity:0.5
    classDef invisible fill:transparent,stroke:transparent;
    style ChatQnA-MegaService stroke:#000000

    %% Subgraphs %%
    subgraph ChatQnA-MegaService["ChatQnA MegaService "]
        direction LR
        EM([Embedding MicroService]):::blue
        RET([Retrieval MicroService]):::blue
        RER([Rerank MicroService]):::blue
        LLM([LLM MicroService]):::blue
    end
    subgraph UserInterface[" User Interface "]
        direction LR
        a([User Input Query]):::orchid
        Ingest([Ingest data]):::orchid
        UI([UI server<br>]):::orchid
    end



    TEI_RER{{Reranking service<br>}}
    TEI_EM{{Embedding service <br>}}
    VDB{{Vector DB<br><br>}}
    R_RET{{Retriever service <br>}}
    DP([Data Preparation MicroService]):::blue
    LLM_gen{{LLM Service <br>}}
    GW([ChatQnA GateWay<br>]):::orange

    %% Data Preparation flow
    %% Ingest data flow
    direction LR
    Ingest[Ingest data] --> UI
    UI --> DP
    DP <-.-> TEI_EM

    %% Questions interaction
    direction LR
    a[User Input Query] --> UI
    UI --> GW
    GW <==> ChatQnA-MegaService
    EM ==> RET
    RET ==> RER
    RER ==> LLM


    %% Embedding service flow
    direction LR
    EM <-.-> TEI_EM
    RET <-.-> R_RET
    RER <-.-> TEI_RER
    LLM <-.-> LLM_gen

    direction TB
    %% Vector DB interaction
    R_RET <-.->|d|VDB
    DP <-.->|d|VDB

```

## Deployment Options

The table below shows different deployment options to choose from. They outline in detail the implementation of this example on the selected hardware.

| Category | Deployment Option | Description |
|------------------|------------------------------------------|
| On-premise Deployments | Docker compose | Xeon |
| | | AI PC |
| | | Gaudi |
| | | Nvidia GPU |
| | | AMD ROCM |
| Ubuntu 22.04 | Work-in-progress | test |



| Hardware  | Deployment Option                    |
| --------- | ----------------------------------- |
| Intel      | [Xeon](./docker_compose/intel/cpu/xeon) , [AI PC](./docker_compose/intel/cpu/aipc), [Gaudi](./docker_compose/intel/hpu/gaudi)                 |
| Nvidia     | [GPU (Turing, Ampere 80, Ampere 86, Ada Lovelace, H100](./docker_compose/nvidia/gpu)  |
| AMD     | [Rocm](./docker_compose/amd/gpu/rocm) |

## 🤖 Automated Terraform Deployment using Intel® Optimized Cloud Modules for **Terraform**

| Cloud Provider       | Intel Architecture                | Intel Optimized Cloud Module for Terraform                                                                                         | Comments                                                             |
| -------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| AWS                  | 4th Gen Intel Xeon with Intel AMX | [AWS Module](https://github.com/intel/terraform-intel-aws-vm/tree/main/examples/gen-ai-xeon-opea-chatqna)                          | Uses meta-llama/Meta-Llama-3-8B-Instruct by default                  |
| AWS Falcon2-11B      | 4th Gen Intel Xeon with Intel AMX | [AWS Module with Falcon11B](https://github.com/intel/terraform-intel-aws-vm/tree/main/examples/gen-ai-xeon-opea-chatqna-falcon11B) | Uses TII Falcon2-11B LLM Model                                       |
| GCP                  | 5th Gen Intel Xeon with Intel AMX | [GCP Module](https://github.com/intel/terraform-intel-gcp-vm/tree/main/examples/gen-ai-xeon-opea-chatqna)                          | Also supports Confidential AI by using Intel® TDX with 4th Gen Xeon |
| Azure                | 5th Gen Intel Xeon with Intel AMX | Work-in-progress                                                                                                                   | Work-in-progress                                                     |
| Intel Tiber AI Cloud | 5th Gen Intel Xeon with Intel AMX | Work-in-progress                                                                                                                   | Work-in-progress                                                     |

## Automated Deployment to Ubuntu based system(if not using Terraform) using Intel® Optimized Cloud Modules for **Ansible**

To deploy to existing Xeon Ubuntu based system, use our Intel Optimized Cloud Modules for Ansible. This is the same Ansible playbook used by Terraform.
Use this if you are not using Terraform and have provisioned your system with another tool or manually including bare metal.
| Operating System | Intel Optimized Cloud Module for Ansible |
|------------------|------------------------------------------|
| Ubuntu 20.04 | [ChatQnA Ansible Module](https://github.com/intel/optimized-cloud-recipes/tree/main/recipes/ai-opea-chatqna-xeon) |
| Ubuntu 22.04 | Work-in-progress |

## Troubleshooting

1. If you get errors like "Access Denied", [validate micro service](https://github.com/opea-project/GenAIExamples/tree/main/ChatQnA/docker_compose/intel/cpu/xeon/README.md#validate-microservices) first. A simple example:

   ```bash
   http_proxy="" curl ${host_ip}:6006/embed -X POST  -d '{"inputs":"What is Deep Learning?"}' -H 'Content-Type: application/json'
   ```

2. (Docker only) If all microservices work well, check the port ${host_ip}:8888, the port may be allocated by other users, you can modify the `compose.yaml`.

3. (Docker only) If you get errors like "The container name is in use", change container name in `compose.yaml`.

## Monitoring OPEA Service with Prometheus and Grafana dashboard

OPEA microservice deployment can easily be monitored through Grafana dashboards in conjunction with Prometheus data collection. Follow the [README](https://github.com/opea-project/GenAIEval/blob/main/evals/benchmark/grafana/README.md) to setup Prometheus and Grafana servers and import dashboards to monitor the OPEA service.

![chatqna dashboards](./assets/img/chatqna_dashboards.png)
![tgi dashboard](./assets/img/tgi_dashboard.png)

## Tracing Services with OpenTelemetry Tracing and Jaeger

> NOTE: This feature is disabled by default. Please check the Deploy ChatQnA sessions for how to enable this feature with compose.telemetry.yaml file.

OPEA microservice and TGI/TEI serving can easily be traced through Jaeger dashboards in conjunction with OpenTelemetry Tracing feature. Follow the [README](https://github.com/opea-project/GenAIComps/tree/main/comps/cores/telemetry#tracing) to trace additional functions if needed.

Tracing data is exported to http://{EXTERNAL_IP}:4318/v1/traces via Jaeger.
Users could also get the external IP via below command.

```bash
ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+'
```

Access the Jaeger dashboard UI at http://{EXTERNAL_IP}:16686

For TGI serving on Gaudi, users could see different services like opea, TEI and TGI.
![Screenshot from 2024-12-27 11-58-18](https://github.com/user-attachments/assets/6126fa70-e830-4780-bd3f-83cb6eff064e)

Here is a screenshot for one tracing of TGI serving request.
![Screenshot from 2024-12-27 11-26-25](https://github.com/user-attachments/assets/3a7c51c6-f422-41eb-8e82-c3df52cd48b8)

There are also OPEA related tracings. Users could understand the time breakdown of each service request by looking into each opea:schedule operation.
![image](https://github.com/user-attachments/assets/6137068b-b374-4ff8-b345-993343c0c25f)

There could be async function such as `llm/MicroService_asyn_generate` and user needs to check the trace of the async function in another operation like
opea:llm_generate_stream.
![image](https://github.com/user-attachments/assets/a973d283-198f-4ce2-a7eb-58515b77503e)
