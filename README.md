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

### 1. Create the Kind Cluster and Deploy Sample Apps

```powershell
cd setup
.\setup-cluster.ps1
```

This script will:
- Create a Kind cluster named `k8s-troubleshooting-demo`
- Deploy sample applications with various issues
- Display cluster information

### 2. Start kubectl Proxy (Method 1 - Recommended for Demo)

```powershell
kubectl proxy --port=8001
```

Keep this running in a separate terminal. Postman can now access the API at `http://localhost:8001`.

### 3. Get API Credentials (Method 2 - Token Authentication)

```powershell
cd setup
.\get-api-credentials.ps1
```

This will output the bearer token and API server URL for direct authentication.

### 4. Import Postman Collection

1. Open Postman
2. Click **Import** button
3. Select files from the `postman/` folder:
   - `K8s-Troubleshooting.postman_collection.json`
   - `Kind-Proxy.postman_environment.json`
   - `Kind-Token-Auth.postman_environment.json`
4. Select the appropriate environment from the dropdown (top-right)

## Project Structure

```
postman/
├── README.md                              # This file
├── kind-config.yaml                       # Kind cluster configuration
├── setup/
│   ├── setup-cluster.ps1                  # Create Kind cluster + deploy apps
│   └── get-api-credentials.ps1            # Extract token and certificates
├── sample-apps/
│   ├── 00-healthy-app.yaml                # Working baseline app
│   ├── 01-crashloop-app.yaml              # CrashLoopBackOff scenario
│   ├── 02-imagepull-error.yaml            # ImagePullBackOff scenario
│   └── 03-pending-pod.yaml                # Pending pod scenario
├── kubectl-commands/
│   └── troubleshooting-reference.md       # kubectl commands reference
├── postman/
│   ├── K8s-Troubleshooting.postman_collection.json
│   ├── Kind-Proxy.postman_environment.json
│   └── Kind-Token-Auth.postman_environment.json
└── presentation/
    └── demo-script.md                     # Presentation talking points
```

## Troubleshooting Scenarios

| Scenario | Pod Name | Issue | Root Cause |
|----------|----------|-------|------------|
| Healthy | healthy-app | None | Working baseline |
| CrashLoopBackOff | crashloop-app | Container keeps restarting | Invalid command causes immediate exit |
| ImagePullBackOff | imagepull-app | Cannot pull image | Non-existent image tag |
| Pending | pending-app | Pod stuck in Pending | Requesting 100Gi memory (unschedulable) |

## API Access Methods

### Method 1: kubectl proxy (Simple)

```powershell
kubectl proxy --port=8001
```

- **Base URL**: `http://localhost:8001`
- **Authentication**: None required (proxy handles it)
- **Best for**: Demos, local development

### Method 2: Direct with Bearer Token

```powershell
# Get the token
$TOKEN = kubectl create token default --duration=24h
```

- **Base URL**: `https://127.0.0.1:<port>` (get port from cluster info)
- **Header**: `Authorization: Bearer <token>`
- **Best for**: Production-like scenarios, automation

## kubectl vs Postman Comparison

| Aspect | kubectl | Postman |
|--------|---------|---------|
| Response Format | Plain text/YAML | Structured JSON with highlighting |
| Reusability | Re-type or script | Saved requests, one-click |
| Multi-cluster | Context switching | Environment dropdown |
| Filtering | grep/jq piping | Query params + Visualizer |
| Automation | Shell scripts | Collection Runner + Tests |
| Sharing | Documentation | Export/Import collections |
| Learning Curve | CLI commands | Visual interface |

## Cleanup

```powershell
# Delete the Kind cluster
kind delete cluster --name k8s-troubleshooting-demo
```

## Useful Links

- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Postman Learning Center](https://learning.postman.com/)

