---
title: "开发了一个实时同步数据库到meilisearch的工具"
date: 2023-07-29T13:04:29+08:00
categories:
  - 程序天地
tags:
  - meilisearch
  - MySQL
  - PostgreSQL
  - MongoDB
  - ETL
---

## 前言

在我的个人项目中很多地方都使用到了 meilisearch，之前也写了一篇博客介绍了一下 meilisearch 的使用，可以参考一下：[MeiliSearch，一个轻量级搜索引擎](/2022/07/meilisearch一个轻量级搜索引擎/)。

之前的话就简单粗暴地其了一个定时任务，每隔一段时间就从数据库中同步一次数据到 meilisearch，这样的话就会有一些问题：

- 数据不实时。
- 每次都是全量同步，效率很低。

所以希望能有一个能实时增量同步数据库，类似 MySQL 的，到 meilisearch 的工具。在 GitHub 上搜了一圈，发现没有什么好用的，于是打算自己写一个。

## 项目地址

- <https://github.com/long2ice/meilisync>, 命令行版本。
- <https://github.com/long2ice/meilisync-admin>，在命令行版本的基础上，增加了一个 web 管理界面，可以动态添加同步任务，查看同步状态等。

## 预览

![meilisync-admin](/meilisearch/meilisync-admin.png)

## 技术栈

- 前端：React + daisyui
- 后端：FastAPI + TortoiseORM + MySQL

## 架构

目前支持三种数据库：

- MySQL，使用 binlog 来实现。
- PostgreSQL，使用 logical replication 来实现。
- MongoDB，使用 change stream 来实现。

最初的版本只是实现了命令行的功能，通过加载配置文件，然后启动一个进程，然后通过 binlog 类似的技术来实现实时地增量同步。

## 更进一步

命令行版本可以满足基本的需求，但是还是有一些不足的地方：

- 修改配置需要重启。
- 无法动态添加同步任务。
- 只支持单实例。

于是在命令行版本的基础上，增加了一个 web 管理界面，可以动态添加同步任务，查看同步状态，以及增加了登录功能。

## 遇到的问题

- 遇到错误如实例连不上，重启进程之类的会丢失数据。
- 全量刷新数据的实时不能影响线上业务。
- MySQL binlog 连接长时间后丢失。
- 以及一些其他的问题。
