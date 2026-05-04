# DOKS Staging Deployment Design

## Summary

This design covers setting up an automated staging deployment pipeline for the districtlive-server application. The goal is a fully hands-off path from a merged pull request to a running instance in the cloud: when code lands on `main`, GitHub Actions builds the application binary via Bazel, packages it into a Docker image, pushes it to the GitHub container registry, and applies updated Kubernetes manifests to a DigitalOcean managed Kubernetes cluster. The deployed app and its Postgres database both run inside the cluster, with the database backed by DigitalOcean block storage.

The approach is deliberately narrow in scope. Cluster provisioning is done once by hand and documented in a runbook rather than automated with infrastructure-as-code tooling — a single staging environment does not justify the overhead of Terraform state management. Secret values (database credentials, API keys, admin credentials) are stored as a Kubernetes Secret created outside the repo and never committed. The kustomize overlay pattern already established for local development is extended to staging, keeping the manifest structure consistent across environments.

## Definition of Done

- Merging to `main` automatically builds a Docker image, pushes it to ghcr.io, and deploys it to a DOKS staging cluster
- The staging cluster runs the app and Postgres as a StatefulSet in the `districtlive-server` namespace
- The app is reachable via a DigitalOcean LoadBalancer public IP on port 80
- Sensitive values (DB credentials, admin credentials, API keys) are stored as Kubernetes Secrets, not in the repo
- A one-time setup runbook documents every `doctl` and `kubectl` command needed to stand up a new cluster from scratch

## Acceptance Criteria

### doks-staging-deployment.AC1: Deploy pipeline triggers automatically on merge to main
- **doks-staging-deployment.AC1.1 Success:** Merging to `main` triggers `deploy.yml` after `ci.yml` completes successfully
- **doks-staging-deployment.AC1.2 Success:** Pushed image is tagged with the commit SHA (`ghcr.io/ibcoleman/districtlive-server:<sha>`)
- **doks-staging-deployment.AC1.3 Failure:** `deploy.yml` does not trigger on PRs or pushes to non-`main` branches
- **doks-staging-deployment.AC1.4 Failure:** `deploy.yml` does not trigger when `ci.yml` fails

### doks-staging-deployment.AC2: Staging cluster runs app and Postgres
- **doks-staging-deployment.AC2.1 Success:** App pod starts and passes readiness probe at `/healthz`
- **doks-staging-deployment.AC2.2 Success:** Postgres StatefulSet pod is running with a bound PVC using `do-block-storage`
- **doks-staging-deployment.AC2.3 Success:** App connects to Postgres and runs migrations on startup
- **doks-staging-deployment.AC2.4 Failure:** App pod fails clearly (not silently) if `districtlive-secrets` Secret is missing

### doks-staging-deployment.AC3: App reachable via LoadBalancer
- **doks-staging-deployment.AC3.1 Success:** `kubectl get svc` shows `districtlive-server` as type `LoadBalancer` with an external IP
- **doks-staging-deployment.AC3.2 Success:** HTTP request to `<LB-IP>:80` returns a valid response from the app

### doks-staging-deployment.AC4: Sensitive values not in repo
- **doks-staging-deployment.AC4.1 Success:** No plaintext credentials appear in any file under `k8s/overlays/staging/`
- **doks-staging-deployment.AC4.2 Success:** Deployment env vars for `DATABASE_URL`, `ADMIN_USERNAME`, `ADMIN_PASSWORD` all use `secretKeyRef`

### doks-staging-deployment.AC5: Setup runbook is complete and followable
- **doks-staging-deployment.AC5.1 Success:** Runbook covers cluster creation, namespace setup, both Secrets, and GitHub Actions secret configuration
- **doks-staging-deployment.AC5.2 Success:** A developer following only the runbook can reach the deployed app at the LoadBalancer IP

## Glossary

