# Human Test Plan — DOKS Staging Deployment

Generated from: `docs/implementation-plans/2026-05-02-doks-staging-deployment/`

## Prerequisites

- DigitalOcean account with API token and sufficient billing headroom for one s-1vcpu-2gb node + one block volume + one LoadBalancer
- `doctl` ≥ 1.100.0, `kubectl` ≥ 1.26.0, `gh` CLI installed and authenticated
- Push access to `https://github.com/ibcoleman/districtlive-server`
- Static checks passing locally:
  - `kubectl apply -k k8s/overlays/staging --dry-run=client` exits 0
  - `grep -rEi 'password|secret|api[_-]?key|token' k8s/overlays/staging/ | grep -vE 'secretKeyRef|secretName|imagePullSecrets'` produces no output

---

## Phase 1: Cluster Bring-Up (executes runbook)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `docs/staging-setup.md` end-to-end before running anything | Sections cover: prerequisites, cluster creation, kubeconfig save, namespace, ghcr-pull-secret, districtlive-secrets, GitHub Actions secrets (GHCR_TOKEN + KUBE_CONFIG), first-deploy trigger, verification |
| 2 | `doctl kubernetes cluster create districtlive-staging --region nyc1 --version 1.33.0-do.0 --node-pool "name=default;size=s-1vcpu-2gb;count=1"` | Cluster reaches `running` after 3–5 min; visible in DO console |
| 3 | `doctl kubernetes cluster kubeconfig save districtlive-staging` then `kubectl config current-context` | Outputs `do-nyc1-districtlive-staging` |
| 4 | `kubectl get nodes` | One node, `Ready` |
| 5 | `kubectl create namespace districtlive-server` | `namespace/districtlive-server created` |
| 6 | Create GitHub PAT with `read:packages`, then run the `kubectl create secret docker-registry ghcr-pull-secret ...` command from runbook Step 4 | `secret/ghcr-pull-secret created` |
| 7 | Run the `kubectl create secret generic districtlive-secrets ...` command from runbook Step 5 with at minimum DATABASE_URL, ADMIN_USERNAME, ADMIN_PASSWORD | `secret/districtlive-secrets created`; `kubectl get secret districtlive-secrets -n districtlive-server -o jsonpath='{.data}'` shows all three keys present |
| 8 | Create GitHub PAT with `write:packages`, then `gh secret set GHCR_TOKEN --body "<PAT>"` | `gh secret list` includes `GHCR_TOKEN` |
| 9 | `gh secret set KUBE_CONFIG --body "$(base64 -w 0 ~/.kube/config)"` (Linux) or BSD-base64 equivalent on macOS | `gh secret list` includes `KUBE_CONFIG`; verify the base64 string is single-line (no wraps) |

---

## Phase 2: First Deploy (validates AC1.1, AC1.2, AC2.x)

| Step | Action | Expected |
|------|--------|----------|
| 1 | On a feature branch, make a no-op change (whitespace in a comment), push, open PR, merge to `main` | PR merges cleanly |
| 2 | Open `https://github.com/ibcoleman/districtlive-server/actions` and watch `ci.yml` | `ci.yml` runs on the merge commit and concludes `success` |
| 3 | Watch for `deploy.yml` to start automatically | **AC1.1** — `deploy.yml` triggers within seconds of `ci.yml` success, against the same head SHA. It does NOT trigger on the unmerged PR's earlier pushes |
| 4 | Wait for `deploy.yml` to finish (~10–15 min first time due to cold Bazel cache) | All steps green; rollout step prints `deployment "districtlive-server" successfully rolled out` |
| 5 | Visit `https://github.com/ibcoleman/districtlive-server/pkgs/container/districtlive-server` | **AC1.2** — image with tag matching the merge commit SHA exists; `latest` tag is absent from the tag list |
| 6 | `docker pull ghcr.io/ibcoleman/districtlive-server:<merge-sha>` | Pulls successfully |
| 7 | `kubectl -n districtlive-server get pods -l app=districtlive-server` | **AC2.1** — pod is `Running` with `READY 1/1` |
| 8 | `kubectl -n districtlive-server describe pod <app-pod>` | Readiness probe shows `Path: /healthz Port: 8080`; most recent probe `Success`; events list no probe failures |
| 9 | `kubectl -n districtlive-server logs <app-pod> --tail=100` | No probe failures, no `connection refused`, no `password authentication failed` |
| 10 | `kubectl -n districtlive-server get statefulset postgres` | **AC2.2** — `READY 1/1` |
| 11 | `kubectl -n districtlive-server get pvc` | PVC `data-postgres-0` is `Bound`, `STORAGECLASS` is `do-block-storage` |
| 12 | `kubectl get pv $(kubectl -n districtlive-server get pvc data-postgres-0 -o jsonpath='{.spec.volumeName}') -o yaml \| grep csi.driver` | Shows `dobs.csi.digitalocean.com` |
| 13 | `kubectl -n districtlive-server logs deployment/districtlive-server \| grep -i 'migration\|sqlx'` | **AC2.3** — sqlx log lines indicating migrations ran on startup |
| 14 | `kubectl -n districtlive-server exec statefulset/postgres -- psql -U app -d app -c '\dt'` | Tables `events`, `venues`, `artists` (and any others) are listed |

