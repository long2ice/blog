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

在当前执行目录创建`.env`或者设置系统环境变量：

.env

```ini
    # 设置为True会打印SQL
    DEBUG=True

    # 监控界面配置
    UI_ENABLE=True
    UI_REDIS_DB=1
    UI_MAX_NUM=60

    # sentry配置
    ENVIRONMENT=development

    MYSQL_HOST=127.0.0.1
    MYSQL_PORT=3306
    MYSQL_USER=root
    MYSQL_PASSWORD=123456
    MYSQL_SERVER_ID=101

    REDIS_HOST=127.0.0.1
    REDIS_PORT=6379
    REDIS_DB=0

    CLICKHOUSE_HOST=127.0.0.1
    CLICKHOUSE_PORT=9002
    CLICKHOUSE_PASSWORD=
    CLICKHOUSE_USER=default

    SENTRY_DSN=https://3450e192063d47aea7b9733d3d52585f@sentry.test.com/1

    KAFKA_SERVER=127.0.0.1:9092
    KAFKA_TOPIC=mysql2ch

    # 配置需要同步的数据表
    SCHEMA_TABLE=test.test;
    # 配置kafka分区与schema映射
    PARTITIONS=test=0;

    # 初始binlog信息，后续会从redis读取
    INIT_BINLOG_FILE=binlog.000474
    INIT_BINLOG_POS=155

    # 每多少条提交一次
    INSERT_NUMS=20000
    # 每多少秒提交一次
    INSERT_INTERVAL=60

```

## 全量同步

你可能需要在开始增量同步之前进行一次全量导入，或者使用`--renew`重新全量导入。

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

## 监控界面

```shell
    $ mysql2ch ui -h

    usage: mysql2ch ui [-h] [--host HOST] [-p PORT]

    optional arguments:
      -h, --help            show this help message and exit
      --host HOST           Listen host.
      -p PORT, --port PORT  Listen port.
```

## 使用 docker-compose（推荐）

```yaml
version: "3"
services:
  producer:
    env_file:
      - .env
    depends_on:
      - redis
    image: long2ice/mysql2ch:latest
    command: mysql2ch produce
  # add more service if you need.
  consumer.test:
    env_file:
      - .env
    depends_on:
      - redis
      - producer
    image: long2ice/mysql2ch:latest
    # consume binlog of test
    command: mysql2ch consume --schema test
  redis:
    hostname: redis
    image: redis:latest
    volumes:
      - redis:/data
  ui:
    env_file:
      - .env
    ports:
      - 5000:5000
    depends_on:
      - redis
      - producer
      - consumer
    image: long2ice/mysql2ch
    command: mysql2ch ui
volumes:
  redis:
```

## 可选

[Sentry](https://github.com/getsentry/sentry)，错误报告，在`.env`配置 `SENTRY_DSN`后开启。

## 开源许可

本项目遵从 [MIT](https://github.com/long2ice/mysql2ch/blob/master/LICENSE)开源许可。
