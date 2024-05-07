---
title: "k8s下MySQL完美的备份方案"
date: 2023-12-27T09:57:30+08:00
categories:
  - 程序天地
tags:
  - MySQL
  - 备份
---

## 前言

此前一直在使用 `mysqlshell` 来备份部署在 k8s 上的 MySQL，虽然这个工具比起 mysqlpump 来说要快很多，支持多线程、可以直接备份到远程 s3 等，但是后面使用过程中也陆陆续续发现了一些问题：

### CPU 占用过高

由于开启了多个核来并行执行提升速度，所以每次执行备份的时候 CPU 只能在凌晨时间，这样极端情况下可能会导致丢失一天的数据。

### 无法增量备份

每次备份的时候都是全量备份，这样也会导致备份的数据占用空间过大。

### 恢复数据慢

由于 `mysqlshell` 备份的数据是逻辑备份，所以恢复数据的时候会很慢。如果另外两个问题还是可以忍受的话，这个问题是无法忍受的。比如在进行服务器迁移的时候，系统恢复的时间就会很长。

## 使用 xtrabackup

之前也曾调研过 xtrabackup，[xtrabackup，强大的 MySQL 备份工具](https://blog.long2ice.io/2023/07/xtrabackup%E5%BC%BA%E5%A4%A7%E7%9A%84-mysql-%E5%A4%87%E4%BB%BD%E5%B7%A5%E5%85%B7/)，但是由于 k8s 下的 MySQL 是使用的 PVC，所以无法直接使用 xtrabackup 来备份。后面实在忍受不了 `mysqlshell` 的问题，所以又重新研究了一下，最终找到了一个比较完美的解决方案。

## 打包一个基础镜像

#### Dockerfile

这个 Dockerfile 里面安装了 xtrabackup 和 rclone，rclone 是一个支持多种对象存储的命令行工具，可以用来将备份的数据上传到对象存储等。然后启动的时候会执行 `entrypoint.sh`，这个脚本会启动一个 cron 定时任务，每小时执行一次 `backup.sh`，这个脚本会根据是否存在全量备份来执行全量备份或者增量备份，然后将备份的数据上传到对象存储。

```Dockerfile
FROM ubuntu
RUN apt update && \
    apt install -y wget cron lsb-release curl gnupg2 zstd unzip && \
    wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb && \
    dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb && \
    apt update && \
    percona-release enable-only tools release && \
    apt update && \
    apt install percona-xtrabackup-80 -y && \
    rm -rf percona-release_latest.$(lsb_release -sc)_all.deb
RUN curl https://rclone.org/install.sh | bash
COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /backup.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

#### backup.sh

这个脚本执行了实际的备份操作，备份的数据会存放在 `/backup` 目录下，然后会将备份的数据同步到 s3 上。

```bash
#!/bin/bash

backup_dir=/backup
my_conf=${MYSQL_CONF:-/etc/mysql/my.cnf}
mkdir -p $backup_dir
mkdir -p /root/.config/rclone
echo "[s3]
type = s3
provider = $S3_PROVIDER
access_key_id = $S3_ACCESS_KEY_ID
secret_access_key = $S3_SECRET_ACCESS_KEY
region = $S3_REGION
endpoint = $S3_ENDPOINT
" > /root/.config/rclone/rclone.conf

function backup() {
    if [ -z "$(ls -A $backup_dir)" ]; then
        xtrabackup --defaults-file="$my_conf" --backup --compress=zstd --target-dir=$backup_dir/base
        echo "全量备份完成！"
    else
        xtrabackup --defaults-file="$my_conf" --backup --compress=zstd --target-dir=$backup_dir/inc-"$(date '+%Y-%m-%d_%H:%M:%S')" --incremental-basedir="$(ls -d $backup_dir/* | tail -n 1)"
        echo "增量备份完成！"
    fi
    echo "开始同步到s3..."
    echo "rclone sync $backup_dir s3:/$S3_BUCKET/$S3_PREFIX $RCLONE_OPTIONS" | bash
}

function restore() {
    for d in "$backup_dir"/*/; do
        xtrabackup --defaults-file="$my_conf" --decompress --target-dir="$d"
    done
    for d in "$backup_dir"/*/; do
        if [ "$d" == "$backup_dir/base/" ]; then
            xtrabackup --defaults-file="$my_conf" --prepare --apply-log-only --target-dir="$d"
        else
            if [ "$d" == "$(ls -d $backup_dir/*/ | tail -n 1)" ]; then
                xtrabackup --defaults-file="$my_conf" --prepare --target-dir=$backup_dir/base --incremental-dir="$d"
            else
                xtrabackup --defaults-file="$my_conf" --prepare --apply-log-only --target-dir=$backup_dir/base --incremental-dir="$d"
            fi
        fi
    done
    xtrabackup --defaults-file="$my_conf" --copy-back --target-dir=$backup_dir/base
    echo "恢复完成！"
}

case "$1" in
backup)
    backup
    ;;
