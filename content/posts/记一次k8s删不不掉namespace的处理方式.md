---
title: "记一次k8s删不不掉namespace的处理方式"
date: 2020-06-17T17:10:32+08:00
categories:
  - 疑难杂记
tags:
  - k8s
---

在使用 k8s 的时候，偶然遇到了一个问题，就是死活删不掉 namespace。这个 namespace 处于 Terminating 状态已经十多天，虽然对 k8s 本身并没有什么影响，但是对于我这种强迫症来说很痛苦。

网上也查询了很多种处理方式，大部分都是讲 namespace 以 json 格式导出，然后删除`spec`部分，再调用 rest 接口，然而我一直都没有成功。

最后不知道在哪里看到一篇文章，直接调用 etcdctl，执行`docker exec -it etcd etcdctl del /registry/namespaces/delete-me`，因为我的 etcd 是一容器安装的，最终删除成功，治好了强迫症。
