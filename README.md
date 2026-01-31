# Kubernetes Troubleshooting with Postman

A demonstration project showcasing how to troubleshoot Kubernetes issues using Postman compared to traditional kubectl commands.

## Prerequisites

- **Docker Desktop** - Running and configured
- **Kind** - Kubernetes in Docker ([Install Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- **kubectl** - Kubernetes CLI ([Install Guide](https://kubernetes.io/docs/tasks/tools/))
- **Postman** - Desktop application ([Download](https://www.postman.com/downloads/))

### Windows Installation (PowerShell as Administrator)

```powershell
# Install Kind using Chocolatey
choco install kind -y

# Or download directly
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe C:\Windows\kind.exe
```

## Quick Start

### 1. Deploy Sample Apps

```powershell
# Create namespaces
kubectl create namespace demo
kubectl create namespace demo2

# Deploy sample apps
kubectl apply -f sample-apps/
```

### 2. Start kubectl Proxy

```powershell
kubectl proxy --port=8001
```

Keep this running in a separate terminal. Postman can now access the API at `http://localhost:8001`.

### 3. Import Postman Collection & Environment

1. Open Postman
2. Click **Import** button
3. Select files from the `postman/` folder:
   - `K8s-Troubleshooting.postman_collection.json`
   - `Kind-Proxy.postman_environment.json`
4. Select **Kind-Proxy** environment from the dropdown (top-right)

### 4. Run Diagnostics

1. Open **Full Pod Diagnostics** request
2. Click **Send**
3. View the **Console** (View → Show Postman Console) for the full report

## Postman Collection

The collection contains 3 streamlined requests:

| Request | Purpose |
|---------|---------|
| **Full Pod Diagnostics** | Comprehensive analysis of ALL pods in namespace |
| **Get Pod Logs** | Fetch logs for a specific pod |
| **Get Pod Events** | Get Kubernetes events for a specific pod |

### Switching Namespaces

**Important:** Environment variables take precedence over Collection variables.

To switch namespaces:
1. Click on your environment name (e.g., **Kind-Proxy**) in top-right
2. Click **Edit** (or the eye icon → Edit)
3. Change the `namespace` value (e.g., `demo`, `demo2`, `default`)
4. Click **Save**

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `base_url` | Kubernetes API URL | `http://localhost:8001` |
| `namespace` | Target namespace to scan | `demo`, `demo2`, `default` |
| `pod_name` | Pod name for logs/events | `pod-1`, `broken-worker` |
| `previous` | Get crashed container logs | `true` or `false` |

## Project Structure

```
postman/
├── README.md                              # This file
├── kind-config.yaml                       # Kind cluster configuration
├── setup/
│   ├── setup-cluster.ps1                  # Create Kind cluster + deploy apps
│   └── get-api-credentials.ps1            # Extract token and certificates
├── sample-apps/
│   ├── 00-healthy-app.yaml                # Healthy pod (namespace: demo)
│   ├── 01-crashloop-app.yaml              # CrashLoopBackOff (namespace: demo)
│   ├── 02-imagepull-error.yaml            # ImagePullBackOff (namespace: demo)
│   ├── 03-pending-pod.yaml                # Pending pod (namespace: demo)
│   └── demo2-pods.yaml                    # Mixed pods (namespace: demo2)
├── kubectl-commands/
│   └── troubleshooting-reference.md       # kubectl commands reference
├── postman/
│   ├── K8s-Troubleshooting.postman_collection.json
│   ├── Kind-Proxy.postman_environment.json
│   └── Kind-Token-Auth.postman_environment.json
└── presentation/
    └── demo-script.md                     # Presentation talking points
```

## Sample Apps

### Namespace: demo

| Pod Name | Status | Issue |
|----------|--------|-------|
| pod-1 | Healthy | Working baseline (nginx) |
| pod-2 | CrashLoopBackOff | Container exits with error |
| pod-3 | ImagePullBackOff | Non-existent image tag |
| pod-4 | Pending | Requests 100Gi memory |

### Namespace: demo2

| Pod Name | Status | Issue |
|----------|--------|-------|
| web-server | Healthy | nginx web server |
| cache-server | Healthy | redis cache |
| broken-worker | CrashLoopBackOff | Database connection error |
| bad-image-app | ImagePullBackOff | Fake internal image |
| resource-hog | Pending | Requests 500Gi memory |

## Console Output Example

When you run **Full Pod Diagnostics**, the Console shows:

```
╔══════════════════════════════════════════════════════════════╗
║         KUBERNETES POD DIAGNOSTICS REPORT                   ║
╚══════════════════════════════════════════════════════════════╝

📍 Namespace: demo
📊 Total Pods: 4
✅ Healthy: 1
❌ Unhealthy: 3

┌──────────────────────────────────────────────────────────────┐
│ ✅ HEALTHY PODS                                              │
└──────────────────────────────────────────────────────────────┘
  ✓ pod-1
    Phase: Running | Containers: nginx

┌──────────────────────────────────────────────────────────────┐
│ ❌ UNHEALTHY PODS                                            │
└──────────────────────────────────────────────────────────────┘
  ✗ pod-2
    Phase: Running
    ├─ Container: container-123xyz
    │  State: Waiting
    │  Reason: CrashLoopBackOff
    │  Restart Count: 5

┌──────────────────────────────────────────────────────────────┐
│ 📋 ISSUE SUMMARY                                             │
└──────────────────────────────────────────────────────────────┘
  🔄 CrashLoopBackOff: 1 occurrence(s)
  🖼️ ImagePullBackOff: 1 occurrence(s)
```

## API Access Methods

### Method 1: kubectl proxy (Recommended for Demo)

```powershell
kubectl proxy --port=8001
```

- **Base URL**: `http://localhost:8001`
- **Authentication**: None required (proxy handles it)

### Method 2: Direct with Bearer Token

```powershell
cd setup
.\get-api-credentials.ps1
```

- **Base URL**: `https://127.0.0.1:6443`
- **Header**: `Authorization: Bearer <token>`
- Update token in **Kind-Token-Auth** environment

## kubectl vs Postman Comparison

| Aspect | kubectl | Postman |
|--------|---------|---------|
| Response Format | Plain text/YAML | Structured JSON with highlighting |
| Reusability | Re-type or script | Saved requests, one-click |
| Multi-namespace | Add `-n` flag each time | Change environment variable |
| Automation | Shell scripts | Built-in tests + Console output |
| Sharing | Documentation | Export/Import collections |

## Cleanup

```powershell
# Delete sample apps
kubectl delete namespace demo
kubectl delete namespace demo2

# Or delete the entire Kind cluster
kind delete cluster --name k8s-troubleshooting-demo
```

## Useful Links

- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Postman Learning Center](https://learning.postman.com/)