- **DOKS (DigitalOcean Kubernetes Service)**: DigitalOcean's managed Kubernetes offering. Handles the control plane; the user provisions worker node pools and deploys workloads.
- **kustomize**: A Kubernetes-native configuration management tool that layers environment-specific patches (overlays) on top of a shared base set of manifests without templating.
- **overlay**: In kustomize terminology, an environment-specific directory (`k8s/overlays/staging/`) that references a `base` and applies patches. The base manifests are unchanged; the overlay only adds or overrides.
- **StatefulSet**: A Kubernetes workload controller designed for stateful applications like databases. Unlike a Deployment, it gives each pod a stable identity and manages persistent storage per pod.
- **PVC (PersistentVolumeClaim)**: A Kubernetes request for a storage volume. On DOKS, a PVC backed by `do-block-storage` provisions a DigitalOcean block storage volume attached to the pod.
- **LoadBalancer Service**: A Kubernetes Service type that instructs the cloud provider to provision an external load balancer with a stable public IP, routing traffic to pods inside the cluster.
- **secretKeyRef**: A Kubernetes manifest field that injects a value from a named Secret into a container's environment variable, keeping sensitive values out of the manifest itself.
- **ghcr.io (GitHub Container Registry)**: GitHub's hosted Docker image registry. Images pushed here are addressable as `ghcr.io/<owner>/<repo>:<tag>`.
- **Bazel / Bazelisk**: Bazel is a build system with hermetic, reproducible builds. Bazelisk is a launcher that downloads the correct Bazel version for a project automatically.
- **imagePullSecret**: A Kubernetes Secret of type `docker-registry` that provides credentials for pulling images from a private container registry.
- **`workflow_run` trigger**: A GitHub Actions event that fires when another named workflow completes. Used here so `deploy.yml` only runs after `ci.yml` succeeds on `main`.
- **kubeconfig**: A YAML file that stores cluster connection details and credentials. `kubectl` uses it to authenticate and target the correct cluster.
- **doctl**: The official DigitalOcean CLI. Used here to create the DOKS cluster and retrieve its kubeconfig.
- **commit SHA tag**: Tagging a Docker image with the Git commit hash (`ghcr.io/...:abc1234`) instead of a mutable label like `latest`, making every deployed image traceable to its source commit.
- **readiness probe**: A Kubernetes health check that determines when a pod is ready to receive traffic. The app exposes `/healthz` for this purpose.
- **`kustomize edit set image`**: A kustomize CLI command that rewrites the image tag in a `kustomization.yaml` file in place, used in the deploy workflow to inject the current commit SHA before applying manifests.

## Architecture

GitHub Actions drives the full pipeline. On every merge to `main`, after `ci.yml` passes, `deploy.yml` builds the app binary via Bazel, packages it into a Docker image, pushes to ghcr.io, and applies the staging kustomize overlay to the DOKS cluster via `kubectl`.

Postgres runs as a StatefulSet inside the cluster, backed by a DigitalOcean block storage PVC. The app communicates with Postgres over the internal cluster DNS (`postgres:5432`). No managed database service — self-hosted keeps the architecture symmetric with local dev.

External access is a Kubernetes `LoadBalancer` Service. DigitalOcean provisions a load balancer and assigns a stable public IP. DNS is not configured; the raw IP is sufficient for staging.

Secrets (DB credentials, admin credentials, API keys) are stored as a `districtlive-secrets` Kubernetes Secret, created once via `kubectl create secret` and never committed to the repo. The deployment references them via `secretKeyRef`. A separate secret holds the ghcr.io pull credentials (`ghcr-pull-secret`).

Cluster provisioning is not automated. A `docs/staging-setup.md` runbook documents the one-time `doctl` commands to create the DOKS cluster and `kubectl` commands to create secrets. This is intentional — a single staging cluster doesn't warrant Terraform state management.

### Pipeline Flow

```
push to main
  → ci.yml passes (lint, fmt, bazel tests)
  → deploy.yml triggers
      1. pnpm build            → frontend/dist/
      2. bazel build //:app    → bazel-bin/app
      3. cp bazel-bin/app ./app
      4. docker build          → ghcr.io/ibcoleman/districtlive-server:<sha>
      5. docker push
      6. kubectl apply -k k8s/overlays/staging
      7. kubectl rollout status deployment/districtlive-server
```

Image tags are commit SHAs — immutable and traceable. The staging overlay uses kustomize's `images:` field; `deploy.yml` overrides `newTag` with the SHA at deploy time.

### GitHub Actions Secrets Required

| Secret | Purpose |
|--------|---------|
| `GHCR_TOKEN` | PAT for pushing to ghcr.io |
| `KUBE_CONFIG` | base64-encoded kubeconfig from `doctl` |

## Existing Patterns

Investigation found an existing kustomize structure with a `local` overlay at `k8s/overlays/local/`. The staging overlay follows the same pattern: a `kustomization.yaml` in `k8s/overlays/staging/` that references `../../base` and applies JSON patches.