---

## Phase 3: LoadBalancer Reachability (validates AC3.1, AC3.2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | `kubectl -n districtlive-server get svc districtlive-server` (poll for up to 3 min) | **AC3.1** — `TYPE=LoadBalancer`, `EXTERNAL-IP` is a real IPv4 (not `<pending>`), `PORT(S)=80:<nodeport>/TCP` |
| 2 | DigitalOcean console → Networking → Load Balancers | Balancer for `districtlive-staging` is provisioned and shows healthy backends |
| 3 | `LB_IP=$(kubectl -n districtlive-server get svc districtlive-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); curl -i http://$LB_IP/healthz` | **AC3.2** — `HTTP/1.1 200 OK` |
| 4 | `curl -i http://$LB_IP/` | Non-error response with HTML body (embedded frontend `index.html`) |

---

## Phase 4: Failure Mode (validates AC2.4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | `kubectl delete secret districtlive-secrets -n districtlive-server` | `secret "districtlive-secrets" deleted` |
| 2 | `kubectl rollout restart deployment/districtlive-server -n districtlive-server` | Rollout begins |
| 3 | `kubectl -n districtlive-server describe pod <new-pod>` | **AC2.4** — pod is `CreateContainerConfigError`; events reference missing `districtlive-secrets` by name; failure is loud, not silent |
| 4 | Recreate the secret using the runbook's Step 5 command, then `kubectl rollout restart deployment/districtlive-server -n districtlive-server` | Pod returns to `Running` `1/1` within 60s |

---

## End-to-End: Fresh Developer Runbook Execution (validates AC5.2)

**Purpose:** Confirm the runbook is self-contained and a developer with no prior context can stand up the staging environment from scratch.

1. Recruit a developer who has not previously worked on this deployment, or have the original author execute the runbook against a brand-new DigitalOcean project on a machine with no prior cluster setup.
2. Provide only the URL to `docs/staging-setup.md`. No verbal walkthrough.
3. Developer executes Steps 1–8 of the runbook top-to-bottom, copy-pasting commands. They may consult vendor documentation (DO, GitHub) but not the project author.
4. Note every place the developer pauses, asks a question, or has to look something up outside the runbook. Each such gap is a runbook bug — file or fix immediately.
5. After Step 8, from the developer's machine: `curl http://<EXTERNAL-IP>/healthz` returns `HTTP/1.1 200 OK`.
6. Tear down: `doctl kubernetes cluster delete districtlive-staging`. Confirm the LoadBalancer and block volume are also released (DO console).

---

## Human Verification Required

| Criterion | Why Manual | Test Section |
|-----------|------------|--------------|
| AC1.1 | Requires real merge event and Actions run history | Phase 2, Steps 1–3 |
| AC1.2 | Requires real ghcr.io push | Phase 2, Steps 5–6 |
| AC2.1 | Requires running pod with networking + secrets | Phase 2, Steps 7–9 |
| AC2.2 | Requires DO CSI driver to provision real volume | Phase 2, Steps 10–12 |
| AC2.3 | Requires runtime DB connectivity and migrations | Phase 2, Steps 13–14 |
| AC2.4 | Requires deliberate failure injection | Phase 4 |
| AC3.1 | Requires DO LoadBalancer provisioning | Phase 3, Steps 1–2 |
| AC3.2 | Requires public network reachability | Phase 3, Steps 3–4 |
| AC5.1 | Documentation completeness, not lintable | Phase 1, Step 1 |
| AC5.2 | True end-to-end runbook validation | E2E section |

## Automated Coverage (already verified)

| Criterion | Test |
|-----------|------|
| AC1.3 | Structural inspection of `.github/workflows/deploy.yml:2-6` — `branches: [main]` |
| AC1.4 | Structural inspection of `.github/workflows/deploy.yml:16` — `conclusion == 'success'` gate |
| AC4.1 | `grep -rEi 'password\|secret\|api[_-]?key\|token' k8s/overlays/staging/` — zero plaintext values |
| AC4.2 | `grep -A2 -E 'name: (DATABASE_URL\|ADMIN_USERNAME\|ADMIN_PASSWORD)' k8s/overlays/staging/patches/deployment-staging.yaml` — all three use `secretKeyRef` |
| Phase 1 done-when | `kubectl apply -k k8s/overlays/staging --dry-run=client` exits 0 |
| Phase 2 done-when | YAML parse + structural inspection of `deploy.yml` |
