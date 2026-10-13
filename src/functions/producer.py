#!/usr/bin/env python3
"""
数据生产者 - 模拟推送到 DIS 流

用于替代已废弃的 Twitter Streaming API
将模拟的社交媒体事件数据推送到华为云 DIS 流
"""

import json
import time
import random
import os
from datetime import datetime

# 华为云 DIS SDK
from huaweicloudsdkdis import DISClient
from huaweicloudsdkdis.request.putrecord import PutRecordRequest
from huaweicloudsdkdis.request.putrecord import PutRecordRequestBody


# 模拟数据生成
def generate_mock_event():
    """生成模拟的社交媒体事件数据"""
    users = ['alice', 'bob', 'charlie', 'david', 'eve', 'frank', 'grace', 'henry']
    messages = [
        'Hello from the stream!',
        'Just deployed to Huawei Cloud',
        'Testing real-time data processing',
        'Serverless is amazing',
        'FunctionGraph rocks!',
        'Building event-driven apps',
        'Data flows like water',
        'Stream processing 101'
    ]

    return {
        'id_str': f'{int(time.time() * 1000)}{random.randint(1000, 9999)}',
        'user': {
            'name': random.choice(users),
            'screen_name': random.choice(users).lower()
        },
        'text': random.choice(messages),
        'created_at': datetime.utcnow().strftime('%a %b %d %H:%M:%S +0000 %Y')
    }


def main():
    # 从环境变量获取配置
    dis_endpoint = os.environ.get('DIS_ENDPOINT', 'https://dis.cn-north-4.myhuaweicloud.com')
    stream_name = os.environ.get('DIS_STREAM_NAME', 'stream-processing-stream')
    ak = os.environ.get('HW_ACCESS_KEY', '')
    sk = os.environ.get('HW_SECRET_KEY', '')

    if not ak or not sk:
        print('ERROR: Please set HW_ACCESS_KEY and HW_SECRET_KEY environment variables')
        return

    # 创建 DIS 客户端
    client = DISClient.new_builder() \
        .with_credentials(ak, sk) \
        .with_endpoint(dis_endpoint) \
        .with_region('cn-north-4') \
        .build()

    print(f'Starting producer to DIS stream: {stream_name}')
    print(f'Endpoint: {dis_endpoint}')
    print('Press Ctrl+C to stop')

    try:
        while True:
            # 生成模拟事件
            event = generate_mock_event()

            # 序列化为 JSON
            data = json.dumps(event)
            data_bytes = data.encode('utf-8')

            # 推送到 DIS
            request = PutRecordRequest()
            request.stream_name = stream_name
            request.partition_key = event['user']['name']

            body = PutRecordRequestBody()
            body.data = data_bytes
            request.body = body

            try:
                response = client.put_record(request)
                print(f'[OK] {event["user"]["name"]}: {event["text"][:50]}...')
                print(f'    SequenceNumber: {response.sequence_number}')
            except Exception as e:
                print(f'[ERROR] Failed to put record: {e}')

            # 间隔 1-3 秒
            time.sleep(random.uniform(1, 3))

    except KeyboardInterrupt:
        print('\nProducer stopped')


if __name__ == '__main__':
    main()
