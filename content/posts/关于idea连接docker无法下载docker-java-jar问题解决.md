---
title: 关于idea连接docker无法下载docker-java.jar问题解决
categories: 
  - 疑难杂记
date: 2017-05-12 00:05:09
tags: 
  - docker
---
最近使用idea连接docker是遇到一个问题，就是一直无法连接，提示是无法从maven的中央仓库下载docker-java.jar。但是我的settings.xml已经更改为阿里云镜像了，那是因为什么呢？网上百度了一番没有找到答案，我猜测idea的maven默认使用的maven仓库并不是我们自己配置的，应该是idea自己确定的。
于是寻找了一番，最终定位到这个文件：
![这里写图片描述](http://img.blog.csdn.net/20170423153110982?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcXFfMjMwOTAwNTM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
打开查看一番，果不然奇然是定义好的jar下载的仓库地址，于是改成阿里云的地址，像这样
![这里写图片描述](http://img.blog.csdn.net/20170423153230358?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcXFfMjMwOTAwNTM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

再次连接docker，速度嗖嗖的就上来了，成功解决该问题。