---
title: "从vercel迁移到cloudflare Pages"
date: 2022-06-24T17:46:54+08:00
categories:
  - 程序天地
---
最近网站流量比之前大了一些，然后发现vercel的每个月100G流量可能不够用了，于是决定迁移到cloudflare pages。

虽然vercel界面更好看一些，然后自动部署也很方便，但是还是没有cloudflare pages不限流量香，并且自动部署github项目的操作流程也跟vercel一样。

然后把dns服务器也迁到cloudflare了，之前用的是porkbun，用porkbun主要是因为买域名便宜，然后api太拉了，还不知道为什么封了我的服务器ip，发邮件说被流量攻击了？

然后果断迁移，还是大一些的服务商稳定一些。
