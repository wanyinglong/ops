# 使用kubeadm部署k8s集群00-缓存gcr.io镜像
2018/2/7

> 原因：kubeadm init 时，需要下载一些镜像，但国内网络原因，大家懂的，不容易下载，此时，只能去绕过它。
> 备注：官方在 1.5 收到阿里一位童鞋的 PR 来允许指定一个第三方的 registry 来解决上述问题，但因为时间所限，并未找到具体的操作方法。


### 【在国外节点上操作】
* [镜像来源](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#running-kubeadm-without-an-internet-connection)

```bash
针对下述镜像：

gcr.io/google_containers/kube-apiserver-amd64:v1.9.0
gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0
gcr.io/google_containers/kube-scheduler-amd64:v1.9.0
gcr.io/google_containers/kube-proxy-amd64:v1.9.0
gcr.io/google_containers/etcd-amd64:3.1.10
gcr.io/google_containers/pause-amd64:3.0
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7
```

```bash
##### 先 pull 下来

docker pull gcr.io/google_containers/kube-apiserver-amd64:v1.9.0
docker pull gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0
docker pull gcr.io/google_containers/kube-scheduler-amd64:v1.9.0
docker pull gcr.io/google_containers/kube-proxy-amd64:v1.9.0
docker pull gcr.io/google_containers/etcd-amd64:3.1.10
docker pull gcr.io/google_containers/pause-amd64:3.0
docker pull gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
docker pull gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
docker pull gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7


##### 修改 tag 为新的仓库/命名空间：

docker tag gcr.io/google_containers/kube-apiserver-amd64:v1.9.0 opera443399/kube-apiserver-amd64:v1.9.0
docker tag gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0 opera443399/kube-controller-manager-amd64:v1.9.0
docker tag gcr.io/google_containers/kube-scheduler-amd64:v1.9.0 opera443399/kube-scheduler-amd64:v1.9.0
docker tag gcr.io/google_containers/kube-proxy-amd64:v1.9.0 opera443399/kube-proxy-amd64:v1.9.0
docker tag gcr.io/google_containers/etcd-amd64:3.1.10 opera443399/etcd-amd64:3.1.10
docker tag gcr.io/google_containers/pause-amd64:3.0 opera443399/pause-amd64:3.0
docker tag gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7 opera443399/k8s-dns-sidecar-amd64:1.14.7
docker tag gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7 opera443399/k8s-dns-kube-dns-amd64:1.14.7
docker tag gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7 opera443399/k8s-dns-dnsmasq-nanny-amd64:1.14.7


##### 再 push 到新的仓库/命名空间中：

docker push opera443399/kube-apiserver-amd64:v1.9.0
docker push opera443399/kube-controller-manager-amd64:v1.9.0
docker push opera443399/kube-scheduler-amd64:v1.9.0
docker push opera443399/kube-proxy-amd64:v1.9.0
docker push opera443399/etcd-amd64:3.1.10
docker push opera443399/pause-amd64:3.0
docker push opera443399/k8s-dns-sidecar-amd64:1.14.7
docker push opera443399/k8s-dns-kube-dns-amd64:1.14.7
docker push opera443399/k8s-dns-dnsmasq-nanny-amd64:1.14.7


##### 在目标机器上 pull 下来：

docker pull opera443399/kube-apiserver-amd64:v1.9.0
docker pull opera443399/kube-controller-manager-amd64:v1.9.0
docker pull opera443399/kube-scheduler-amd64:v1.9.0
docker pull opera443399/kube-proxy-amd64:v1.9.0
docker pull opera443399/etcd-amd64:3.1.10
docker pull opera443399/pause-amd64:3.0
docker pull opera443399/k8s-dns-sidecar-amd64:1.14.7
docker pull opera443399/k8s-dns-kube-dns-amd64:1.14.7
docker pull opera443399/k8s-dns-dnsmasq-nanny-amd64:1.14.7


##### 还原 tag 到目标镜像：
docker tag opera443399/kube-apiserver-amd64:v1.9.0 gcr.io/google_containers/kube-apiserver-amd64:v1.9.0
docker tag opera443399/kube-controller-manager-amd64:v1.9.0 gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0
docker tag opera443399/kube-scheduler-amd64:v1.9.0 gcr.io/google_containers/kube-scheduler-amd64:v1.9.0
docker tag opera443399/kube-proxy-amd64:v1.9.0 gcr.io/google_containers/kube-proxy-amd64:v1.9.0
docker tag opera443399/etcd-amd64:3.1.10 gcr.io/google_containers/etcd-amd64:3.1.10
docker tag opera443399/pause-amd64:3.0 gcr.io/google_containers/pause-amd64:3.0
docker tag opera443399/k8s-dns-sidecar-amd64:1.14.7 gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
docker tag opera443399/k8s-dns-kube-dns-amd64:1.14.7 gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
docker tag opera443399/k8s-dns-dnsmasq-nanny-amd64:1.14.7 gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7

##### 清理中转用到的镜像 tag ：
docker rmi $(docker images |grep opera443399 |awk '{print $1":"$2}')

```




ZYXW、参考
1. [阿里云快速部署Kubernetes - VPC环境](https://yq.aliyun.com/articles/66474)
2. [support customize repository prefix of image through environment KUBE… #35948](https://github.com/kubernetes/kubernetes/pull/35948)
3. [Using custom images](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#custom-images)
