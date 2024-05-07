---
title: "一个由于MySQL Binlog同步问题导致的bug"
date: 2020-10-26T22:01:13+08:00
categories:
  - 程序天地
---

最近在项目中遇到了一个很奇怪的 bug，从发现到解决一共持续了一周左右的时间。

bug 现象：插入一条语句后在执行 select，会报查询不到记录，但是该 bug 只偶尔复现，频率很低。

刚开始的时候尝试了很多种方法，猜测是不是 ORM 框架问题，或者是 MySQL 版本问题，但是经过测试都不会复现。并且由于出现的概率很低，很不好 debug。

在问题的代码周围打了很多 log，也还是没有找到问题所在。

就在有一次我上厕所的时候灵机一动，联想到我们用的是阿里云的读写分离数据库，猜测是否是因为 MySQL 同步延迟导致的？

查询了阿里云文档后，地址为[https://help.aliyun.com/knowledge_detail/41767.html?spm=5176.11065259.1996646101.searchclickresult.3d3c31d8pXWGBr](https://help.aliyun.com/knowledge_detail/41767.html?spm=5176.11065259.1996646101.searchclickresult.3d3c31d8pXWGBr)，最终确定正是这个问题。

解决方案有两种，一种是在同一事务中支持先写入再读取操作，另一种是使用单实例，放弃读写分离。