The existing CI workflow in `.github/workflows/ci.yml` already uses Bazelisk, pnpm, and Node 22. The deploy workflow reuses the same setup steps.

The Dockerfile is already a runtime-only image (no build stages) that expects a pre-built `app` binary at the repo root. The pipeline matches this expectation exactly, consistent with how the Tiltfile drives local image builds.

No existing secrets management pattern found — all credentials in the base manifests are hardcoded (`app:app`). This design introduces Kubernetes Secrets as the first secrets management layer.

## Implementation Phases

<!-- START_PHASE_1 -->
### Phase 1: Staging kustomize overlay

**Goal:** A complete `k8s/overlays/staging/` that can be applied to any DOKS cluster with the right secrets pre-created.

**Components:**
- `k8s/overlays/staging/kustomization.yaml` — extends base; sets image name to `ghcr.io/ibcoleman/districtlive-server`; references patches; adds `imagePullSecrets`; sets namespace
- `k8s/overlays/staging/patches/service-loadbalancer.yaml` — patches `districtlive-server` Service type from `ClusterIP` to `LoadBalancer`
- `k8s/overlays/staging/patches/deployment-staging.yaml` — patches Deployment to reference `districtlive-secrets` via `secretKeyRef` for `DATABASE_URL`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`; adds `INGESTION_ENABLED=true`, `ENRICHMENT_ENABLED=true`
- `k8s/overlays/staging/patches/postgres-storage.yaml` — patches Postgres StatefulSet PVC `storageClassName` to `do-block-storage`

**Dependencies:** None (base manifests already exist at `k8s/base/`)

**Done when:** `kubectl apply -k k8s/overlays/staging --dry-run=client` succeeds without errors
<!-- END_PHASE_1 -->

<!-- START_PHASE_2 -->
### Phase 2: GitHub Actions deploy workflow

**Goal:** Automated build-push-deploy on every successful CI run against `main`.

**Components:**
- `.github/workflows/deploy.yml` — triggers on `workflow_run` completion of `ci` on `main`; steps: checkout, setup Bazelisk + pnpm + Node 22, `pnpm build`, `bazel build //:app`, `cp bazel-bin/app ./app`, `docker build`, `docker push` (ghcr.io, tagged with `${{ github.sha }}`), write kubeconfig from `KUBE_CONFIG` secret, `kustomize edit set image` to inject SHA tag, `kubectl apply -k k8s/overlays/staging`, `kubectl rollout status`

**Dependencies:** Phase 1 (overlay must exist for `kubectl apply` to succeed)

**Done when:** Workflow file is valid YAML, passes `actionlint` or equivalent check; logic is reviewable
<!-- END_PHASE_2 -->

<!-- START_PHASE_3 -->
### Phase 3: Staging setup runbook

**Goal:** Document every manual step needed to stand up a fresh staging cluster, from zero to first successful deploy.

**Components:**
- `docs/staging-setup.md` — covers: install prerequisites (`doctl`, `kubectl`); create DOKS cluster via `doctl kubernetes cluster create`; save kubeconfig; create `districtlive-server` namespace; create `ghcr-pull-secret` imagePullSecret; create `districtlive-secrets` Secret with all required env vars; configure GitHub Actions secrets (`GHCR_TOKEN`, `KUBE_CONFIG`); trigger first deploy

**Dependencies:** Phase 1 and Phase 2 (runbook references overlay and workflow)

**Done when:** A developer unfamiliar with the project can follow the runbook to a working staging environment without external assistance
<!-- END_PHASE_3 -->

## Additional Considerations

**Optional API keys:** `TICKETMASTER_API_KEY`, `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, and `BANDSINTOWN_APP_ID` are optional. The runbook documents them as optional entries in `districtlive-secrets`. The app starts without them; connectors that require them simply won't run.

**Postgres credentials in staging:** The Postgres StatefulSet still uses hardcoded `app:app` credentials internally (env vars on the StatefulSet pod). `DATABASE_URL` in `districtlive-secrets` must use the same credentials. This is acceptable for staging; the DB is not internet-accessible (ClusterIP only).

**Image tag strategy:** Only the SHA tag is pushed. No `latest` tag. This avoids ambiguity about what's deployed — the rollout status step confirms the SHA-tagged image is running.
