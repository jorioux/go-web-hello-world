# Technical Steps

## Task 0 - Get an Ubuntu server VM

I'm on Windows 10, so there are several ways to get an Ubuntu CLI:

1. Virtualbox ❌
    * This is not an option for me because I already have Docker Desktop installed and it prevents me from using other hardware virtualization (VT) apps like Virtualbox
2. Docker Desktop ❌
    * Running this cmd allows me to easily access an Ubuntu 16.04 CLI:
      ```sh
      docker run -it ubuntu:16.04 bash
      ```
    * But as Docker Desktop on Windows 10 leverages WSL2 to run the linux containers, I got blocked at the Gitlab installation step because of an incompatibility with WSL2.
3. WSL2 ❌
    * Windows 10 ships with an actual Linux Kernel built-in and allows me to open an Ubuntu CLI as easily as opening a Powershell CLI. But for the same reason as Docker Desktop, it didn't work for me.
4. vSphere VM ✔️
    * I'm lucky enough to have an HPE ProLiant server at home with ESXi. So I provisioned an Ubuntu server VM (with the 16.04 ISO) and accessed the CLI from my Windows 10 laptop using SSH.

    **Since I'm using a vSphere VM, I won't need the port forwardings.**

## Task 1 - Update system

Upon installation of Ubuntu server, it automatically applies the latest updates. Just to make sure to have the latest kernel, I ran:

```sh
sudo apt-get update
```

## Task 2 - Install gitlab-ce

To install gitlab-ce I ran these commands:

```sh
# Install dependancies
sudo apt-get install -y curl openssh-server ca-certificates tzdata

# Install postfix (select "no configuration" option because we won't make use of it)
sudo apt-get install -y postfix

# Install the gitlab-ce repository
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# Install the gitlab-ce package
# The value of EXTERNAL_URL is my Ubuntu server VM IP
sudo EXTERNAL_URL="http://192.168.1.181" apt-get install gitlab-ce
```

## Task 3 - Create Go project

After creating the group and project in Gitlab, I created a file named `helloworld.go` that contains the following:

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Go Web Hello World!")
    })

    // serve and listen on port 8081
    http.ListenAndServe(":8081", nil)
}
```

And pushed the code to Gitlab:

```sh
# clone the repository
git clone http://192.168.1.181/demo/go-web-hello-world.git

# push the Go app
git add helloworld.go
git commit -m "first commit"
git push
```

## Task 4 - Run the Go app

To run the Go app I did the following:

```sh
go run helloworld.go
```

I am now able to curl the Go app and get the expected response:

![curl8081](https://i.imgur.com/aBdnTmT.png)

## Task 5 - Install Docker

As I already have Docker Desktop installed on my laptop for dev purposes, I decided to make use of it instead of installing docker-ce on the Ubuntu VM. So I basically skipped that step.

## Task 6 - Run the Go app on a container

Create the `Dockerfile` file with the following content:

```dockerfile
FROM golang:latest

# copy helloworld.go file into the container
COPY *.go .

EXPOSE 8081

# this command will run at runtime to serve the Go app
CMD ["go","run","helloworld.go"]
```

```sh
# Grab the golang Docker image from the Docker hub
docker pull golang:latest

# Build the Go app image from the Dockerfile
docker build . -t jorioux/go-web-hello-world:v0.1

# Run the image and expose port 8082
docker run -p 8082:8081 -d jorioux/go-web-hello-world:v0.1
```

I am now able to curl into the Go app on port 8082:

![curl8082](https://i.imgur.com/zuuNF0P.png)

## Task 7 - Push the Go app image to Docker Hub

```sh
# Push the image
docker push jorioux/go-web-hello-world:v0.1
```

The image is now pushed to the Docker Hub and accessible publically:

![dockerhub](https://i.imgur.com/ekTr1Hk.png)

## Quick steps on how to run the Docker image

To run docker image:

```sh
docker run -p 8082:8081 -d jorioux/go-web-hello-world:v0.1
```

The Go app is accessible here: http://localhost:8082

To deploy on Kubernetes:

```sh
kubectl apply -f k8s-helloworld.yaml
```

Access it from here: http://localhost:31080

## To generate a Bearer Token for k8s dashboard

Apply this yaml file to create a service account and RBAC role:

```yaml
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

```sh
kubectl describe secret jonathan-secret
```

You can then login on the k8s dashboard by using the token authentication.
