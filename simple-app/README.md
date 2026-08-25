# Simple App using existing Argo CD repository

Existing Git repo:
https://github.com/bus57790/argocd.git

Existing Jenkins webhook:
https://ub-server.tail678a36.ts.net/github-webhook/

Flow:
GitHub push -> Tailscale Funnel -> Jenkins -> Docker/GHCR -> Git manifest update -> Argo CD auto-sync -> Kubernetes

## Install into existing repository

Copy the `simple-app` directory and `Jenkinsfile.simple-app` to the root of the existing argocd repository.

Create a Jenkins Pipeline job pointed at:
https://github.com/bus57790/argocd.git

Script Path:
Jenkinsfile.simple-app

Enable:
GitHub hook trigger for GITScm polling

## Jenkins credential

Credential ID:
github-container-registry

Type:
Username with password

Username:
bus57790

Password:
GitHub PAT with repository write and GHCR package write permissions.

## Bootstrap Argo CD application

kubectl apply -f simple-app/argocd-application.yaml

argocd app get argocd-simple-app

## Verify deployment

kubectl get pods -n demo
kubectl get svc -n demo

kubectl port-forward -n demo svc/argocd-simple-app 8081:80

curl http://127.0.0.1:8081/
