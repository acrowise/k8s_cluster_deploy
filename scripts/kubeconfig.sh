#----------------------创建 kube-apiserver TLS Bootstrapping Token

BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
echo ${BOOTSTRAP_TOKEN}

cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

#----------------------

APISERVER=$1
SSL_DIR=$2

export KUBE_APISERVER="https://$APISERVER:8443"

#----------------------

echo "===> generate kubectl config"

# 创建 kubectl config 

kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=config


kubectl config set-credentials admin \
  --client-certificate=$SSL_DIR/admin.pem \
  --client-key=$SSL_DIR/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=config

kubectl config set-context admin@kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=config

kubectl config use-context admin@kubernetes --kubeconfig=config

#----------------------

echo "===> generate kube-controller-manager.kubeconfig"

# 创建 kube-controller-manager.kubeconfig 

kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=$SSL_DIR/master/kube-controller-manager.pem \
  --client-key=$SSL_DIR/master/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager@kubernetes \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager@kubernetes --kubeconfig=kube-controller-manager.kubeconfig

#----------------------

echo "===> generate kube-scheduler.kubeconfig"

# 创建 kube-scheduler.kubeconfig 

kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=$SSL_DIR/master/kube-scheduler.pem \
  --client-key=$SSL_DIR/master/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler@kubernetes \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler@kubernetes --kubeconfig=kube-scheduler.kubeconfig

#----------------------

echo "===> generate kubelet bootstrapping kubeconfig"

# 创建 kubelet bootstrapping kubeconfig 

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

#----------------------

echo "===> generate kube-proxy.kubeconfig"

# 创建 kube-proxy.kubeconfig

kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=$SSL_DIR/node/kube-proxy.pem \
  --client-key=$SSL_DIR/node/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context system:kube-proxy@kubernetes \
  --cluster=kubernetes \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context system:kube-proxy@kubernetes --kubeconfig=kube-proxy.kubeconfig
