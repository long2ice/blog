---
title: "xtrabackup，强大的 MySQL 备份工具"
date: 2023-07-31T16:25:40+08:00
categories:
  - 程序天地
tags:
  - MySQL
  - 备份
---

## 前言

一直在寻找一个最适合自己的 MySQL 备份方案，毕竟数据无价，来来去去也使用了很多种方案，在此记录一下。

## 使用云数据库

这是最省心的方案了，云数据库比如阿里云的 RDS，腾讯云的云数据库都自带了备份功能，完全不用自己操心，但是这种方案的缺点也很明显，就是价格太贵了，对于个人开发者来说，成本还是太高了，同配置的云数据库比服务器要贵很多。

之前也用了腾讯云最低配置的云数据库，一个月要一百多，放弃了。

## 自建 MySQL 主从

之前也尝试了在阿里云买了两台轻量服务器组了主从数据库，也用了一段时间，虽然很便宜，但是实际用起来还是有一些问题。

- 阿里云轻量服务器的磁盘性能很低，不适合搭建数据库，所以我组了主从并且搭配 proxysql 来做读写分离。
- 阿里云轻量服务器的磁盘太小，后面数据量多了之后，磁盘空间就不够用了，而升级更高配置的话成本又变高了。

## 使用廉价 VPS 加 mysqlpump

有很多小的 VPS 商家卖的 VPS 比起大厂的更便宜，而且性能更高，但是缺点就是没有大厂稳定，而且有丢失数据的风险，所以定时备份数据就很重要。

之前我使用的是 mysqlpump 加定时任务的方式，为此我还专门写了个项目 <https://github.com/long2ice/databack>，将备份的数据上传到对象存储，但是后面发现这个方案也有问题，就是数据量大了以后不论是备份或者上传到对象存储花费的时间都很长，更不用说恢复数据的时间了，完全没办法使用在生产环境。

## 使用廉价 VPS 加 xtrabackup

这是我最终使用的方案，使用 xtrabackup 备份数据，然后上传到对象存储。xtrabackup 备份数据非常快，它是基于物理备份的，并且备份的时候不会影响到线上数据库。同时它也支持增量备份，这样除了第一次上传全量备份的时候会花费一些时间，后面的备份都会很快。

贴一下使用的脚本：

```bash
#!/bin/bash

# 备份函数
function backup() {
    cp /etc/mysql/mysql.conf.d/mysqld.cnf ./
    # 检查备份目录是否存在
    if [ ! -d "./backups" ]; then
        mkdir ./backups
    fi

    # 检查是否存在全量备份
    if [ -z "$(ls -A ./backups)" ]; then
        # 执行全量备份命令
        xtrabackup --backup --compress=zstd --target-dir=./backups/base
        echo "全量备份完成。"
    else
        # 执行增量备份命令
        xtrabackup --backup --compress=zstd --target-dir=./backups/inc-$(date '+%Y-%m-%d_%H:%M:%S') --incremental-basedir=$(ls -d ./backups/* | tail -n 1)
        echo "增量备份完成。"
    fi
    rclone sync /root/backup/mysql greencloud:/backup/mysql/prod
}

# 恢复函数
function restore() {
    # 遍历备份目录解压缩
    for d in backups/*/; do
        xtrabackup --decompress --target-dir=$d
    done
    # 准备恢复
    for d in backups/*/; do
        if [ $d == "backups/base/" ]; then
            xtrabackup --prepare --apply-log-only --target-dir=$d
        else
            # if is last dir
            if [ $d == $(ls -d backups/*/ | tail -n 1) ]; then
                xtrabackup --prepare --target-dir=./backups/base --incremental-dir=$d
            else
                xtrabackup --prepare --apply-log-only --target-dir=./backups/base --incremental-dir=$d
            fi
        fi
    done
    # 执行恢复
    xtrabackup --copy-back --target-dir=./backups/base
    echo "恢复完成。"
}

case "$1" in
backup)
    backup
    ;;
restore)
    restore
    ;;
*)
    echo "Usage: $0 {backup|restore}"
    ;;
esac
```

完事之后直接 crontab 挂一个定时任务就 OK 了。

```bash
0 2 * * * cd /root/backup/mysql && ./backup.sh backup >> /dev/null
```
