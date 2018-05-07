### 系统初始化

centos 7 以上

> # 修改语言
> $ localectl  set-locale LANG=en_US.UTF-8

### docker 部署

```
$ yum update

$ cat >/etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

$ yum install docker-engine

===================
docker machine 安装
参考：
https://github.com/docker/machine/releases/
http://www.cnblogs.com/sparkdev/p/7044950.html
http://www.cnblogs.com/sparkdev/p/7066789.html

$ curl -L https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine
$ chmod +x /usr/local/bin/docker-machine

$ adduser docker
$ usermod -a -G root docker

$ visudo

docker   ALL=(ALL:ALL) NOPASSWD: ALL

$ ssh-keygen -t rsa -b 4096 -C docker
$ passwd docker
$ ssh-copy-id -i ~/.ssh/id_rsa.pub docker@172.28.32.202

$ docker-machine create -d generic --generic-ip-address=172.28.32.202 --generic-ssh-user=docker --generic-ssh-key ~/.ssh/id_rsa dockerHost-202

```

系统配置proxy
```
vi /etc/profile

export http_proxy=ip:port
export https_proxy=ip:port
#export socks5_proxy=socks5ip:socks5port

```

yum 配置proxy
```
vi /etc/yum.conf

# Works on RHEL7 / CentOS7 (yum 3.4.3).
proxy=socks5://ip:port

```

docker 配置proxy
```
vi /etc/sysconfig/docker

HTTP_PROXY="http://ip:port"
HTTPS_PROXY="https://ip:port"
http_proxy="${HTTP_PROXY}"
https_proxy="${HTTPS_PROXY}"

```

添加镜像加速
```
vi /etc/docker/daemon.json

{
  "registry-mirrors": ["https://qsofa8am.mirror.aliyuncs.com"]
}

```

下载镜像
> $ docker pull hyperledger/fabric-peer:x86_64-1.1.0
> $ docker pull hyperledger/fabric-ca:x86_64-1.1.0
> $ docker pull hyperledger/fabric-kafka:x86_64-1.0.5
> $ docker pull hyperledger/fabric-tools:x86_64-1.1.0
> $ docker pull hyperledger/fabric-ccenv:x86_64-1.1.0
> $ docker pull hyperledger/fabric-orderer:x86_64-1.1.0
> $ docker pull hyperledger/fabric-baseimage:x86_64-0.4.7
> $ docker pull hyperledger/fabric-baseos:x86_64-0.4.7

### mesos 部署

下载rpm  
https://open.mesosphere.com/downloads/mesos/

> $ yum install -y subversion
> $ yum install -y cyrus-sasl-md5
> $ yum install -y libevent-devel

> $ rpm -ivh mesos-1.0.3-2.0.1.el7.x86_64.rpm

```
启动zk
$ docker run -d --name zk \
    -p 2181:2181 \
    -p 2888:2888 \
    -p 3888:3888 \
    garland/zookeeper

配置mesos
服务启动执行脚本，可查看参数配置等
$ vi /usr/bin/mesos-init-wrapper
修改zk 地址
$ vi /etc/mesos/zk
mesos-slave 默认配置（增加ip配置）
$ vi /etc/default/mesos-master
IP={ip}
CLUSTER="dev cluester"
$ vi /etc/mesos-master/hostname
{ip}

mesos-slave 默认配置（增加ip配置）
$ vi /etc/default/mesos-slave
IP={ip}
$ vi /etc/mesos-slave/hostname
{ip}
# or
$ vi /etc/mesos-slave/?no-hostname_lookup
true
注意：如上操作可能需要清理目录，否则可能造成slave 无法正常启动
$ rm -rf /var/lib/mesos/*

修改work_dir 路径
$ vi /etc/mesos-slave/work_dir
修改containerizers 路径
$ echo 'docker,mesos' > /etc/mesos-slave/containerizers
or
$ vi /etc/mesos-slave/containerizers

启动mesos master
$ systemctl start mesos-master

$ systemctl start mesos-slave

访问
http://{ip}:5050/

```

=======
域名绑定

```
$ vi /etc/hosts

172.28.32.205 orderer.justtry.com
172.28.32.202 peer0.org1.justtry.com
172.28.32.203 peer1.org1.justtry.com
172.28.32.205 peer0.org2.justtry.com
172.28.32.206 peer1.org2.justtry.com
172.28.32.207 peer91.org2.justtry.com
172.28.32.207 ca.justtry.com
172.28.32.207 zk.justtry.com
```

