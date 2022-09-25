---
title: "分享一个不错Uptime开源监控项目"
date: 2022-09-25T12:12:05+08:00
categories:
  - 程序天地
tags:
  - Uptime
  - 开源
  - 监控
---

## 简介

之前一直使用[gatus](https://github.com/TwiN/gatus)来监控一些服务，但是最近发现了一个更强大的开源项目[uptime-kuma](https://github.com/louislam/uptime-kuma)，web 界面功能更加丰富，遂决定转向`uptime-kuma`。

## 项目地址

<https://github.com/louislam/uptime-kuma>

![uptime-kuma](https://camo.githubusercontent.com/9674a2b1b7d094b060fd79e6df7dca10b86a484ce6015b2668cff768dfc786ee/68747470733a2f2f757074696d652e6b756d612e7065742f696d672f6461726b2e6a7067)

## 安装

最方便的方式就是使用`docker-compose`。

```yaml
version: "3"
services:
  uptime-kuma:
    image: louislam/uptime-kuma
    container_name: uptime-kuma
    volumes:
      - uptime-kuma-data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
    network_mode: host

volumes:
  uptime-kuma-data:
```

## 支持多种类型监控

![type](/uptime/type.png)

- http
- ping
- tcp
- dns
- docker
- ...

## 支持多种类型告警

![type](/uptime/alert.png)

- 飞书
- 邮件
- Telegram
- 企业微信
- webhook
- ...

## 最后

总的使用下来还是非常不错的。
