---
title: "FastAPI-Admin，开箱即用的后台管理面板"
date: 2021-06-25T22:19:28+08:00
categories:
  - 程序天地
tags:
  - FastAPI
  - admin
---

## 简介

FastAPI-Admin 是一个基于 FastAPI 与 TortoiseORM 的开箱即用的后台管理面板，UI 框架使用了[tabler](https://preview.tabler.io/)，仅需要少量配置，即可快速搭建一个 CURD 管理台，类似于 Django Admin。

项目地址：<https://github.com/fastapi-admin/fastapi-admin>

线上 DEMO：<https://fastapi-admin.long2ice.cn/admin/login>

用户名：`admin`

密码：`123456`

## 预览

![登录界面](/fastapi-admin/login.png)

![主页](/fastapi-admin/dashboard.png)

## 特性

- 开箱即用，配置丰富。
- 集成登录、验证码、权限控制。
- 易于扩展，自定义。
- 内置多种组件，功能丰富的 CRUD 界面。
- 其它更多特性。

## 开发

FastAPI-Admin 基于 FastAPI 与 TortoiseORM，使用 jinja2 渲染前端界面。最早期的版本是使用前后端分离，通过 rest 协议进行通信，前端框架与查询协议直接来源于另一个开源项目，后来由于不便于扩展、不熟悉等原因放弃，并基于 tabler ui 开发了现在的版本。实现过程中参考了 Django Admin，通过后端进行资源配置，渲染菜单，界面等。并且实现了多种展示组件、编辑组件、筛选组件等。

除此之外，Pro 版本还实现了基于资源读写的权限控制，包括管理员、角色、权限三种对象。

## 文档

文档地址：<https://fastapi-admin-docs.long2ice.cn>

目前英文文档更全面一些，中文文档还待编写中。
