# Nexus Enterprises — Static Website (Docker + CI/CD)

A small demo project that serves a static website via Apache in a Debian-based container. The repo includes:

- `Dockerfile` — builds an Apache image that expects your site files in `app/` and sets `WORKDIR /var/www/html`.
- `JenkinsFile` — example Jenkins pipeline that builds, tags, pushes an image to AWS ECR and deploys to EKS.
- `website-enterprise.html` — example website content; copy or rename to `app/index.html` for local testing.
- `k8s/` — Kubernetes manifests (`deployment.yaml`, `service.yaml`) used by the pipeline.
- `terraform/` — Terraform configuration (EKS, VPC, etc.). NOTE: the workspace currently contains Terraform state files — do not commit sensitive state in production; use a remote backend.

---

## Quickstart — Local build & run ✅

1. Place your static site files under `./app` (e.g., `app/index.html`).
2. Build the Docker image:

```bash
docker build -t <username>/<repo>:<tag> .
```

3. Run locally (port 8080 example):

```bash
docker run --rm -p 8080:80 --name enterprise-web <username>/<repo>:<tag>
# then open http://localhost:8080
```


## Docker Hub / ECR — Examples 🔧

- Push to Docker Hub:

```bash
docker tag <username>/<repo>:<tag> <username>/<repo>:<tag>
docker push <username>/<repo>:<tag>
```

- Push to AWS ECR (simplified):

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
docker tag <repo>:<tag> <account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>
```

(The provided `JenkinsFile` automates the ECR tag & push steps.)

---

## Jenkins CI/CD — Pipeline overview ⚙️

This repo contains an example `JenkinsFile` that demonstrates a Windows-based Jenkins agent doing the following:

1. Checkout
2. Sanity checks (aws, docker, kubectl, terraform)
3. Build Docker image
4. Create ECR repo (if needed), login, tag and push
5. Deploy to EKS (injects image into `k8s/deployment.yaml` and applies manifests)

Important pipeline variables and parameters (see `JenkinsFile`):

- Environment variables in the file: `AWS_REGION`, `CLUSTER_NAME`, `ECR_REPO`.
- Parameter: `APP_TAG` — docker image tag to build and deploy (default `app1.1.0`).

Notes:
- Jenkins needs AWS credentials (or an instance role) with ECR/EKS permissions.
- The pipeline injects the pushed ECR image into `k8s/deployment.yaml` by replacing `IMAGE_PLACEHOLDER`.

---

## Kubernetes — Deploying the app ☸️

The `k8s/deployment.yaml` contains a placeholder `IMAGE_PLACEHOLDER` which should be replaced with the image URI (ECR or Docker Hub) before apply.

Example (local, manual):

```bash
# replace placeholder and apply
sed "s|IMAGE_PLACEHOLDER|<image-uri>|g" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/enterprise-web
kubectl get svc enterprise-web-svc -o wide
```

When using the pipeline, this image replacement and apply is done automatically.

---

## Terraform — EKS / infra (summary) 🧭

Terraform manifests are in `terraform/`. Typical workflow:

```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Important:
- The repository currently contains `terraform.tfstate` and a backup — do **not** commit real workspace state in production. Use a remote backend (S3 + DynamoDB) for team environments.
- Check `variables.tf` and `terraform.tfvars` before applying.

---

## Troubleshooting & Tips 💡

- If the deployment's `Service` is `LoadBalancer`, `kubectl get svc` shows the external IP once the cloud provider provisions it.
- If image pull fails, ensure ECR image exists and the cluster nodes can access ECR (IAM or node role).
- Use `kubectl logs` and `kubectl describe` to inspect pods and events.

---

## Security & Best Practices ⚠️

- Do not store credentials or secrets in plain text in the repo. Use Jenkins credentials store, Kubernetes Secrets, or a secret manager.
- Move Terraform state to a remote backend for safety.

---

## Contributing & License

Contributions are welcome — open an issue or a PR. This project is provided as-is for learning/demo purposes.

---

**Enjoy!** 🚀

For quick questions about the pipeline or infra layout, open an issue or ask in a PR.
