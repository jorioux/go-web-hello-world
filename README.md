# Steps on how to run stuff!

To run docker image:
```
docker run -p 8082:8081 -d jorioux/go-web-hello-world:v0.1
```

The webapp is accessible here: http://localhost:8082

To deploy on Kubernetes:
```
kubectl apply -f k8s-helloworld.yaml
```

Access it from here: http://localhost:31080

# To generate a Bearer Token for k8s dashboard!

Apply this yaml file to create a service account and RBAC role:

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jonathan
  namespace: default
secrets:
- name: jonathan-secret
---
apiVersion: v1
kind: Secret
metadata:
  name: jonathan-secret
  annotations:
    kubernetes.io/service-account.name: jonathan
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jonathan-role
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "replicationcontrollers", "events", "limitranges", "services"]
  verbs: ["get", "delete", "list", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: jonathan-role-binding
roleRef:
  kind: ClusterRole
  name: jonathan-role
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: jonathan
  namespace: default
```

Retrieve the service account token for `jonathan`:
```
kubectl describe secret jonathan-secret
```

You can then login on the k8s dashboard by using the token authentication! yay!
