---
title: "记一次 k3s DNS 问题解决"
date: 2025-09-24T15:55:45+08:00
categories:
  - 疑难杂记
tags:
  - k3s
  - DNS
---

之前搭建了一个单节点的 k3s 集群，运行良好，最近又购得一台同区域的服务器，打算把原本 k3s 扩展为多节点集群。

按照文档 <https://docs.k3s.io/networking/distributed-multicloud> 部署好后，发现集群内 DNS 域名解析有一个奇怪的现象。

pod 内时不时会报错 dns 解析失败，导致各种内部或者外部请求超时。

一开始是以为 coredns 压力太大，扩展成多个副本，并且加上了 localdns 缓存，但是问题依旧存在。

又怀疑是不是 `Embedded k3s multicloud solution` 的问题，考虑换成另一种方案 `Integration with the Tailscale VPN provider (experimental)`？

后面在 debug 的过程中发现问题出现的很有规律，几次解析很快，然后突然变慢一次，经过跟 `chatgpt` 的交流，最后终于定位到问题，原来是由于 `/proc/sys/net/netfilter/nf_conntrack_max` 满了。因为之前的机器配置很高，所以这个配置的默认值也很大，不会有这个问题，但是新的机器配置比较低，所以这个配置的默认值比较小，导致这个机器上的 pod 在解析 dns 的时候时不时会超时。

解决办法很简单，就是调大这个配置的值即可。

```bash
echo 'net.netfilter.nf_conntrack_max=1000000' >> /etc/sysctl.conf
sysctl -p
```

问题就解决了，pod 内解析 dns 恢复正常。
