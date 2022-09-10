---
title: "如何优化Python Docker镜像大小"
date: 2022-09-10T12:51:02+08:00
categories:
  - 程序天地
tags:
  - docker
  - Python
---

一直以来，使用普通方式打包的 Python 项目的 Docker 镜像都非常大，大概有一个多 G 的样子，比如下面这个例子。

```Dockerfile
FROM python:3
RUN mkdir -p /telsearch
WORKDIR /telsearch
COPY pyproject.toml poetry.lock /telsearch/
RUN pip3 install poetry
ENV POETRY_VIRTUALENVS_CREATE false
RUN poetry install --no-root --no-dev
COPY . /telsearch
```

足足有 1.5 个 G，非常的浪费磁盘空间，那么，有没有什么方法可以减小镜像大小呢？

答案就是 Docker 的多阶段构建，官方文档在这里：<https://docs.docker.com/develop/develop-images/multistage-build/>。

```Dockerfile
FROM python:3.9 as builder
RUN mkdir -p /telsearch
WORKDIR /telsearch
COPY pyproject.toml poetry.lock /telsearch/
ENV POETRY_VIRTUALENVS_CREATE false
RUN pip3 install pip --upgrade && pip3 install poetry --upgrade --pre && poetry install --no-root --only main

FROM python:3.9-slim
WORKDIR /telsearch
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY . /telsearch
CMD ["uvicorn" ,"telsearch.app:app", "--host", "0.0.0.0"]
```

使用了新的方式打包之后，镜像大小减小到了 284MB，减小了非常之多。
