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

![mysql2ch](https://github.com/long2ice/mysql2ch/raw/dev/images/mysql2ch.png)

## 特性

- 支持全量同步与增量同步。
- 支持 DDL 与 DML，当前支持 DDL 字段新增与删除与重命名，支持所有的 DML。
- 支持 redis 和 kafka 作为消息队列。

## 依赖

- [kafka](https://kafka.apache.org)，缓冲 MySQL binlog 的消息队列，当使用 kafka 作为消息队列时需要。
- [redis](https://redis.io)，缓存 MySQL binlog position 与 file。

## 安装

```shell
pip install mysql2ch
```

## 使用

配置文件

```ini
[core]
# 当前支持kafka和redis作为消息队列
broker_type = kafka
mysql_server_id = 1
# redis stream最大长度，多出的消息会按照FIFO删除
queue_max_len = 200000
init_binlog_file = binlog.000024
init_binlog_pos = 252563
# 跳过删除的表，多个以逗号分开
skip_delete_tables =
# 跳过更新的表，多个以逗号分开
skip_update_tables =
# 跳过的DML，多个以逗号分开
skip_dmls =
# 每多少条消息同步一次，生产环境推荐20000
insert_num = 1
# 每多少秒同步一次，生成环境推荐60秒
insert_interval = 1

[sentry]
# sentry environment
environment = development
# sentry dsn
dsn = https://xxxxxxxx@sentry.test.com/1

[redis]
host = 127.0.0.1
port = 6379
password =
db = 0
prefix = mysql2ch
# 启用哨兵模式
sentinel = false
# 哨兵地址
sentinel_hosts = 127.0.0.1:5000,127.0.0.1:5001,127.0.0.1:5002
sentinel_master = master

[mysql]
host = 127.0.0.1
port = 3306
user = root
password = 123456

# 需要同步的数据库
[mysql.test]
# 需要同步的表
tables = test
# 指定kafka分区
kafka_partition = 0

[clickhouse]
host = 127.0.0.1
port = 9000
user = default
password =

# need when broker_type=kafka
[kafka]
# kafka servers,multiple separated with comma
servers = 127.0.0.1:9092
topic = mysql2ch
```

## 全量同步

你可能需要在开始增量同步之前进行一次全量导入，或者使用`--renew`重新全量导入，该操作会删除目标表并重新同步。

```shell
> mysql2ch etl -h

usage: mysql2ch etl [-h] --schema SCHEMA [--tables TABLES] [--renew]

optional arguments:
  -h, --help       show this help message and exit
  --schema SCHEMA  Schema to full etl.
  --tables TABLES  Tables to full etl,multiple tables split with comma,default read from environment.
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
> mysql2ch consume -h

usage: mysql2ch consume [-h] --schema SCHEMA [--skip-error] [--last-msg-id LAST_MSG_ID]

optional arguments:
  -h, --help            show this help message and exit
  --schema SCHEMA       Schema to consume.
  --skip-error          Skip error rows.
  --last-msg-id LAST_MSG_ID
                        Redis stream last msg id or kafka msg offset, depend on broker_type in config.
```

## 使用 docker-compose（推荐）

<details>
<summary>Redis，轻量级消息队列，应对低并发场景</summary>

```yaml
version: "3"
services:
  producer:
    depends_on:
      - redis
    image: long2ice/mysql2ch
    command: mysql2ch produce
    volumes:
      - ./mysql2ch.ini:/mysql2ch/mysql2ch.ini
  consumer.test:
    depends_on:
      - redis
    image: long2ice/mysql2ch
    command: mysql2ch consume --schema test
    volumes:
      - ./mysql2ch.ini:/mysql2ch/mysql2ch.ini
  redis:
    hostname: redis
    image: redis:latest
    volumes:
      - redis
volumes:
  redis:
```

</details>

<details>
<summary>Kafka，应对高并发场景</summary>

```yml
version: "3"
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
    environment:
      ZK_HOSTS: "zookeeper:2181"
      KAFKA_MANAGER_AUTH_ENABLED: "false"
    command: -Dpidfile.path=/dev/null
  producer:
    depends_on:
      - redis
      - kafka
      - zookeeper
    image: long2ice/mysql2ch
    command: mysql2ch produce
    volumes:
      - ./mysql2ch.ini:/mysql2ch/mysql2ch.ini
  consumer.test:
    depends_on:
      - redis
      - kafka
      - zookeeper
    image: long2ice/mysql2ch
    command: mysql2ch consume --schema test
    volumes:
      - ./mysql2ch.ini:/mysql2ch/mysql2ch.ini
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

</details>

## 可选

[Sentry](https://github.com/getsentry/sentry)，错误报告，在`config.json`配置 `sentry_dsn`后开启。

## 开源许可

本项目遵从 [MIT](https://github.com/long2ice/mysql2ch/blob/master/LICENSE)开源许可。
