---
title: "科学上网与VPN办公的完美结合"
date: 2023-03-20T16:48:25+08:00
categories:
  - 职场生活
tags:
  - Clash
  - OpenVPN
---

## 前言

工作中很多时候需要使用到 VPN 来访问企业内网，但是同时又需要科学上网，这两个同时开启的时候会出现冲突。所以之前老是要切换来切换去，很麻烦，最近终于找到了完美的解决办法。

## 准备工作

- Clash，<https://github.com/Dreamacro/clash>，强大的代理分流工具。
- Docker，<https://www.docker.com>，用来跑 openvpn 的容器。将 openvpn 跑在容器里可以防止污染宿主机。

## 启动 openvpn

将 openvpn 的配置文件放在`./config`目录下，然后执行`docker-compose up -d`启动 openvpn。该容器会将 openvpn 转发到 socks5 代理，端口为 1080。

```yml
version: "3"
services:
  openvpn:
    image: curve25519xsalsa20poly1305/openvpn-socks5
    restart: always
    cap_add:
      - NET_ADMIN
    ports:
      - 1080:1080
    environment:
      - OPENVPN_CONFIG=/config/config.ovpn
    volumes:
      - ./config:/config
    devices:
      - /dev/net/tun
```

## 启动 clash

主要是 rules 部分的配置。

```yml
proxies:
  - name: "openvpn"
    type: socks5
    server: 192.168.123.205
    port: 1080
rules:
  - IP-CIDR,172.26.0.0/16,openvpn # 你的公司内网网段
  - DOMAIN-SUFFIX,xxx.cn,openvpn # 你的公司内网域名
```

然后将 clash 设置为 rule 模式，一切 OK，just enjoy it!
