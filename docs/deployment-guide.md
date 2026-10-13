# 部署指南 - 实时流处理

## 前置条件

1. 华为云账号
2. IAM 用户 AK/SK（具备 DIS、FunctionGraph、GeminiDB、VPC、OBS 创建权限）
3. Terraform >= 1.0

## 快速开始

### 1. 克隆仓库

```bash
git clone <repository-url>
cd huaweicloud/lambda-refarch-streamprocessing
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

### 3. 初始化 Terraform

```bash
cd infra
terraform init
```

### 4. 规划部署

```bash
terraform plan
```

### 5. 执行部署

```bash
terraform apply
```

输入 `yes` 确认部署。

### 6. 验证部署

部署完成后，查看输出：

```bash
terraform output
```

获取关键信息：
- `dis_stream_name`: DIS 流名称
- `function_urn`: FunctionGraph 函数 URN
- `geminidb_endpoint`: GeminiDB 连接地址

## 验证功能

### 方式一：运行 Producer

```bash
cd src/functions
pip install huaweicloudsdkdis

export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
export DIS_STREAM_NAME="stream-processing-stream"

python producer.py
```

### 方式二：手动触发函数

```bash
# 获取函数 Invoke URL
INVOKE_URL=$(terraform output -raw functiongraph | jq -r '.invoke_url')

# 模拟 DIS 事件
curl -X POST $INVOKE_URL \
  -H "Content-Type: application/json" \
  -d '{
    "records": [
      {
        "kinesis": {
          "data": "eyJpZF9zdHIiOiAiMTIzNDU2Nzg5MCIsInVzZXIiOiB7Im5hbWUiOiAidGVzdCJ9LCJ0ZXh0IjogIkhlbGxvIiwgImNyZWF0ZWRfYXQiOiAiVGh1IEp1bCAyNyAyMDI2IDEwOjMwOjAwICswMDAwIn0="
        }
      }
    ]
  }'
```

### 3. 查看数据

连接 GeminiDB 查看写入的数据：

```bash
# 使用 Cassandra CLI 连接
cqlsh <geminidb-endpoint> -u root -p <password>
# 查询数据
SELECT * FROM stream_data.event_data;
```

## 清理资源

```bash
terraform destroy
```

输入 `yes` 确认删除所有资源。

