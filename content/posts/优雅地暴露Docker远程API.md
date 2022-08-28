---
title: "优雅地暴露Docker远程API"
date: 2022-08-28T16:39:03+08:00
categories:
  - 程序天地
tags:
  - docker
---

## 起因

最近在使用 portainer 管理多个机器上的 Docker 的时候，需要开启 docker 的远程 api 访问，但是如果直接开启的话会直接暴露到公网，容易被扫端口然后入侵机器，而自己生成 tls 证书什么的又比较麻烦，于是在 Google 搜索中发现了一个项目，https://github.com/kekru/docker-remote-api-tls。

## 简介

简单看了一下项目的介绍，其实就是通过容器内部的 nginx 对挂载进容器的`docker.sock`做了反代，并且提供了自动生成证书的功能，还不错，虽然只有几十颗星，不过正是我想要的。

## 部署

项目本身是一个 docker 项目，使用`docker-compose`就可以启动，并且项目里面也提供了示例。

```yaml
version: "3.4"
services:
  remote-api:
    image: kekru/docker-remote-api-tls:v0.4.0
    ports:
      - 2376:443
    environment:
      - CREATE_CERTS_WITH_PW=supersecret
      - CERT_HOSTNAME=remote-api.example.com
    volumes:
      - <local cert dir>:/data/certs
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

- CREATE_CERTS_WITH_PW： 证书密码，随便设置一个就行。
- CERT_HOSTNAME：证书的域名，需要和 portainer 里面的域名保持一直，不过好像不支持 ip，只能用域名。

然后执行`docker compose up -d`就启动了。

## 证书

启动后会在`<local cert dir>`生成证书文件，使用`client`子目录下面的文件就可以通过 api 连接了。

目录结构大概是这样：

```shell
❯ tree certs/
certs/
├── ca-cert.pem
├── ca-key.pem
├── client
│   ├── ca.pem
│   ├── cert.pem
│   └── key.pem
├── server-cert.pem
└── server-key.pem

1 directory, 7 files
```
