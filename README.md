# Real-time Stream Processing Reference Architecture

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Overview

This implementation provides a **Real-time Stream Processing** reference architecture on Huawei Cloud, demonstrating a complete event-driven data processing pipeline built with native Huawei Cloud services.

### What is Real-time Stream Processing?

Real-time Stream Processing is a data processing paradigm that analyzes and processes **continuous data streams** in real-time. Unlike traditional batch processing, stream processing handles data immediately upon arrival, with latencies typically in milliseconds to seconds. This approach is ideal for:

- **IoT Sensor Data Collection and Analysis**
- **Real-time Log Monitoring and Anomaly Detection**
- **Financial Transaction Risk Control**
- **Social Media Real-time Sentiment Analysis**
- **Clickstream User Behavior Analysis**

### What This Architecture Solves

This reference architecture demonstrates how to build an end-to-end real-time stream processing system:

1. **Data Ingestion**: Data sources (Producers) push data to DIS (Data Ingestion Service)
2. **Event Triggering**: When DIS receives data, it automatically triggers a FunctionGraph function
3. **Data Processing**: FunctionGraph processes the received data—parsing, transforming, enriching, etc.
4. **Persistent Storage**: Processed structured data is written to GeminiDB (Document Database) for permanent storage

### Key Benefits

- **Serverless Architecture**: No server provisioning or management required, pay-per-use, significantly reduces operational costs
- **Auto-scaling**: DIS shards and FunctionGraph concurrency automatically adjust based on data volume
- **Low Latency**: Data processing completes in milliseconds, from ingestion to persistence in seconds
- **High Availability**: DIS and FunctionGraph are deployed across multiple availability zones; single points of failure don't affect the overall service
- **Fully Managed**: Huawei Cloud handles infrastructure availability and performance; you focus only on business logic

## Features

- **Event-driven**: DIS triggers FunctionGraph, enabling true reactive architecture
- **Serverless**: No server management, execute on-demand, pay-per-use
- **Real-time processing**: Millisecond-level data processing latency, seconds for ingestion-to-persistence
- **Persistent storage**: GeminiDB stores structured data with high-concurrency read support
- **Scalable**: DIS shards can be dynamically adjusted, FunctionGraph supports high concurrency
- **Monitoring integration**: Can integrate with Cloud Eye for real-time monitoring and alerting

## Architecture Diagram

```
┌─────────────┐     ┌─────────┐     ┌─────────────┐     ┌──────────┐
│   Data      │ ──> │   DIS   │ ──> │FunctionGraph│ ──> │ GeminiDB │
│  Producer   │     │ (Stream)│     │ (Function)  │     │ (Storage)│
└─────────────┘     └─────────┘     └─────────────┘     └──────────┘

Data Flow:
1. Producer pushes data to DIS stream
2. DIS triggers FunctionGraph function
3. Function parses data and writes to GeminiDB
4. Data is persistently stored
```

### Component Description

| Component | Huawei Cloud Service | Description |
|-----------|---------------------|-------------|
| Data Source | Custom Producer | Generates or collects raw data, pushes to DIS stream |
| Data Ingestion | DIS (Data Ingestion Service) | Real-time data stream ingestion |
| Event Processing | FunctionGraph | Serverless function computing |
| Data Storage | GeminiDB | Document database with Cassandra API support |

## Use Cases

This reference architecture is suitable for:

- **Real-time Data Analysis**: Aggregate, analyze, and process data as it arrives
- **Event-driven Applications**: Trigger business logic based on events (order processing, user behavior tracking)
- **IoT Data Processing**: Process real-time data from sensors and devices
- **Real-time Log Analysis**: Collect and analyze application logs in real-time for anomaly detection
- **Real-time Recommendation Systems**: Personalize recommendations based on real-time user behavior

## Prerequisites

- Huawei Cloud account
- IAM user AK/SK (with permissions to create DIS, FunctionGraph, GeminiDB resources)
- Terraform >= 1.0
- Node.js >= 18 (for local testing)
- Python >= 3.8 (for running Producer)

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd huaweicloud/lambda-refarch-streamprocessing
```

### 2. Configure Credentials

Set environment variables:

```bash
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

Or create a `terraform.tfvars` file:

```bash
cp infra/tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars with your configuration
```

### 3. Deploy

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 4. Verify

#### Option 1: Run Producer

```bash
cd src/functions
pip install -r requirements.txt

export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
export DIS_STREAM_NAME="stream-processing-stream"

python producer.py
```

#### Option 2: Manually Trigger Function

Manually trigger the function through the FunctionGraph console or API with test events.

See [Deployment Guide](docs/deployment-guide.md) for detailed steps.

## Technical Specifications

| Component | Specification |
|----------|---------------|
| DIS Shards | 1 (scalable) |
| Function Runtime | Node.js 18.15 |
| Function Memory | 128 MB |
| Function Timeout | 10 seconds |
| GeminiDB Nodes | 3 |
| Storage Capacity | 100 GB |

## Cloud Services Involved

- **DIS** (Data Ingestion Service) - Real-time data stream ingestion
- **FunctionGraph** (FunctionCompute) - Serverless event processing
- **GeminiDB** (Document Database) - Structured data storage
- **OBS** (Object Storage Service) - Function code storage (optional)
- **VPC** (Virtual Private Cloud) - Network isolation
- **IAM** (Identity and Access Management) - Access control

## License

MIT No Attribution - Copyright Huawei Cloud

## Contact

- Huawei Cloud: https://www.huaweicloud.com/
- Technical Support: Contact Huawei Cloud Customer Service
