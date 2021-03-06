docker深入2-docker-ce的最佳实践
2018/7/14

> 注1：凡是本人整理的，开源产品相关的文章中，标题党写明了“最佳实践”的文章，要特别注意，本人总结的文字并未涉及安全方面的指导，请参考官方的指导教程，因为安全是一个有深度的话题，且安全是相对而言的，并不是个容易的话题。

> 注2：本人整理的所有知识库，基础内容占比多，因为在学习的路上，总是容易卡在某个点上，希望能对路过的你有点帮助即可，力求普及知识，而非教科书一般的按步骤12345来指导即可上生产环境，请自行总结，走出自己的路，加油。


目标
---
部署 docker-ce 服务的最佳实践（持续更新）

部分童鞋对 docker 的版本不太理解，以下是我记忆中的事，docker 版本大致是这样演变的：
- v1.11 时代是 swarmkit
- v1.12 开始出现了 swarm mode
- v1.13 后 docker 变成 EE 和 CE 版本，CE 对应的是社区版本，并将社区的 docker 重命名为 moby，版本跳跃为：v17.03
- 当前最新版本是：v18.05

在[这里](https://github.com/docker/docker-ce/releases)查看版本


部署 docker
---
### 安装
```bash
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum -y install docker-ce
# (可选)指定版本
yum -y install docker-ce-18.03.1.ce-1.el7.centos.x86_64
# (可选)升级版本
yum -y upgrade docker-ce-18.03.1.ce-1.el7.centos.x86_64

# 开机启动
systemctl enable docker

# 启动服务
systemctl start docker
```


### 配置
**推荐配置如下内容**
- 存储驱动
- 日志
- 阿里云registry-mirrors（可选，适用于访问 docker hub 很慢的场景，使用注意事项请参考后续FAQ#1）


有多种方式来配置 docker 服务，建议使用下述配置文件：
`/etc/docker/daemon.json`

linux 上默认没有配置文件，需要创建：
`mkdir -p /etc/docker`


**配置存储驱动的实例**
- overlay 驱动
```bash
tee /etc/docker/daemon.json <<-'EOF'
{
  "graph": "/mnt/docker-data",
  "storage-driver": "overlay",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://xxxx.mirror.aliyuncs.com"]
}
EOF
```
> 注：针对 自定义存储目录，使用 "graph": "/mnt/docker-data"
[参考文档](https://docs.docker.com/engine/admin/systemd/#start-automatically-at-system-boot)



- overlay2 驱动
```bash
tee /etc/docker/daemon.json <<-'EOF'
{
  "graph": "/mnt/docker-data",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://xxxx.mirror.aliyuncs.com"]
}
EOF
```
> 注：针对 centos 系统和 docker-ce 版本，使用 `overlay2.override_kernel_check=true`
[参考文档](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/#configure-docker-with-the-overlay-or-overlay2-storage-driver)





- devicemapper 驱动
```bash
yum install -y yum-utils device-mapper-persistent-data lvm2

tee /etc/docker/daemon.json <<-'EOF'
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.directlvm_device=/dev/sdb",
    "dm.thinp_percent=95",
    "dm.thinp_metapercent=1",
    "dm.thinp_autoextend_threshold=80",
    "dm.thinp_autoextend_percent=20",
    "dm.directlvm_device_force=false"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://xxxx.mirror.aliyuncs.com"]
}
EOF
```

> 注：针对 让 docker 服务来管理 （自动创建） DIRECT-LVM 设备，使用 dm 相关的参数
[参考文档](https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/#configure-direct-lvm-mode-for-production)



### 重启服务
```
systemctl daemon-reload
systemctl restart docker
```


FAQ
---

##### 1、使用阿里云 Docker Hub 镜像站点和 latest 这个 tag 带来的问题

> 注1：拉取镜像时，不推荐使用 latest 这个 tag 来拉取，否则可能拉取到旧的镜像，建议指定明确的版本号。

问题描述
我的 docker node 使用了 [Docker Hub 镜像站点](https://cr.console.aliyun.com/#/accelerator)，然后发现一个问题：

````bash
~]$ sudo cat /etc/docker/daemon.json |grep registry
  "registry-mirrors": ["https://zvz7k9mh.mirror.aliyuncs.com"]

~]$ sudo docker pull opera443399/whoami
Using default tag: latest
latest: Pulling from opera443399/whoami
Digest: sha256:4119c322c2d9f007af8751394a63ed6809158bc39456e6aa60ab84e7a21429c5
Status: Image is up to date for opera443399/whoami:latest

~]$ sudo docker images |grep opera
opera443399/whoami         latest              160ed79ce86f        5 weeks ago         4.13MB
````

实际上，上述拉取到的是一个旧的版本 160ed79ce86f

> 对比下面操作中另一个节点的状态（没有使用加速镜像）
````bash
~]$ sudo docker pull opera443399/whoami
Using default tag: latest
latest: Pulling from opera443399/whoami
Digest: sha256:a05120d9fe157868f7f1c8b842cc860fb58665d74cadaf8eb7d6091af626cccd
Status: Downloaded newer image for opera443399/whoami:latest

~]$ sudo docker images |grep opera
opera443399/whoami          0.9                  a7878d3e0fdf        20 hours ago        4.13MB
opera443399/whoami          latest               a7878d3e0fdf        20 hours ago        4.13MB
opera443399/whoami          0.8                  ae008c956c53        3 weeks ago         4.13MB
opera443399/whoami          0.7                  160ed79ce86f        5 weeks ago         4.13MB