restore)
    restore
    ;;
*)
    echo "无效的参数"
    ;;
esac
```

#### entrypoint.sh

这个脚本会启动一个 cron 定时任务，每小时执行一次 `backup.sh`。

```bash
#!/bin/bash

echo "backup cron running..."
env >> /etc/environment
touch /var/log/backup.log
echo "0 * * * * /backup.sh backup > /proc/1/fd/1 2>/proc/1/fd/2" | crontab -
cron -f -l 2
```

## 部署为 k8s MySQL 的 sidecar

k8s 的 sidecar 提供了多个容器共享一个 pod 的功能，这样我们就可以将这个备份容器部署到 MySQL 的 pod 中，然后通过共享 volume 的方式来访问 MySQL 的数据目录。由于我是使用 bitnami/mysql，所以以下的配置是基于这个 chart 的。

```yaml
primary:
  configuration: |-
    [xtrabackup]
    password={{ .Values.mysql.password }}
  extraVolumes:
    - name: socket # 这个 volume 用来共享 MySQL 的 socket 文件
      emptyDir: {}
  extraVolumeMounts:
    - name: socket
      mountPath: /opt/bitnami/mysql/tmp
  sidecars:
    - name: mysql-backup
      image: long2ice/mysql-backup
      imagePullPolicy: Always
      env:
        - name: S3_PROVIDER
          value: {{ .Values.s3.provider }}
        - name: S3_ACCESS_KEY_ID
          value: {{ .Values.s3.access_key }}
        - name: S3_SECRET_ACCESS_KEY
          value: {{ .Values.s3.secret_key }}
        - name: S3_ENDPOINT
          value: {{ if .Values.s3.secure }}https{{else}}http{{end}}://{{ .Values.s3.endpoint }}
        - name: S3_BUCKET
          value: {{ .Values.mysql.backup_bucket }}
        - name: S3_PREFIX
          value: {{ .Values.mysql.backup_prefix }}
        - name: RCLONE_OPTIONS
          value: "-P --transfers=50 --fast-list"
        - name: MYSQL_CONF
          value: /opt/bitnami/mysql/conf/my.cnf
      volumeMounts:
        - name: data # 这个 volume 用来共享 MySQL 的数据目录
          mountPath: /bitnami/mysql
        - name: config # 这个 volume 用来共享 MySQL 的配置文件
          mountPath: /opt/bitnami/mysql/conf/my.cnf
          subPath: my.cnf
        - name: socket # 这个 volume 用来共享 MySQL 的 socket 文件
          mountPath: /opt/bitnami/mysql/tmp
```

## 完结

这样就可以完美的解决 MySQL 的备份问题了，备份的数据会存放在 s3 上，如果需要恢复的话，只需要将备份的数据下载到本地，然后执行 `backup.sh restore` 就可以了。
