echo "[Step 1] Disabilito lo SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

echo "[Step 2] Kernel settings"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system

echo "[Step 3] Install continerd"
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    >/dev/null 2>&1
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y containerd.io >/dev/null 2>&1

sudo mkdir /etc/containerd
sudo -i
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd >/dev/null 2>&1

echo "[Step 4] Install kubeadm"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y kubelet kubeadm kubectl  >/dev/null 2>&1
sudo apt-mark hold kubelet kubeadm kubectl

echo "[Step 5] Aggiungo i nomi macchina cablati tipo bestia"
sudo -i
cat >>/etc/hosts<<EOF
172.15.15.100   kubemaster.local.com     kubemaster
172.15.15.101   kubeworker1.local.com    kubeworker1
172.15.15.102   kubeworker2.local.com    kubeworker2
EOF

echo "[Step 6] Inizializzo il cluster"
sudo kubeadm init --apiserver-advertise-address=172.15.15.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

echo "[Step 7] sposto il join sulla cartella accessibile ai nodi"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "[Step 8] abilito l'autenticazione dai worker per prendersi il join command"
sudo -i
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc