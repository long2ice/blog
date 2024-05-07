---
title: "FastAPI-Admin，快速搭建基于fastapi与tortoise-orm的管理后台"
date: 2020-05-05T17:15:14+08:00
categories:
  - 程序天地
tags:
  - FastAPI
  - admin
  - tortoise-orm
---

## 简介

FastAPI-admin 是一个基于[fastapi](https://github.com/tiangolo/fastapi)和
[tortoise-orm](https://github.com/tortoise/tortoise-orm)和[rest-admin](https://github.com/wxs77577/rest-admin)的后台管理面板。

FastAPI-admin 提供了开箱即用的 CRUD，只需少量的配置。

## 在线 demo 地址

[https://fastapi-admin.long2ice.io](https://fastapi-admin.long2ice.io/)

- 用户名: `admin`
- 密码: `123456`

数据会每天进行重置。

## 预览

![image](https://github.com/long2ice/fastapi-admin/raw/master/images/login.png)

![image](https://github.com/long2ice/fastapi-admin/raw/master/images/list.png)

![image](https://github.com/long2ice/fastapi-admin/raw/master/images/view.png)

![image](https://github.com/long2ice/fastapi-admin/raw/master/images/create.png)

## 快速开始

### 本地运行样例

查看[examples](https://github.com/long2ice/fastapi-admin/tree/master/examples)。

1. 执行`git clone https://github.com/long2ice/fastapi-admin.git`.
2. 创建数据库`fastapi-admin`并且导入`examples/example.sql`。
3. 执行`python setup.py install`。
4. 执行`env PYTHONPATH=./ DATABASE_URL=mysql://root:123456@127.0.0.1:3306/fastapi-admin python3 examples/main.py`：

   ```log
   INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
   INFO:     Started reloader process [89005]
   INFO:     Started server process [89009]
   INFO:     Waiting for application startup.
   INFO:     Tortoise-ORM startup
       connections: {'default': 'mysql://root:123456@127.0.0.1:3306/fastapi-admin'}
       apps: {'models': {'models': ['examples.models'], 'default_connection': 'default'}}
   INFO:     Tortoise-ORM started, {'default': <tortoise.backends.mysql.client.MySQLClient object at 0x110ed6760>}, {'models': {'Category': <class 'examples.models.Category'>, 'Product': <class 'examples.models.Product'>, 'User': <class 'examples.models.User'>}}
   INFO:     Tortoise-ORM generating schema
   INFO:     Application startup complete.
   ```

5. 执行`cd front && npm install && npm run serve`:

   ```log
   App running at:
   - Local:   http://localhost:8080/
   - Network: http://192.168.10.23:8080/

   Note that the development build is not optimized.
   To create a production build, run yarn build.
   ```

打开`http://localhost:8080/`进行体验。

### 后端代码集成

```shell
pip3 install fastapi-admin
```

```Python
fast_app = FastAPI()

register_tortoise(fast_app, config=TORTOISE_ORM, generate_schemas=True)

fast_app.mount('/admin', admin_app)

@fast_app.on_event('startup')
async def startup():
    admin_app.init(
        user_model='User',
        tortoise_app='models',
        admin_secret='test',
        permission=True,
        site=Site(...)
    )
```

### 前端

执行`cd front && cp .env.example .env` 并且对应更改，然后执行`npm run serve`。

## 特性

### 内置授权与权限控制

继承 `fastapi_admin.models.User`增加自定义自动，必须包含`is_active`和`is_superuser`。

必须导入`Permission`和`Role`，导入之后什么也不用做。

```python
from fastapi_admin.models import User as AdminUser, Permission, Role

class AdminUser(AdminUser,Model):
    is_active = fields.BooleanField(default=False, description='Is Active')
    is_superuser = fields.BooleanField(default=False, description='Is Superuser')
    status = fields.IntEnumField(Status, description='User Status')
    created_at = fields.DatetimeField(auto_now_add=True)
    updated_at = fields.DatetimeField(auto_now=True)
```

然后注册权限和创建超级管理员：

```shell
$ fastapi-admin -h
usage: fastapi-admin [-h] -c CONFIG {register_permissions,createsuperuser} ...

optional arguments:
  -h, --help            show this help message and exit
  -c CONFIG, --config CONFIG
                        Tortoise-orm config dict import path,like settings.TORTOISE_ORM.

subcommands:
  {register_permissions,createsuperuser}
```

设置`permission=True`激活权限控制模块：

```python
admin_app.init(
    user_model='AdminUser',
    admin_secret='123456',
    models='examples.models',
    permission=True,
    site=Site(
        ...
    )
)
```

### 枚举支持

在 tortoise-orm 定义枚举字段时，可以继承`fastapi_admin.enums.EnumMixin`并且实现`choices()` 方法，FastAPI-admin 会自动读取并且在前端渲染一个`select`控件。

```python
class Status(EnumMixin, IntEnum):
    on = 1
    off = 2

    @classmethod
    def choices(cls):
        return {
            cls.on: 'ON',
            cls.off: 'OFF'
        }
```

### 友好的字段名

FastAPI-admin 会自动从字段读取`description`属性并且展示在前端。

### 外键支持

如果外键未在`menu.raw_id_fields`定义，FastAPI-admin 会自动读取所有的关联记录并且在前端以`Model.__str__`渲染一个`select`控件。

### 多对多支持

FastAPI-admin 会自动读取所有的关联记录并且在前端以`Model.__str__`渲染一个多选`select`控件，仅限于编辑界面。

### json 支持

FastAPI-admin 会对`JSONFIeld`以 json 控件渲染。

### 搜索

定义 `menu.search_fields`会渲染出一个搜索框。

### Xlsx 导出

FastAPI-admin 可导出 xlsx 文件，只需在`menu`设置`export=True`。

### 批量操作

当前 FastAPI-admin 支持内置的`delete_all`，如果你需要自定义：

1. 传入 `bulk_actions` 到 `Menu`，示例：

   ```python
   Menu(
       bulk_actions=[{
             'value': 'delete', # fastapi path参数
             'text': 'delete_all', # 前端展示的
       }]
   )
   ```

2. 编写 fastapi 路由，示例：

   ```python
   from fastapi_admin.schemas import BulkIn
   from fastapi_admin.factory import app as admin_app

   @admin_app.post(
       '/rest/{resource}/bulk/delete' # `delete` is defined in Menu before.
   )
   async def bulk_delete(
           bulk_in: BulkIn,
           model=Depends(get_model)
   ):
       await model.filter(pk__in=bulk_in.pk_list).delete()
       return {'success': True}
   ```

## 部署

1. 使用`gunicorn+uvicorn` 或者参考<https://fastapi.tiangolo.com/deployment。>
2. `cp .env.example .env`对应修改,在`front`目录执行`npm run build`，然后将`dist`中所有文件拷贝到服务器并用`nginx`部署。

## 感谢

- [fastapi](https://github.com/tiangolo/fastapi) ,high performance
  async api framework.
- [tortoise-orm](https://github.com/tortoise/tortoise-orm) ,familiar
  asyncio ORM for python.
- [rest-admin](https://github.com/wxs77577/rest-admin),restful Admin
  Dashboard Based on Vue and Boostrap 4.

## 开源许可

本项目遵从 [MIT](https://github.com/long2ice/fastapi-admin/blob/master/LICENSE)开源许可。
