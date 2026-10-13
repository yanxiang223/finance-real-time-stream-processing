# ============================================
# 实时流处理参考架构 - Terraform
# 华为云最佳实践
# ============================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.96.0"
    }
  }
}

# ============================================
# Provider 配置
# ============================================

provider "huaweicloud" {
  region = var.region
}

# ============================================
# 网络层 - VPC/子网/安全组
# ============================================

resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = var.subnet_cidr
  gateway_ip = cidrhost(var.subnet_cidr, 1)
}

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for stream processing"
}

resource "huaweicloud_networking_secgroup_rule" "egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "ingress_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# ============================================
# IAM 委托 - FunctionGraph 访问 GeminiDB
# ============================================

resource "huaweicloud_identity_agency" "functiongraph" {
  name                  = "${var.project_name}-fgs-agency"
  description           = "Agency for FunctionGraph to access GeminiDB"
  duration              = "FOREVER"
  delegated_service_name = "op_svc_cff"  # FunctionGraph 云服务名称

  project_role {
    project = var.region
    roles = [
      "OBS OperateAccess",
      "GaussDBforNoSQL FullAccess",
    ]
  }
}

# ============================================
# GeminiDB 实例（Cassandra 引擎）
# ============================================

resource "huaweicloud_geminidb_instance" "main" {
  name              = "${var.project_name}-db"
  mode              = "Cluster"
  password          = var.geminidb_password
  availability_zone = "${var.region}a,${var.region}b,${var.region}c"
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.main.id

  datastore {
    type           = "cassandra"
    storage_engine = "rocksDB"
    version        = "3.11"
  }

  flavor {
    num       = 3
    size      = 100
    spec_code = "geminidb.cassandra.large.4"
    storage   = "ULTRAHIGH"
  }

  tags = {
    project = var.project_name
  }
}

# ============================================
# DIS 流
# ============================================

resource "huaweicloud_dis_stream" "event_stream" {
  stream_name       = "${var.project_name}-stream"
  partition_count  = var.dis_shard_count
  retention_period = 24

  tags = {
    project = var.project_name
  }
}

# ============================================
# FunctionGraph 函数
# ============================================

resource "huaweicloud_fgs_function" "stream_processor" {
  name        = "${var.project_name}-processor"
  agency      = huaweicloud_identity_agency.functiongraph.name
  app         = "default"
  runtime     = var.function_runtime
  handler     = "index.handler"
  memory_size = var.function_memory_size
  timeout     = var.function_timeout
  description = "Stream processing function - processes DIS events and writes to GeminiDB"

  func_code = <<-EOF
exports.handler = async (event, context) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  const cassandra = require('cassandra-driver');
  const endpoint = process.env.GEMINIDB_ENDPOINT;
  const keyspace = process.env.KEYSPACE || 'stream_data';

  if (!endpoint) {
    throw new Error('GEMINIDB_ENDPOINT environment variable is not set');
  }

  // 解析 DIS 事件
  const records = event.records || [];
  const insertPromises = [];

  for (const record of records) {
    try {
      // DIS 数据解码（Base64 -> ASCII -> JSON）
      const payload = Buffer.from(record.kinesis.data, 'base64').toString('ascii');
      const data = JSON.parse(payload);

      const query = \`INSERT INTO \${keyspace}.event_data (id, username, timestamp, message) VALUES (?, ?, ?, ?)\`;
      const params = [
        data.id || Date.now().toString(),
        data.user?.name || data.user_name || 'unknown',
        data.created_at || new Date().toISOString(),
        data.text || data.message || ''
      ];

      insertPromises.push(
        client.execute(query, params, { prepare: true }).then(() => {
          console.log('Inserted:', params[0]);
        }).catch(err => {
          console.error('Insert failed:', err.message);
        })
      );
    } catch (e) {
      console.error('Process error:', e.message);
    }
  }

  await Promise.all(insertPromises);

  return {
    statusCode: 200,
    body: \`Processed \${records.length} records\`
  };
};

// 初始化 Cassandra 客户端（全局复用）
let client = null;
const getClient = () => {
  if (!client) {
    const contactPoints = (process.env.GEMINIDB_ENDPOINT || '').split(',');
    client = new cassandra.contactPoints(contactPoints);
  }
  return client;
};
EOF

  environment {
    variables = {
      GEMINIDB_ENDPOINT = replace(huaweicloud_geminidb_instance.main.connection_address, ",", ",")
      KEYSPACE          = "stream_data"
    }
  }

  tags = {
    project = var.project_name
  }
}

# ============================================
# DIS 触发器 - 关联 DIS 流与 FunctionGraph
# ============================================

resource "huaweicloud_dis_bucket" "stream_bucket" {
  bucket_name = "${var.project_name}-dis-trigger"
  region     = var.region
}

resource "huaweicloud_fgs_trigger" "dis_trigger" {
  function_urn = huaweicloud_fgs_function.stream_processor.function_urn
  type        = "DIS"
  trigger_config {
    stream_name     = huaweicloud_dis_stream.event_stream.stream_name
    shard_iterator_type = "LATEST"
    batch_size      = 100
    max_fetch_records = 1000
  }
}

# ============================================
# 输出
# ============================================

output "dis_stream_name" {
  description = "DIS 流名称"
  value       = huaweicloud_dis_stream.event_stream.stream_name
}

output "dis_stream_id" {
  description = "DIS 流 ID"
  value       = huaweicloud_dis_stream.event_stream.id
}

output "function_urn" {
  description = "FunctionGraph 函数 URN"
  value       = huaweicloud_fgs_function.stream_processor.function_urn
}

output "geminidb_connection_string" {
  description = "GeminiDB 连接地址"
  value       = huaweicloud_geminidb_instance.main.connection_address
  sensitive   = true
}

output "geminidb_instance_id" {
  description = "GeminiDB 实例 ID"
  value       = huaweicloud_geminidb_instance.main.id
}
