#!/bin/bash


for node in master worker1;do
  multipass launch -n $node --mem 2G --disk 10G
done

# Init cluster on master
multipass exec master -- bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"--disable traefik --kubelet-arg max-pods=1024\" sh -"

# Get node1's IP
IP=$(multipass info master | grep IPv4 | awk '{print $2}')

# Get Token used to join nodes
TOKEN=$(multipass exec master sudo cat /var/lib/rancher/k3s/server/node-token)

# Join worker1
multipass exec worker1 -- \
bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -"

# Join worker2
#multipass exec worker2 -- \
#bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -"

# Get cluster's configuration
multipass exec master sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml

# Set masters external IP in the configuration file
sed -i "s/127.0.0.1/$IP/" k3s.yaml

# We'r all set
echo
echo "K3s cluster is ready !"
echo
echo "Run the following command to set the current context:"
echo "$ export KUBECONFIG=$PWD/k3s.yaml"
echo
echo "and start to use the cluster:"
echo "$ kubectl get nodes"
echo
