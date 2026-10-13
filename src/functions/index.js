/*
 * 华为云流处理函数 - 实时处理 DIS 流数据并写入 GeminiDB (Cassandra 兼容)
 *
 * 事件来源: DIS (数据接入服务) 推送的事件
 * 存储: GeminiDB Cassandra API
 */

'use strict';

const cassandra = require('cassandra-driver');

let client = null;

/**
 * 获取或初始化 Cassandra 客户端
 */
function getClient(endpoint) {
  if (!client) {
    // endpoint 格式: "192.168.1.1:9042,192.168.1.2:9042"
    const contactPoints = endpoint.split(',').map(e => e.trim());
    client = new cassandra.contactPoints(contactPoints);
  }
  return client;
}

exports.handler = async function(event, context) {
  console.log('Received event:', JSON.stringify(event, null, 2));

  // 从环境变量获取 GeminiDB 连接信息
  const endpoint = process.env.GEMINIDB_ENDPOINT;
  const keyspace = process.env.KEYSPACE || 'stream_data';

  if (!endpoint) {
    throw new Error('GEMINIDB_ENDPOINT environment variable is not set');
  }

  const cassandraClient = getClient(endpoint);

  // 确保 keyspace 存在
  try {
    await cassandraClient.execute(
      `CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1}`
    );
  } catch (e) {
    console.log('Keyspace creation skipped:', e.message);
  }

  // 确保表存在
  try {
    await cassandraClient.execute(`
      CREATE TABLE IF NOT EXISTS ${keyspace}.event_data (
        id text PRIMARY KEY,
        username text,
        timestamp text,
        message text
      )
    `);
  } catch (e) {
    console.log('Table creation skipped:', e.message);
  }

  // 处理每条 DIS 记录
  const records = event.records || [];
  const insertPromises = [];

  for (const record of records) {
    // DIS 数据解码（Base64 -> ASCII）
    let payload;
    try {
      payload = Buffer.from(record.kinesis.data, 'base64').toString('ascii');
      console.log('Decoded payload:', payload);
    } catch (e) {
      console.log('Decode error:', e.message);
      continue;
    }

    try {
      const data = JSON.parse(payload);

      const query = `INSERT INTO ${keyspace}.event_data (id, username, timestamp, message) VALUES (?, ?, ?, ?)`;
      const params = [
        data.id || data.id_str || String(Date.now()),
        data.user?.name || data.user_name || 'unknown',
        data.created_at || new Date().toISOString(),
        data.text || data.message || ''
      ];

      insertPromises.push(
        cassandraClient.execute(query, params, { prepare: true })
          .then(() => {
            console.log('Inserted:', params[0]);
          })
          .catch(err => {
            console.error('Insert failed:', err.message);
          })
      );
    } catch (e) {
      console.log('Parse error:', e.message);
    }
  }

  await Promise.all(insertPromises);

  return {
    statusCode: 200,
    body: `Processed ${records.length} records`
  };
};
