---
title: "Awesome项目搜索网站"
date: 2022-07-08T15:42:26+08:00
categories:
  - 程序天地
tags:
  - 搜索引擎
  - Awesome
---
## 简介

项目地址：<https://awesome.long2ice.io>

最近突发奇想开发了一个Awesome项目搜索网站，整个网站看起来样子长这样。

![awesome](/awesome/awesome.png)

为什么要开发一个这个呢？因为Github上有很多Awesome类型的项目，其实就是针对某一种类型的项目做一个聚合，然后使用markdown展示出来。但是感觉这样的话其实并不友好，也不能够搜索什么的，于是就有了这个项目，随便又学习了一下React Mui和Go异步队列。

## 项目架构

整个项目也是前后端分离的，前端主要使用React + Mui。
而后端主要使用:

- [Fibers](https://github.com/long2ice/fibers)，一个我自己基于Fiber+Swagger封装的提供类似FastAPI开发体验的框架。
- [Asynq](https://github.com/hibiken/asynq)，一个Go的异步任务队列，也自带了WEB界面和命令行工具。
- [ent](https://entgo.io/)，一个Go的ORM框架，由Facebook开发。

## 部署

整个项目后端是直接使用Docker部署的，而前端是使用CloudFlare的Pages服务，不得不说很好用，主要还是不限流量。
