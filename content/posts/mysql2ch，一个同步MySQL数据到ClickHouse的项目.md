---
title: "Mysql2ch，一个同步MySQL数据到ClickHouse的项目"
date: 2020-05-05T17:14:11+08:00
categories:
  - 程序天地
tags:
  - MySQL
  - ClickHouse
---

## 介绍

[mysql2ch](https://github.com/long2ice/mysql2ch) 是一个用于同步 MySQL 到 ClickHouse 的工具，支持全量同步与增量同步。

![mysql2ch](https://github.com/long2ice/mysql2ch/raw/master/images/mysql2ch.png)

## 特性

- 支持全量同步与增量同步。
- 支持 DDL 与 DML，当前支持 DDL 字段新增与删除，支持所有的 DML。
- 丰富的配置项。
- 生产者与消费者 ui 监控。

## 依赖

- [kafka](https://kafka.apache.org)，用户缓冲 MySQL binlog 的消息队列。
- [redis](https://redis.io)，缓存 MySQL binlog position 与 file。

## 安装

```shell
pip install mysql2ch
```

## 使用

配置文件

```json
{
  "debug": true,
  "environment": "development",
  "mysql_host": "127.0.0.1",
  "mysql_port": 3306,
  "mysql_user": "root",
  "mysql_password": "123456",
  "mysql_server_id": 21,
  "redis_host": "127.0.0.1",
  "redis_port": 6379,
  "redis_password": null,
  "redis_db": 0,
  "clickhouse_host": "127.0.0.1",
  "clickhouse_port": 9000,
  "clickhouse_user": "default",
  "clickhouse_password": "123456",
  "kafka_server": "127.0.0.1:9092",
  "kafka_topic": "test",
  "sentry_dsn": "https://3450e192063d47aea7b9733d3d52585f@sentry.prismslight.com/12",
  "schema_table": {
    "test": {
      "tables": [
        "test"
      ],
      "kafka_partition": 0
    }
  },
  "init_binlog_file": "mysql-bin.000005",
  "init_binlog_pos": 11090597,
  "log_pos_prefix": "mysql2ch",
  "skip_delete_tables": [
    "test.test2"
  ],
  "skip_update_tables": [
    "test.test2"
  ],
  "skip_dmls": [
    "delete",
    "update"
  ],
  "insert_num": 20000,
  "insert_interval": 60
}
```

## 全量同步

你可能需要在开始增量同步之前进行一次全量导入，或者使用`--renew`重新全量导入，该操作会删除目标表并重新同步。

```shell
    $ mysql2ch etl -h

    usage: mysql2ch etl [-h] --schema SCHEMA [--tables TABLES] [--renew]

    optional arguments:
      -h, --help       show this help message and exit
      --schema SCHEMA  Schema to full etl.
      --tables TABLES  Tables to full etl,multiple tables split with comma.
      --renew          Etl after try to drop the target tables.
```

## 生产者

监听 MySQL binlog 并生产至 kafka。

```shell
mysql2ch produce
```

## 消费者

从 kafka 消费并插入 ClickHouse，使用`--skip-error`跳过错误行。

```shell
    $ mysql2ch consume -h

    usage: mysql2ch consume [-h] --schema SCHEMA [--skip-error] [--auto-offset-reset AUTO_OFFSET_RESET]

    optional arguments:
      -h, --help            show this help message and exit
      --schema SCHEMA       Schema to consume.
      --skip-error          Skip error rows.
      --auto-offset-reset AUTO_OFFSET_RESET
                            Kafka auto offset reset,default earliest.
```

## 使用 docker-compose（推荐）

```yaml
version: '3'
services:
  zookeeper:
    image: bitnami/zookeeper:3
    hostname: zookeeper
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    volumes:
      - zookeeper:/bitnami
  kafka:
    image: bitnami/kafka:2
    hostname: kafka
    environment:
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - ALLOW_PLAINTEXT_LISTENER=yes
      - JMX_PORT=23456
      - KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
    depends_on:
      - zookeeper
    volumes:
      - kafka:/bitnami
  kafka-manager:
    image: hlebalbau/kafka-manager
    ports:
      - "9000:9000"
    depends_on:
      - kafka
      - zookeeper
    environment:
      ZK_HOSTS: "zookeeper:2181"
      KAFKA_MANAGER_AUTH_ENABLED: "true"
      KAFKA_MANAGER_USERNAME: admin
      KAFKA_MANAGER_PASSWORD: 123456
    command: -Dpidfile.path=/dev/null
  producer:
    depends_on:
      - redis
      - kafka
      - zookeeper
    image: long2ice/mysql2ch
    command: mysql2ch -c config.json produce
    volumes:
      - ./config.json:/src/config.json
  consumer.test:
    depends_on:
      - redis
      - kafka
      - zookeeper
    image: long2ice/mysql2ch
    command: mysql2ch -c config.json consume --schema test
    volumes:
    - ./config.json:/src/config.json
  redis:
    hostname: redis
    image: redis:latest
    volumes:
      - redis:/data
volumes:
  redis:
  kafka:
  zookeeper:
```

## 可选

[Sentry](https://github.com/getsentry/sentry)，错误报告，在`config.json`配置 `sentry_dsn`后开启。

## 开源许可

本项目遵从 [MIT](https://github.com/long2ice/mysql2ch/blob/master/LICENSE)开源许可。