````

小结：使用阿里云的容器服务中的 Docker Hub 镜像站点后，缓存的 latest 这个 tag 是旧版本，且过了好几天还没有刷新，这个问题怎么解决？



已经试图反馈给[阿里云](https://github.com/aliyun/aliyun-cli/issues/36)，如果进展，后续更新。


##### 2、在 swarm mode 中使用独立的网络

用途：处于同一个 overlay 网络中的服务，互相之间可以通过服务名称来访问
```
docker network create --driver overlay my-network
docker service create \
    --name t001 \
    --with-registry-auth \
    --detach=true \
    --network=my-network \
    --publish 11111:80 \
    your-private-registry/your-ns/whoami:0.9

```

##### 3、在 swarm mode 中使用私有镜像仓库
`--with-registry-auth` 示例同 FAQ#2


##### 4、使用 go 模版来获取指定内容

例如，获取所有 overlay 网络的 subnet 信息
```bash
docker network inspect $(docker network ls -f driver='overlay' -q) \
--format='{{.Name}} -> {{if .IPAM.Config}}{{(index .IPAM.Config 0).Subnet}}{{else}}null{{end}}' |sort -k2
```


##### 5、安装指定版本的 docker 服务
使用 `labels` 和 `constraint` 来调度容器

* 给 node 打标签
```bash
docker node update --label-add 'deploy.env==ops' worker1
docker node update --label-add 'deploy.env==dev' worker2
docker node update --label-add 'deploy.env==qa' worker3
```

* 更新服务，加上调度策略(注意：每执行一次 `--constraint-add` 将增加一个标签)
```bash
docker service update --with-registry-auth \
  --constraint-add "node.labels.deploy.env==dev" svc1
```

* 查看 svc1 的调度策略
```bash
docker service inspect svc1 --pretty |grep Constraints
```

* 移除标签(如果有多个标签，可以重复使用 `--constraint-rm` 指令)
```bash
docker service update --with-registry-auth \
  --constraint-rm "node.labels.deploy.env==dev" svc1
```


zyxw、参考
---
1. [systemd](https://docs.docker.com/engine/admin/systemd/)
2. [storagedriver](https://docs.docker.com/engine/userguide/storagedriver)
3. [Docker CE 镜像源站](https://yq.aliyun.com/articles/110806)
4. [阿里云容器服务-镜像加速器](https://cr.console.aliyun.com/#/accelerator)
5. [Docker --format 格式化输出概要操作说明](https://yq.aliyun.com/articles/230067)
