- Install vault bằng helm

1. Tạo thư mục lưu trữ

```sh
mkdir -p /mnt/gluster/shopnow/vault
```

2. Tạo pv vault

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vault-pv
  namespace: shopnow
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /mnt/gluster/shopnow/vault
    server: 192.168.10.155
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-storage
```

### Thực hiện trên server node

Cài đặt vault helm chart

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl create ns vault
```

Tạo file values.yaml có nội dung

```yaml
server:
  dataStorage:
    enabled: true
    size: 5Gi
    storageClass: "nfs-storage"
    accessMode: ReadWriteOnce
    mountPath: "/vault/data"`
```

- Cài đặt

```sh
helm upgrade --install vault hashicorp/vault --namespace vault -f values.yaml
```
