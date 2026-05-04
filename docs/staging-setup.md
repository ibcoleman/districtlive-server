# Staging Cluster Setup

This runbook documents the one-time manual steps to provision a fresh DOKS staging cluster for districtlive-server. Run these steps once. After setup, all deploys are automated via GitHub Actions.

## Prerequisites

Install the following tools before starting:

- **doctl** ≥ 1.100.0 — DigitalOcean CLI  
  Install: https://docs.digitalocean.com/reference/doctl/how-to/install/  
  Verify: `doctl version`  
  Authenticate: `doctl auth init` (requires a DigitalOcean API token)

- **kubectl** ≥ 1.26.0  
  Install: https://kubernetes.io/docs/tasks/tools/  
  Verify: `kubectl version --client`

- **gh** (GitHub CLI) — for setting Actions secrets  
  Install: https://cli.github.com/  
  Authenticate: `gh auth login`

## Step 1: Create the DOKS cluster

```bash
doctl kubernetes cluster create districtlive-staging \
  --region nyc1 \
  --version 1.33.0-do.0 \
  --node-pool "name=default;size=s-1vcpu-2gb;count=1"
```

This creates a single-node cluster (`s-1vcpu-2gb` = 1 vCPU, 2 GB RAM) in the `nyc1` region. Provisioning takes 3–5 minutes.

To see available Kubernetes versions: `doctl kubernetes options versions`

## Step 2: Save the kubeconfig

```bash
doctl kubernetes cluster kubeconfig save districtlive-staging
```

This adds the cluster context to `~/.kube/config`. Verify kubectl is pointing at the new cluster:

```bash
kubectl config current-context
# Expected: do-nyc1-districtlive-staging
kubectl get nodes
# Expected: one node in Ready state
```

## Step 3: Create the namespace

```bash
kubectl create namespace districtlive-server
```

## Step 4: Create the image pull secret

The app image is hosted on ghcr.io (GitHub Container Registry), which requires credentials to pull. Create a GitHub Personal Access Token (PAT) with `read:packages` scope at https://github.com/settings/tokens.

```bash
kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=ibcoleman \
  --docker-password=<GITHUB_PAT> \
  --docker-email=ibcoleman@gmail.com \
  --namespace districtlive-server
```

Replace `<GITHUB_PAT>` with the token you created.

## Step 5: Create the application secrets

Create the `districtlive-secrets` Secret with all required env vars. The Postgres credentials are `app:app` — the StatefulSet uses these values hardcoded internally, so `DATABASE_URL` must match.

**Required values:**

```bash
kubectl create secret generic districtlive-secrets \
  --from-literal=DATABASE_URL='postgres://app:app@postgres:5432/app' \
  --from-literal=ADMIN_USERNAME='<choose a username>' \
  --from-literal=ADMIN_PASSWORD='<choose a strong password>' \
  --namespace districtlive-server
```

**Optional API keys** (add `--from-literal=KEY=value` for each one you have):

| Key | Purpose |
|-----|---------|
| `TICKETMASTER_API_KEY` | Enables Ticketmaster event ingestion connector |
| `SPOTIFY_CLIENT_ID` | Enables Spotify artist enrichment |
| `SPOTIFY_CLIENT_SECRET` | Required alongside SPOTIFY_CLIENT_ID |
| `BANDSINTOWN_APP_ID` | Enables Bandsintown event ingestion connector |
| `DICEFM_VENUE_SLUGS` | Comma-separated Dice.fm venue slugs; enables Dice.fm connector |

Example with optional keys:

```bash
kubectl create secret generic districtlive-secrets \
  --from-literal=DATABASE_URL='postgres://app:app@postgres:5432/app' \
  --from-literal=ADMIN_USERNAME='admin' \
  --from-literal=ADMIN_PASSWORD='<strong-password>' \
  --from-literal=TICKETMASTER_API_KEY='<key>' \
  --from-literal=SPOTIFY_CLIENT_ID='<id>' \
  --from-literal=SPOTIFY_CLIENT_SECRET='<secret>' \
  --from-literal=BANDSINTOWN_APP_ID='<id>' \
  --namespace districtlive-server
```

The app starts without optional keys; connectors that require them simply won't run.

## Step 6: Configure GitHub Actions secrets

The deploy workflow needs two repository secrets.

### GHCR_TOKEN

Create a GitHub PAT with `write:packages` scope at https://github.com/settings/tokens. This allows the workflow to push Docker images to ghcr.io.

```bash
gh secret set GHCR_TOKEN --body "<PAT_WITH_WRITE_PACKAGES>"
```

### KUBE_CONFIG

Base64-encode the kubeconfig for the staging cluster (single-line, no wraps):

```bash
# Linux (GNU base64):
base64 -w 0 ~/.kube/config

# macOS (BSD base64 doesn't support -w 0):
base64 -i ~/.kube/config | tr -d '\n'
```

Set it as the `KUBE_CONFIG` secret:

```bash
# Linux:
gh secret set KUBE_CONFIG --body "$(base64 -w 0 ~/.kube/config)"

# macOS:
gh secret set KUBE_CONFIG --body "$(base64 -i ~/.kube/config | tr -d '\n')"
```

Verify both secrets are set:

```bash
gh secret list
# Expected output includes: GHCR_TOKEN, KUBE_CONFIG
```

## Step 7: Trigger the first deploy

Push or merge any commit to `main`. The `ci` workflow runs first; once it passes, `deploy.yml` triggers automatically.

Monitor the deploy from the terminal:

```bash
gh run watch --repo ibcoleman/districtlive-server
# or list recent runs:
gh run list --workflow=deploy.yml --repo ibcoleman/districtlive-server
```

Or go to the repository on GitHub → Actions tab → find the `deploy` workflow run.

Once the workflow finishes, watch the Kubernetes rollout:

```bash
kubectl rollout status deployment/districtlive-server \
  -n districtlive-server --timeout=300s
```

## Step 8: Verify the deployment

**Check all pods are running:**

```bash
kubectl get pods -n districtlive-server
```

Expected:
```
NAME                                    READY   STATUS    RESTARTS
districtlive-server-<hash>              1/1     Running   0
postgres-0                              1/1     Running   0
```

**Get the LoadBalancer IP:**

```bash
kubectl get svc districtlive-server -n districtlive-server
```

Wait until `EXTERNAL-IP` shows a real IP address (not `<pending>`). DigitalOcean takes 1–2 minutes to provision the load balancer.

**Test the app:**

```bash
curl http://<EXTERNAL-IP>/healthz
# Expected: 200 OK
```

**Check Postgres PVC is bound:**

```bash
kubectl get pvc -n districtlive-server
```

Expected: `data-postgres-0` is `Bound` with `do-block-storage` storage class.

## Troubleshooting

**App pod is CrashLoopBackOff:**

```bash
kubectl logs deployment/districtlive-server -n districtlive-server
```

If the logs show "secret not found" or env var errors, the `districtlive-secrets` Secret is missing or incomplete. Delete and recreate it (see Step 5), then restart:

```bash
kubectl rollout restart deployment/districtlive-server -n districtlive-server
```

**LoadBalancer IP is `<pending>`:**

Wait 2 minutes. DigitalOcean provisioning is async. If it stays pending after 5 minutes, check DigitalOcean billing limits.

**Deploy workflow doesn't trigger:**

Verify: `ci` workflow completed successfully on `main` (check GitHub Actions). The `deploy.yml` trigger is `workflow_run` from `ci` — it will not fire if `ci` is still running or failed.
