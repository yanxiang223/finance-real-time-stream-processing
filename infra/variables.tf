variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称，用于资源命名"
  type        = string
  default     = "stream-processing"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "子网网段"
  type        = string
  default     = "10.0.1.0/24"
}

variable "dis_shard_count" {
  description = "DIS 流分片数"
  type        = number
  default     = 1
}

variable "function_runtime" {
  description = "FunctionGraph 运行时"
  type        = string
  default     = "Node.js18.15"
}

variable "function_timeout" {
  description = "函数超时时间（秒）"
  type        = number
  default     = 10
}

variable "function_memory_size" {
  description = "函数内存大小（MB）"
  type        = number
  default     = 128
}

variable "geminidb_password" {
  description = "GeminiDB 密码（至少8位，包含大小写和数字）"
  type        = string
  sensitive   = true
}