$ mkdir -p /apps/justtry

### 生成秘钥，证书及初始块等文件

$ sh gen.sh

### 更换域名（目前为justtry.com）

需要替换下面脚本及配置文件中的所有相关域名

> ./scripts/script.sh
> ./bin/gen.sh
> ./config/configtx.yaml
> ./config/crypto-config.yaml
> ./config/docker-compose-cli.yaml
> ./config/base/docker-compose-base.yaml
> ./config/base/peer-base.yaml

### 配置是否使用TLS

> ./config/docker-compose-cli.yaml

- CORE_PEER_TLS_ENABLED=false

> ./config/base/peer-base.yaml

- CORE_PEER_TLS_ENABLED=false

> ./config/base/docker-compose-base.yaml

- ORDERER_GENERAL_TLS_ENABLED=false

> ./scripts/script.sh

ORDERER_CA=******

### 配置系统环境变量

```
$ vi /etc/profile

export KOYNARE_MESOS_MASTER=172.28.32.202:5050
export KOYNARE_YAML=/apps/justtry/config/docker-compose-cli.yaml
export KOYNARE_MEM=400

```

### fabric-ca 部署及功能测试

```
部署

$ docker run -d --name ca \
    -p 7054:7054 \
    -v /etc/hosts:/etc/hosts \
    -v /apps/justtry/:/apps/justtry/ \
    -v /apps/justtry/config/crypto-config/peerOrganizations/org1.justtry.com/ca/:/etc/hyperledger/ca/ \
    -v /apps/justtry/fabric-ca-server-config.yaml:/etc/hyperledger/fabric-ca-server/fabric-ca-server-config.yaml \
    -e CA_CERT_FILE=/etc/hyperledger/ca/ca.org1.justtry.com-cert.pem \
    -e CA_KEY_FILE=/etc/hyperledger/ca/9670cf768a18dbb4aa182090fb27313858398c5066efa314688a16dca014fdfd_sk \
    hyperledger/fabric-ca:x86_64-1.1.0 \
    sh -c 'fabric-ca-server start --ca.certfile ${CA_CERT_FILE} --ca.keyfile ${CA_KEY_FILE} -b admin:adminpw -d'

测试

为支持自定义域名需要修改配置fabric-ca-server-config.yaml
affiliations:
   org1:
      - justtry.com
注册管理员
$ ./fabric-ca-client enroll -u http://admin:adminpw@ca.org1.justtry.com:7054
注册新账户
$ ./fabric-ca-client register --id.name peer9 --id.type peer --id.affiliation org1.justtry.com --id.attrs 'hf.Revoker=true,foo=bar'
背书（获取证书及秘钥）
$ ./fabric-ca-client enroll -u http://peer91:XEprggyNDLkB@ca.org1.justtry.com:7054 -M /apps/justtry/peer91msp

需要复制能够将peer 加入到channel 的管理员证书
$ mkdir /apps/justtry/peer91msp/admincerts
$ cp config/crypto-config/peerOrganizations/org1.justtry.com/peers/peer0.org1.justtry.com/msp/admincerts/Admin\@org1.justtry.com-cert.pem ./peer91msp/admincerts/

启动peer91 节点容器

docker run -d \
    -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
    --name=peer91.org1.justtry.com \
    --restart=unless-stopped \
    --net=host \
    -v /etc/hosts:/etc/hosts \
    -v /var/run/:/host/var/run/ \
    -v /apps/justtry/peer91msp:/etc/hyperledger/fabric/msp \
    -v /apps/justtry/peer91msp/tls:/etc/hyperledger/fabric/tls \
    -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
    -e CORE_LOGGING_LEVEL=DEBUG \
    -e CORE_PEER_ENDORSER_ENABLED=true \
    -e CORE_PEER_GOSSIP_USELEADERELECTION=true \
    -e CORE_PEER_GOSSIP_ORGLEADER=false \
    -e CORE_PEER_PROFILE_ENABLED=false \
    -e CORE_PEER_TLS_ENABLED=false \
    -e CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt \
    -e CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt \
    -e CORE_PEER_ID=peer91.org1.justtry.com \
    -e CORE_PEER_ADDRESS=peer91.org1.justtry.com:7051 \
    -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer91.org1.justtry.com:7051 \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    hyperledger/fabric-peer:x86_64-1.1.0 peer node start

```
