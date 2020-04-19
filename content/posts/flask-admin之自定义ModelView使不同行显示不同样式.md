---
title: flask-admin之自定义ModelView使不同行显示不同样式
categories:
  - 程序猿之路
date: 2019-03-18 21:12:25
tags:
  - flask
  - flask-admin
---

## 前言

如果有使用过[django-suit]( https://github.com/darklow/django-suit )—一个django admin的美化框架，这个框架的话，其admin设置中可以使用suit_row_attributes这个方法，在后台表单中设置表单列表中不同的行有不同的属性。这个方法在有些情况下很有用，比如说订单列表可以根据不同的订单状态在表单中呈现不同的样式，比如支付成功的可以设置为bootstrap的table-success，支付失败的可以设置为table-danger，这样在查看后台表单的时候可以更加一目了然。代码类似于下面这样：

```python

    def suit_row_attributes(self, obj->Order, request):
        css = {
            2: 'table-success',
        }.get(obj.status)
        if css:
            return {'class': css}
            
```

这样在订单状态为2的一行的时候，该行会显示为绿色。

![表格显示]( https://raw.githubusercontent.com/long2ice/blog/master/resources/images/table-css.png "表格显示" )

## 关于flask-admin

由于最近在使用flask这个框架，对应的admin管理使用的是[flask-admin]( https://flask-admin.readthedocs.io/en/latest/introduction/ )，同样需要像django-suit这样设置row attributes。

关于django和flask，flask是一个微服务框架，本身只提供了基本的请求响应处理等功能，并且可以很快的搭建一个rest api服务，但是如果需要其他的，比如ORM、权限管理、后台管理等扩展功能，就需要一个一个集成第三方扩展；而django提供的是一站式全方位解决方案，包含admin管理、ORM、权限控制、模板引擎等，具体该使用哪个框架，需要视业务场景而定。

回到flask-admin，这个扩展的功能还是比较强大的，包含了model view显示，action等功能，并且可以很方便的自定义。然而关于上面提到的需求，官方是没有自带的解决方案的，所以就只能重写list.html这个模板了。

## 解决方案

官方文档里有写：
> To override any of the built-in templates, simply copy them from the Flask-Admin source into your project’s templates/admin/ directory. As long as the filenames stay the same, the templates in your project directory should automatically take precedence over the built-in ones.

就是说，如果你要重写模板，就简单的把flask-admin自带的模板复制到templates/admin/对应的模板下面，然后修改就行了，自已的模板优先级要更高一些。

然后复制list.html这个模板到flask的templates/admin/model目录下面，找到其对应table的地方，在115行这里：

![](http://cdn.long2ice.cn/20190318221148.png)


明显这里tr没有任何的class和可供操作的地方，所以只能重写模板了。

重写后代码如下，flask使用的是jinja2模板语法：

![](http://cdn.long2ice.cn/20190318221321.png)


然后在ModelView里面自定义ModelView:


```python

class BaseModelView(ModelView):
    column_display_pk = True

    def is_accessible(self):
        return current_user.is_authenticated

    @abc.abstractmethod
    def row_attributes(self, obj):
        pass

```

其他的ModelVIew继承这个基类就行了，row_attributes这个方法跟django-suit框架使用方法一样：

```python

    def row_attributes(self, obj):
        if obj.status == 2:
            return {'class': 'success'}

```

当该行的obj的status为2时，table的该row就会有success的样式了。

## 结语

总的来讲，flask-admin这个扩展还是很不错的，其可定制化很强，ModelView有很多可配置参数，具体可以查看官方文档。