---
title: flask-admin之自定义ModelView使不同行显示不同样式
categories:
  - 程序天地
date: 2019-03-18 21:12:25
tags:
  - flask
  - flask-admin
---

## 前言

如果有使用过[django-suit](https://github.com/darklow/django-suit)—一个 django admin 的美化框架，这个框架的话，其 admin 设置中可以使用 suit_row_attributes 这个方法，在后台表单中设置表单列表中不同的行有不同的属性。这个方法在有些情况下很有用，比如说订单列表可以根据不同的订单状态在表单中呈现不同的样式，比如支付成功的可以设置为 bootstrap 的 table-success，支付失败的可以设置为 table-danger，这样在查看后台表单的时候可以更加一目了然。代码类似于下面这样：

```python

    def suit_row_attributes(self, obj->Order, request):
        css = {
            2: 'table-success',
        }.get(obj.status)
        if css:
            return {'class': css}

```

这样在订单状态为 2 的一行的时候，该行会显示为绿色。

![表格显示](/flask-admin/table-css.png "表格显示")

## 关于 flask-admin

由于最近在使用 flask 这个框架，对应的 admin 管理使用的是[flask-admin](https://flask-admin.readthedocs.io/en/latest/introduction/)，同样需要像 django-suit 这样设置 row attributes。

关于 django 和 flask，flask 是一个微服务框架，本身只提供了基本的请求响应处理等功能，并且可以很快的搭建一个 rest api 服务，但是如果需要其他的，比如 ORM、权限管理、后台管理等扩展功能，就需要一个一个集成第三方扩展；而 django 提供的是一站式全方位解决方案，包含 admin 管理、ORM、权限控制、模板引擎等，具体该使用哪个框架，需要视业务场景而定。

回到 flask-admin，这个扩展的功能还是比较强大的，包含了 model view 显示，action 等功能，并且可以很方便的自定义。然而关于上面提到的需求，官方是没有自带的解决方案的，所以就只能重写 list.html 这个模板了。

## 解决方案

官方文档里有写：

> To override any of the built-in templates, simply copy them from the Flask-Admin source into your project’s templates/admin/ directory. As long as the filenames stay the same, the templates in your project directory should automatically take precedence over the built-in ones.

就是说，如果你要重写模板，就简单的把 flask-admin 自带的模板复制到 templates/admin/对应的模板下面，然后修改就行了，自已的模板优先级要更高一些。

然后复制 list.html 这个模板到 flask 的 templates/admin/model 目录下面，找到其对应 table 的地方，在 115 行这里：

![list](/flask-admin/list.webp)

明显这里 tr 没有任何的 class 和可供操作的地方，所以只能重写模板了。

重写后代码如下，flask 使用的是 jinja2 模板语法：

![list rewrite](/flask-admin/list-rewrite.webp)

然后在 ModelView 里面自定义 ModelView:

```python

class BaseModelView(ModelView):
    column_display_pk = True

    def is_accessible(self):
        return current_user.is_authenticated

    @abc.abstractmethod
    def row_attributes(self, obj):
        pass

```

其他的 ModelVIew 继承这个基类就行了，row_attributes 这个方法跟 django-suit 框架使用方法一样：

```python

    def row_attributes(self, obj):
        if obj.status == 2:
            return {'class': 'success'}

```

当该行的 obj 的 status 为 2 时，table 的该 row 就会有 success 的样式了。

## 结语

总的来讲，flask-admin 这个扩展还是很不错的，其可定制化很强，ModelView 有很多可配置参数，具体可以查看官方文档。
