# 实时流处理参考架构

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 简介

本实践是 **实时流处理（Real-time Stream Processing）** 的华为云参考架构实现，基于华为云原生服务构建了一个完整的事件驱动数据处理流水线。

### 什么是实时流处理？

实时流处理是一种数据处理范式，它对持续不断的**数据流（Data Stream）**进行实时分析和处理。与传统的批处理（Batch Processing）不同，流处理在数据到达时立即进行处理，延迟通常在毫秒到秒级别，适用于以下场景：

- **物联网（IoT）传感器数据采集与分析**
- **实时日志监控与异常检测**
- **金融交易实时风控**
- **社交媒体实时舆情分析**
- **点击流实时用户行为分析**

### 本架构解决的问题

本参考架构演示了如何构建一个端到端的实时流处理系统：

1. **数据接入**：数据源（Producer）将数据推送到 DIS（数据接入服务）
2. **事件触发**：DIS 流接收到数据后，自动触发 FunctionGraph 函数执行
3. **数据处理**：FunctionGraph 函数对接收到的数据进行解析、转换、增强等处理
4. **持久化存储**：处理后的结构化数据写入 GeminiDB（文档数据库）进行永久存储

### 核心优势

- **无服务器架构**：无需预置或管理服务器，按需计费，大幅降低运维成本
- **弹性伸缩**：DIS 分片和 FunctionGraph 并发数可根据数据量自动调整
- **低延迟**：数据从接收到处理完成通常在毫秒级别完成
- **高可用**：DIS 和 FunctionGraph 均采用多可用区部署，单点故障不影响整体服务
- **完全托管**：华为云负责基础设施的可用性和性能，用户只需关注业务逻辑

## 特性

- **事件驱动**：DIS 流触发 FunctionGraph 函数，实现真正的响应式架构
- **无服务器**：无需管理服务器，按需执行，按使用量计费
- **实时处理**：毫秒级数据处理延迟，数据从摄入到持久化秒级完成
- **持久化**：GeminiDB 存储结构化数据，支持高并发读取
- **可扩展**：DIS 分片数可动态调整，FunctionGraph 支持高并发
- **监控集成**：可对接 Cloud Eye 进行实时监控和告警

## 架构图

```
┌─────────────┐     ┌─────────┐     ┌─────────────┐     ┌──────────┐
│  数据源    │ ──> │   DIS   │ ──> │FunctionGraph│ ──> │ GeminiDB │
│ (Producer) │     │  (流)   │     │  (函数)     │     │  (存储)  │
└─────────────┘     └─────────┘     └─────────────┘     └──────────┘

数据流:
1. Producer 推送数据到 DIS 流
2. DIS 触发 FunctionGraph 函数
3. 函数解析数据并写入 GeminiDB
4. 数据持久化存储
```

### 组件说明

| 组件 | 华为云服务 | 说明 |
|------|-----------|------|
| 数据源 | 自定义 Producer | 生成或采集原始数据，推送到 DIS 流 |
| 数据接入 | DIS (数据接入服务) | 实时数据流接入 |
| 事件处理 | FunctionGraph | 无服务器函数计算 |
| 数据存储 | GeminiDB | 文档数据库，支持 Cassandra API |

## 适用场景

本参考架构适用于以下场景：

- **实时数据分析**：对实时到来的数据进行聚合、统计、分析
- **事件驱动应用**：基于事件触发业务逻辑，如订单处理、用户行为追踪
- **物联网数据处理**：处理来自传感器、设备的实时数据流
- **日志实时分析**：实时收集、分析应用日志，进行异常检测
- **实时推荐系统**：基于用户实时行为进行个性化推荐

## 前置条件

- 华为云账号
- IAM 用户 AK/SK（需具备 DIS、FunctionGraph、GeminiDB 创建权限）
- Terraform >= 1.0
- Node.js >= 18（用于本地测试）
- Python >= 3.8（用于运行 Producer）

## 快速开始

### 1. 克隆仓库

```bash
git clone <repository-url>
cd huaweicloud/finance-real-time-stream-processing
```

### 2. 配置凭据

设置环境变量：

```bash
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

或创建 `terraform.tfvars` 文件：

```bash
cp infra/tfvars.example infra/terraform.tfvars
# 编辑 terraform.tfvars 填入您的配置
```

### 3. 部署

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 4. 验证

#### 方式一：运行 Producer

```bash
cd src/functions
pip install -r requirements.txt

export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
export DIS_STREAM_NAME="stream-processing-stream"

python producer.py
```

#### 方式二：手动触发函数

通过 FunctionGraph 控制台或 API 手动触发函数，传入测试事件。

详细步骤见 [部署指南](docs/deployment-guide.md)

## 技术规格

| 组件 | 规格 |
|------|------|
| DIS 分片数 | 1（可扩展） |
| 函数运行时 | Node.js 18.15 |
| 函数内存 | 128 MB |
| 函数超时 | 10 秒 |
| GeminiDB 节点 | 3 |
| 存储容量 | 100 GB |

## 涉及云服务

- **DIS** (数据接入服务) - 实时数据流接入
- **FunctionGraph** (函数计算) - 无服务器事件处理
- **GeminiDB** (文档数据库) - 结构化数据存储
- **OBS** (对象存储服务) - 函数代码存储（可选）
- **VPC** (虚拟私有云) - 网络隔离
- **IAM** (统一身份认证服务) - 访问控制

## 许可证

MIT No Attribution - Copyright Huawei Cloud
