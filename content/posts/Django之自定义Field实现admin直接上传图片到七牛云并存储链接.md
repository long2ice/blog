---
title: Django之自定义Field实现admin直接上传图片到七牛云并存储链接
categories: 
  - 程序天地
date: 2019-02-13 21:44:26
tags:
  - django
---
Django自带的admin模块的功能实际上已经足够强大了，但是我们不免有一些自定义化的需求，比如我们在后台存储图片时，为了提高系统的性能，我们会使用第三方cdn服务去存储图片等静态资源，然后将链接存入数据库中，但是将图片上传到cdn，然后复制链接存入数据库又是比较繁琐的一个过程，作为程序员，肯定要寻求更高效的解决方法，比如自定义Field。

实际上覆盖admin的字段在Django中有两种方式，一种是自定义Form，然后在admin.py对应的ModelAdmin中覆盖form属性，比如：

```python

class MyForm(forms.Form):
    class Meta:
        widgets = {
            'field':CustomWidget()
        }
# admin.py
class MyAdmin(admin.ModelAdmin):
    form = MyForm
    
```

这样就将field字段覆盖为CustomWidget，在CustomWidget中，就可以自定义template和css等。这样的话在每个需要自定义的Field都需要这样做一次，如果使用频繁的话就不怎么推荐，推荐另一种更通用的方式，自定义models.py中的Field。

