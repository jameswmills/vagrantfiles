#!/bin/bash

#Back up configs so we can compare when rolling to new versions
cd /etc/kubernetes
for x in $(ls); do
    cp ${x} ${x}.orig
done

if [ "$1" = "master" ]; then
    ### Usage: $0 "master" minionname [minionname minionname]
    cd /etc/etcd
    for x in $(ls); do
        cp ${x} ${x}.orig
    done

    ip=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
    cat << EOF > /etc/kubernetes/apiserver
#FILE:  apiserver
KUBE_API_ADDRESS="--address=0.0.0.0"
KUBE_API_PORT="--port=8080"
KUBE_ETCD_SERVERS="--etcd_servers=http://${ip}:4001"
KUBELET_PORT="--kubelet_port=10250"
KUBE_SERVICE_ADDRESSES="--portal_net=10.254.0.0/16"
KUBE_API_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/config
#FILE:  config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow_privileged=false"
KUBE_MASTER="--master=http://${ip}:8080"
EOF

    cat << EOF > /etc/kubernetes/controller-manager
#FILE:  controller-manager
KUBE_MASTER="--master=http://${ip}:8080"
KUBE_CONTROLLER_MANAGER_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/kubelet
#FILE:  kubelet
KUBELET_ADDRESS="--address=127.0.0.1"
KUBELET_HOSTNAME="--hostname_override=127.0.0.1"
KUBELET_API_SERVER="--api_servers=http://127.0.0.1:8080"
KUBELET_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/proxy
#FILE:  proxy
KUBE_PROXY_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/scheduler
#FILE:  scheduler
KUBE_MASTER="--master=${ip}:8080"
KUBE_SCHEDULER_ARGS=""
EOF

    cat << EOF > /etc/etcd/etcd.conf
#FILE: etcd.conf
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:4001"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379,http://localhost:4001"
EOF
    ip link delete docker0
    systemctl enable etcd.service kube-apiserver.service kube-controller-manager.service kube-proxy.service kube-scheduler.service
    systemctl start etcd.service kube-apiserver.service kube-controller-manager.service kube-proxy.service kube-scheduler.service

    # Wait for things to settle and create minion configs
    # under /etc/kubernetes/minion_configs
    sleep 10
    mkdir -p /etc/kubernetes/minion_configs
    array=( "$@" )
    arraylength=${#array[@]}
    for (( i=1; i<${arraylength}+1; i++ ));
    do
        if [ ! -z "${array[$i]}" ]; then
            cat << EOF > /etc/kubernetes/minion_configs/${array[$i]}.yaml
apiVersion: v1
kind: Node
metadata:
  name: ${array[$i]}
  labels:
    name: ${array[$i]}
spec:
  externalID: "${array[$i]}"
EOF
            cat /etc/kubernetes/minion_configs/${array[$i]}.yaml
            kubectl create -f /etc/kubernetes/minion_configs/${array[$i]}.yaml
        fi
    done

    #Add flanneld config
    cat << EOF > /etc/kubernetes/minion_configs/flanneld.yaml
{
    "Network": "10.10.0.0/16",
    "SubnetLen": 24,
    "Backend": {
        "Type": "vxlan",
        "VNI": 1
     }
}
EOF
    etcdctl set /coreos.com/network/config < /etc/kubernetes/minion_configs/flanneld.yaml
    #let etcd figure stuff out
    sleep 5

    cat << EOF > /etc/sysconfig/flanneld
#FILE: flanneld
FLANNEL_ETCD="http://${ip}:4001"
FLANNEL_ETCD_KEY="/coreos.com/network"
#FLANNEL_OPTIONS=""
EOF
    systemctl enable flanneld.service
    systemctl start flanneld.service

    #SkyDNS/kube2sky
    docker run -d --net=host --restart=always gcr.io/google_containers/kube2sky:1.11 -v=10 -logtostderr=true -domain=kubernetes.local -etcd-server="http://${ip}:4001"
    docker run -d --net=host --restart=always -e ETCD_MACHINES="http://${ip}:4001" -e SKYDNS_DOMAIN="kubernetes.local" -e SKYDNS_ADDR="0.0.0.0:53" -e SKYDNS_NAMESERVERS="8.8.8.8:53,8.8.4.4:53" gcr.io/google_containers/skydns:2015-03-11-001

fi



if [ "$1" = "minion" ]; then
    ### Usage: $0 "minion" minionname mastername
    minion=$2
    master=$3
    masterip=$(ping -c 1 ${master}|grep ^64|sed -e 's/.*(\(.*\)):.*/\1/')

    cat << EOF > /etc/kubernetes/apiserver
#FILE: apiserver
KUBE_API_ADDRESS="--address=127.0.0.1"
KUBE_ETCD_SERVERS="--etcd_servers=http://127.0.0.1:4001"
KUBE_SERVICE_ADDRESSES="--portal_net=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--admission_control=NamespaceAutoProvision,LimitRanger,ResourceQuota"
KUBE_API_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/config
#FILE: config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow_privileged=false"
KUBE_MASTER="--master=http://${masterip}:8080"
EOF

    cat << EOF > /etc/kubernetes/controller-manager
#FILE: controller-manager
KUBELET_ADDRESSES="--machines=127.0.0.1"
KUBE_CONTROLLER_MANAGER_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/kubelet
#FILE: kubelet
KUBELET_ADDRESS="--address=0.0.0.0"
KUBELET_PORT="--port=10250"
KUBELET_HOSTNAME="--hostname_override=${minion}"
KUBELET_API_SERVER="--api_servers=http://${masterip}:8080"
#SkyDNS/kube2sky
KUBELET_ARGS="--cluster_dns=${masterip} --cluster_domain=kubernetes.local"
EOF

    cat << EOF > /etc/kubernetes/proxy
#FILE: proxy
KUBE_MASTER="--master=${masterip}:8080"
KUBE_PROXY_ARGS=""
EOF

    cat << EOF > /etc/kubernetes/scheduler
#FILE: scheduler
KUBE_SCHEDULER_ARGS=""
EOF

    cat << EOF > /etc/sysconfig/flanneld
#FILE: flanneld
FLANNEL_ETCD="http://${masterip}:4001"
FLANNEL_ETCD_KEY="/coreos.com/network"
#FLANNEL_OPTIONS=""
EOF

    systemctl enable kube-proxy.service kubelet.service flanneld.service docker
    systemctl start kube-proxy.service kubelet.service flanneld.service docker
    systemctl stop flanneld.service
    systemctl stop docker
    ip link delete docker0
    systemctl start flanneld.service
    systemctl start docker
    systemctl start kubelet

fi
