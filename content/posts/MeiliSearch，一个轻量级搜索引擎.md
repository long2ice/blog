---
title: "MeiliSearch，一个轻量级搜索引擎"
date: 2022-07-03T09:36:19+08:00
categories:
  - 程序天地
tags:
  - 搜索引擎
  - MeiliSearch
---
## 起因

很早之前就知道了这个开源搜索引擎，也一直想用在实际项目中，但是一直没有机会。最近在开发[TelSearch](http://telsearch.long2ice.io/)这个电报中文搜索引擎的时候，终于有机会可以用上了，这里简单记录一下接入流程。

## 选型

搜索引擎的选型有很多方案，最常见的就是ES，但是ES确实太重了，对于小项目来说不仅增加的硬件成本，也增加了运维成本，对于个人开发者来说确实不太合适。另外一个就是使用关系型数据库自带的全文检索功能，比如MySQL和PostgreSQL等，都有对应的功能，但是对于性能，中文分词等支持来说确实不太好。所以对于中小型项目来说，[MeiliSearch](https://www.meilisearch.com/)确实是一个不错的选择。

## 简介

[MeiliSearch](https://www.meilisearch.com/)是一个使用Rust开发的项目，目前github上有`27.7K`Star了，也是Rust语言Star最多的几个项目之一了，介于Rust语言最近越来越流行，很多Rust项目都有了越来越多的关注。看官方博客，<https://blog.meilisearch.com/meilisearch-raised-5meu-seed-fundraising/>，最近还得到了500万美元的融资，不得不感慨开源项目的出来也许就是先慢慢做大，然后寻求融资，好的项目总是会被慧眼识珠。另外，官方好像还在招聘远程开发，不过好像得熟练使用Rust，地址在这里：<https://jobs.lever.co/meili>。

## 部署

`MeiliSearch`的部署非常简单，也没有什么其他的组件，使用docker可以很容易的部署起来。官方也提供了很多种部署方式：<https://docs.meilisearch.com/learn/getting_started/quick_start.html#setup-and-installation>，包括部署脚本、docker、homebrew等等。

![deploy](/meilisearch/deploy.png)

这里的话就使用`docker-compose`来进行部署。

```yaml
version: "3"
services:
  meilisearch:
    image: getmeili/meilisearch
    network_mode: host
    restart: always
    volumes:
      - ./data:/meili_data
```

然后直接运行：`docker-compose up -d`，然后就成功地运行起来了。

## 使用

### WEB界面

当`MeiliSearch`运行起来后，默认会在`7700`端口暴露http接口，后续所有的访问，包括新增数据、搜索数据等都是通过这个http接口。另外启动之后，官方还自带了一个web界面，不过这个界面只是用来测试的，在生产环境会被关闭掉。然后你可以在这个界面试用`MeiliSearch`强大的搜索功能。

![web](/meilisearch/web.png)

### SDK

当然在实际项目中，通常会用SDK来使用对应的一些功能。官方也提供了很多语言的SDK，包括Python、PHP、Java、Go等等流行语言。对应的地址在这里：<https://docs.meilisearch.com/learn/getting_started/quick_start.html#add-documents>。

![sdk](/meilisearch/sdk.png)

### 增加文档

增加文档可以通过调用对应的接口，这里以Python为例：

先安装对应包：`pip3 install meilisearch`，然后直接调用`add_documents`方法新增文档。

```python
import meilisearch
import json

client = meilisearch.Client('http://127.0.0.1:7700')

json_file = open('movies.json')
movies = json.load(json_file)
client.index('movies').add_documents(movies)
```

### 搜索文档

搜索文档直接调用`search`方法：

```python
client.index('movies').search('botman')
```

响应数据：

```json
{
  "hits": [
    {
      "id": 29751,
      "title": "Batman Unmasked: The Psychology of the Dark Knight",
      "poster": "https://image.tmdb.org/t/p/w1280/jjHu128XLARc2k4cJrblAvZe0HE.jpg",
      "overview": "Delve into the world of Batman and the vigilante justice tha",
      "release_date": "2008-07-15"
    },
    {
      "id": 471474,
      "title": "Batman: Gotham by Gaslight",
      "poster": "https://image.tmdb.org/t/p/w1280/7souLi5zqQCnpZVghaXv0Wowi0y.jpg",
      "overview": "ve Victorian Age Gotham City, Batman begins his war on crime",
      "release_date": "2018-01-12"
    }
  ],
  "nbHits": 66,
  "exhaustiveNbHits": false,
  "query": "botman",
  "limit": 20,
  "offset": 0,
  "processingTimeMs": 12
}
```

### 实际项目实践

在实际项目中，通常会将主键ID和想要搜索的内容都导入`MeiliSearch`，然后调用搜索的时候返回对应数据的ID，然后通过ID再从数据库中获取原始数据，整个流程下来的话延迟还是比较低的。

## 资源占用

目前`TelSearch`大概十多万条数据，`MeiliSearch`占用内存大概1.6G，也还行，在可以接受的范围之内，CPU的使用也不是很高。