### 1、构建widgets
要实现上传七牛的功能，首先在项目同名的目录下建一个widgets.py，实现自己的QiniuWidgets类，另外说一点的是，该实现参考了[django-ckeditor]( https://github.com/django-ckeditor/django-ckeditor )项目，可以在admin中集成富文本编辑器，还是很不错的，推荐使用。

```python

class QiniuWidgets(forms.FileInput):
    template_name = 'admin/qiniu_input.html'

    def __init__(self, attrs=None, app=None, table=None, unique_list=None):
        """

        :param attrs:
        :param app: app
        :param table: 数据模型
        :param unique_list: 唯一标识列表，除了id
        """
        super(QiniuWidgets, self).__init__(attrs)
        self.unique = unique_list
        if settings.DEBUG:
            env = 'dev'
        else:
            env = 'pro'
        self.filename_prefix = '{}/{}/{}/'.format(env, app, table)

    def format_value(self, value):
        return value

    def value_from_datadict(self, data, files, name):
        file = files.get(name)  # type:InMemoryUploadedFile
        file_data = b''.join(chunk for chunk in file.chunks()) # 取出二进制数据
        file_type = file.name.split('.')[-1] # 得到文件的后缀
        unique_filename = '_'.join(list(map(lambda x: data.get(x), self.unique))) 
        file_name = self.filename_prefix + '{}_{}.{}'.format(name, unique_filename, file_type) # 构造文件的唯一文件名
        q = QiniuUtils(settings.QINIU_ACCESS_KEY, settings.QINIU_SECRET_KEY) # 七牛上传实例
        q.delete(settings.QINIU_BUCKET_NAME, file_name) # 删除已经存在的
        q.upload(settings.QINIU_BUCKET_NAME, file_name, file_data) # 上传新的
        http = 'https://' if settings.QINIU_USE_SSL else 'http://' 
        url = http + settings.QINIU_DOMAIN + '/' + file_name # 拼接最终的url
        return url

    def render(self, name, value, attrs=None, renderer=None):
        context = self.get_context(name, value, attrs)
        template = loader.get_template(self.template_name).render(context)
        return mark_safe(template)
        
```

现在QiniuWidgets介绍类中方法的含义：
* 首先QiniuWidgets继承了forms.FileInput这个类，这个的类是Django自带的类，可以允许在admin字段中展示一个文件上传框，通过配置好settings.py后，可以实现直接上传文件到服务器目录中，但是我们是使用cdn存储静态资源，所以并不需要这个功能，所以我们要重写内部的方法。
* 在重写的构造函数中，传入了app，table这些参数，实际上是为了生成唯一的静态资源路径，那为什么不直接使用时间戳或者是随机字符串命令呢？实际上是一种强迫症，可以在下次上传文件覆盖时删除之前的，并且可以根据app，model等更清晰的构造文件的路径。
* format_value这个方法是为了在模板中渲染该字段的值，在其父类中可以看到直接return了并没有返回任何值，

```python

class FileInput(Input):
    input_type = 'file'
    needs_multipart_form = True
    template_name = 'django/forms/widgets/file.html'

    def format_value(self, value):
        """File input never renders a value."""
        return

    def value_from_datadict(self, data, files, name):
        "File widgets take data from FILES, not POST"
        return files.get(name)

    def value_omitted_from_data(self, data, files, name):
        return name not in files
        
```

但是在这里我们要直接返回value，不然就会报错。
* 然后就是最重要的方法，value_from_datadict，在其父类函数中可以看到返回的是files.get(name)，实际上是直接返回了一个InMemoryUploadedFile实例，我们就需要重写这个方法，实现将图片上传到七牛云，然后返回url链接。可以看注释很容易了解其实现方式，另外其中的QiniuUtils是自己根据官方的sdk封装的类。

```python

class QiniuUtils:
    _instance_lock = threading.Lock()

    def __init__(self, access_key, secret_key):
        self.secret_key = secret_key
        self.access_key = access_key
        self.auth = qiniu.Auth(self.access_key, self.secret_key)
        self.bucket = qiniu.BucketManager(self.auth)
        self.cdn = qiniu.CdnManager(self.auth)

    def __new__(cls, *args, **kwargs):
        if not hasattr(QiniuUtils, '_instance'):
            with QiniuUtils._instance_lock:
                if not hasattr(QiniuUtils, '_instance'):
                    QiniuUtils._instance = object.__new__(cls)
        return QiniuUtils._instance

    def upload(self, bucket_name, key, file_data):
        """
        上传图片到七牛云
        :param bucket_name: 空间名
        :param key: 文件名
        :param file_data: 二进制数据
        :return:
        """
        up_token = self.auth.upload_token(bucket_name, key, 3600)
        return qiniu.put_data(up_token, key, file_data)

    def delete(self, bucket_name, key):
        """
        删除文件
        :param bucket_name:
        :param key:
        :return:
        """
        self.bucket.delete(bucket_name, key)

    def refresh_urls(self, urls):
        self.cdn.refresh_urls(urls)
        
```

### 2、构建Field
第一补构建好widgets之后，实际上已经可以通过覆盖form属性进行使用了，但是我们希望能使用更通用简便的方式，就好像使用[django-ckeditor]( https://github.com/django-ckeditor/django-ckeditor )这个插件的时候，只需要在定时model的使用将字段定义成RichTextField，就可以在admin中直接以富文本形式展现了，实际上数据库中的存储方式也还是字符串类型，只不过在显示层更改了展现的方式，很多时候要明白框架内部的运行原理而不是只知道怎么去使用这个框架。

```python

# fields.py
class QiniuField(models.URLField):
    def __init__(self, *args, **kwargs):
        self.app = kwargs.pop('app', '')
        self.table = kwargs.pop('table', '')
        self.unique_list = kwargs.pop('unique_list', '')
        super(QiniuField, self).__init__(*args, **kwargs)

    def formfield(self, **kwargs):
        defaults = {
            'form_class': QiniuFormField,
            'app': self.app,
            'table': self.table,
            'unique_list': self.unique_list
        }
        defaults.update(kwargs)
        return super(QiniuField, self).formfield(**defaults)


class QiniuFormField(forms.fields.URLField):
    def __init__(self, app=None, table=None, unique_list=None, **kwargs):
        kwargs.update({'widget': QiniuWidgets(app=app, table=table, unique_list=unique_list)})
        super(QiniuFormField, self).__init__(**kwargs)
        
```

* 这里定义了两个类，一个是QiniuField，继承于models.URLField，另一个是QiniuFormField，继承了forms.fields.URLField，其构造函数中kwargs的widget定义为我们自己定义的QiniuWidgets，并且传入参数；然后在QiniuField的formfield方法中，将form_class这个值指定为QiniuFormField，具体为什么这样做，我也是参考django-ckeditor的实现，也可以看看Django自带的Field的定义，具体更深层次的实现就没有去深入了解了。这样实现之后，就可以在models.py使用我们自定义的QiniuField了，从文件上传框上传文件会被上传到七牛云，然后资源的链接会被存储到数据库，perfect。

最后不要忘了在settings.py中配置好以下变量：

```python

# 七牛
QINIU_ACCESS_KEY = ''
QINIU_SECRET_KEY = ''
QINIU_BUCKET_NAME = ''
QINIU_DOMAIN = ''
QINIU_USE_SSL = True # 如果要使用ssl需要另外的配置，具体详见官方教程。

```

### 3、结语
因为整个代码是继承在项目中的，后面有时间会整理好后上传到github作为一个Django的插件。