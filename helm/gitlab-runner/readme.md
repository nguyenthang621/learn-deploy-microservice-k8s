Ref: https://docs.gitlab.com/runner/install/kubernetes/

- Cài đặt Gitlab-runner

```sh
mkdir gitlab-runner

helm repo add gitlab https://charts.gitlab.io

helm repo update


# Vào gitlab > Admin > Runners > New > lấy token

helm install gitlab-runner gitlab/gitlab-runner --namespace gitlab-runner --create-namespace --set gitlabUrl=http://<domain-gitlab> --set runnerRegistrationToken=<token>
```

- Sửa values.yaml

```yaml
gitlabUrl: "http://<domain>"

runnerRegistrationToken: "<token>"

concurrent: 10
rbac:
  create: true
  clusterWideAccess: true

runners:
  tags: "k8s, ci-cd"
  config: |
    [[runners]]
      [runners.kubernetes]
        namespace = "gitlab-runner"
        image = "alpine"
        image_pull_secrets = ["shopnow-registry-secret"]
        service-account = "gitlab-runner-sa"
        privileged = true
```

- Update helm

```sh
helm upgrade --install gitlab-runner gitlab/gitlab-runner -n gitlab-runner -f values.yaml
```

- Cấu hình rbac

==sa-and-clusterBinding.yaml==

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-runner-sa
  namespace: gitlab-runner
---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gitlab-runner-role
  namespace: gitlab-runner
rules:
  - apiGroups: [""]
    resources: ["secrets", "pods", "pods/log", "configmaps"]
    verbs: ["get", "list", "create", "delete", "watch"]
  - apiGroups: [""]
    resources: ["events"
    verbs: ["list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["create", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gitlab-runner-role-binding
  namespace: gitlab-runner
subjects:
  - kind: ServiceAccount
    name: gitlab-runner-sa
    namespace: gitlab-runner
roleRef:
  kind: Role
  name: gitlab-runner-role
  apiGroup: rbac.authorization.k8s.io


---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gitlab-runner-sa-binding
subjects:
  - kind: ServiceAccount
    name: gitlab-runner-sa
    namespace: gitlab-runner
roleRef:
  kind: ClusterRole
  name: cluster-admin # Cấp quyền admin để truy cập tất cả tài nguyên
  apiGroup: rbac.authorization.k8s.io
```

- Apply

```sh
k apply -n gitlab-runner sa-and-clusterBinding.yaml
```

- Cấu hình thêm **<font color="#c0504d">privileged = true</font>** ở config.toml trong configmap
  ![[Pasted image 20250322121922.png]]
