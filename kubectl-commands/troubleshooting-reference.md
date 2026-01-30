# kubectl vs Postman: Troubleshooting Reference

This document provides side-by-side comparisons of kubectl commands and their Postman API equivalents for Kubernetes troubleshooting.

---

## Quick Reference Table

| Task | kubectl | Postman Request |
|------|---------|-----------------|
| List pods | `kubectl get pods -n <ns>` | GET `/api/v1/namespaces/{ns}/pods` |
| Pod details | `kubectl describe pod <name>` | GET `/api/v1/namespaces/{ns}/pods/{name}` |
| Pod logs | `kubectl logs <pod>` | GET `/api/v1/namespaces/{ns}/pods/{name}/log` |
| Previous logs | `kubectl logs <pod> --previous` | GET `.../log?previous=true` |
| Events | `kubectl get events` | GET `/api/v1/namespaces/{ns}/events` |
| Pod events | `kubectl get events --field-selector...` | GET `.../events?fieldSelector=involvedObject.name={pod}` |
| Node info | `kubectl describe nodes` | GET `/api/v1/nodes` |
| Cluster version | `kubectl version` | GET `/version` |

---

## Scenario 1: CrashLoopBackOff

### Problem Description
A pod's container keeps crashing and restarting, entering a backoff loop.

### kubectl Approach (Multiple Commands)

```powershell
# Step 1: List pods to see the status
kubectl get pods -n troubleshooting-demo
# Output shows: crashloop-app   0/1   CrashLoopBackOff   5   2m

# Step 2: Describe pod for details
kubectl describe pod crashloop-app -n troubleshooting-demo
# Look for:
#   - State: Waiting (reason: CrashLoopBackOff)
#   - Last State: Terminated (exit code, reason)
#   - Restart Count
#   - Events section

# Step 3: Check logs from crashed container
kubectl logs crashloop-app -n troubleshooting-demo --previous
# Shows logs from the previous (crashed) container instance
```

### Postman Approach (Structured Data)

**Request 1: Get Pod Details**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/pods/crashloop-app
```

**Key JSON paths to examine:**
```javascript
// Container state
response.status.containerStatuses[0].state.waiting.reason
// → "CrashLoopBackOff"

// Restart count
response.status.containerStatuses[0].restartCount
// → 5

// Last termination reason
response.status.containerStatuses[0].lastState.terminated.exitCode
// → 1 (non-zero = error)

response.status.containerStatuses[0].lastState.terminated.reason
// → "Error"
```

**Request 2: Get Previous Container Logs**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/pods/crashloop-app/log?previous=true
```

### Comparison

| Aspect | kubectl | Postman |
|--------|---------|---------|
| Commands needed | 3+ commands | 2 requests |
| Output format | Text (requires parsing) | Structured JSON |
| Restart count | Buried in describe output | Direct access via JSON path |
| Exit code | Requires reading describe | Programmatic access |
| Automation | Shell script required | Built-in tests |

---

## Scenario 2: ImagePullBackOff

### Problem Description
Kubernetes cannot pull the container image, often due to typos, missing tags, or registry issues.

### kubectl Approach

```powershell
# Step 1: Check pod status
kubectl get pods -n troubleshooting-demo
# Output: imagepull-app   0/1   ImagePullBackOff   0   1m

# Step 2: Describe for details
kubectl describe pod imagepull-app -n troubleshooting-demo
# Look for:
#   - State: Waiting (reason: ImagePullBackOff)
#   - Events: Failed to pull image...

# Step 3: Get specific events
kubectl get events -n troubleshooting-demo --field-selector involvedObject.name=imagepull-app
```

### Postman Approach

**Request 1: Get Pod Details**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/pods/imagepull-app
```

**Key JSON paths:**
```javascript
// Waiting state
response.status.containerStatuses[0].state.waiting.reason
// → "ImagePullBackOff" or "ErrImagePull"

// Error message
response.status.containerStatuses[0].state.waiting.message
// → "rpc error: code = NotFound..."

// Image being pulled
response.spec.containers[0].image
// → "nginx:this-tag-does-not-exist-v999"
```

**Request 2: Get Pod Events**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/events?fieldSelector=involvedObject.name=imagepull-app
```

**Event analysis:**
```javascript
// Find failed events
response.items.filter(e => e.reason === 'Failed')
// Each event has:
//   - reason: "Failed"
//   - message: "Failed to pull image..."
//   - type: "Warning"
```

### Comparison

| Aspect | kubectl | Postman |
|--------|---------|---------|
| Image name | Parse from describe | `spec.containers[0].image` |
| Error message | In Events section | `containerStatuses[0].state.waiting.message` |
| Filter events | --field-selector flag | Query parameter |
| Pattern detection | grep/awk | JavaScript tests |

---

## Scenario 3: Pending Pod

### Problem Description
Pod remains in Pending state because the scheduler cannot place it on any node.

### kubectl Approach

```powershell
# Step 1: Check pod status
kubectl get pods -n troubleshooting-demo
# Output: pending-app   0/1   Pending   0   5m

# Step 2: Describe to find reason
kubectl describe pod pending-app -n troubleshooting-demo
# Look for:
#   - Status: Pending
#   - Conditions: PodScheduled = False
#   - Events: FailedScheduling

# Step 3: Check node resources
kubectl describe nodes
# Look for Allocatable resources

# Step 4: Get scheduling events
kubectl get events -n troubleshooting-demo --field-selector reason=FailedScheduling
```

### Postman Approach

**Request 1: Get Pod Details**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/pods/pending-app
```

**Key JSON paths:**
```javascript
// Phase
response.status.phase
// → "Pending"

// Scheduling condition
response.status.conditions.find(c => c.type === 'PodScheduled')
// → { status: "False", reason: "Unschedulable", message: "..." }

// Resource requests (the cause)
response.spec.containers[0].resources.requests.memory
// → "100Gi"
```

**Request 2: Check Node Resources**
```
GET {{base_url}}/api/v1/nodes
```

**Node analysis:**
```javascript
// Available memory per node
response.items.forEach(node => {
    console.log(node.metadata.name, node.status.allocatable.memory);
});
// → "kind-control-plane" "8Gi"
// Compare with pod request of 100Gi → impossible!
```

**Request 3: Get Scheduling Events**
```
GET {{base_url}}/api/v1/namespaces/troubleshooting-demo/events?fieldSelector=involvedObject.name=pending-app
```

### Comparison

| Aspect | kubectl | Postman |
|--------|---------|---------|
| Scheduling reason | Events section | `conditions[].message` |
| Resource comparison | Manual inspection | Programmatic check |
| Node capacity | Separate describe | Single API call |
| Automation | Complex scripts | Simple tests |

---

## Common kubectl Commands Reference

### Pod Operations

```powershell
# List all pods
kubectl get pods -n troubleshooting-demo

# List pods with more details
kubectl get pods -n troubleshooting-demo -o wide

# List pods with custom columns
kubectl get pods -n troubleshooting-demo -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount

# Watch pods in real-time
kubectl get pods -n troubleshooting-demo -w

# Get pod YAML
kubectl get pod <pod-name> -n troubleshooting-demo -o yaml

# Get pod JSON
kubectl get pod <pod-name> -n troubleshooting-demo -o json
```

### Log Operations

```powershell
# Get logs
kubectl logs <pod-name> -n troubleshooting-demo

# Follow logs (stream)
kubectl logs <pod-name> -n troubleshooting-demo -f

# Last 100 lines
kubectl logs <pod-name> -n troubleshooting-demo --tail=100

# Logs with timestamps
kubectl logs <pod-name> -n troubleshooting-demo --timestamps

# Previous container logs
kubectl logs <pod-name> -n troubleshooting-demo --previous

# Logs from specific container (multi-container pods)
kubectl logs <pod-name> -n troubleshooting-demo -c <container-name>
```

### Event Operations

```powershell
# All events in namespace
kubectl get events -n troubleshooting-demo

# Sorted by time
kubectl get events -n troubleshooting-demo --sort-by='.lastTimestamp'

# Filter by pod
kubectl get events -n troubleshooting-demo --field-selector involvedObject.name=<pod-name>

# Only warnings
kubectl get events -n troubleshooting-demo --field-selector type=Warning
```

### Node Operations

```powershell
# List nodes
kubectl get nodes

# Describe nodes (detailed)
kubectl describe nodes

# Node resources
kubectl top nodes  # Requires metrics-server
```

---

## API Endpoints Reference

### Core v1 API

| Resource | Endpoint |
|----------|----------|
| Pods | `/api/v1/namespaces/{namespace}/pods` |
| Pod (specific) | `/api/v1/namespaces/{namespace}/pods/{name}` |
| Pod logs | `/api/v1/namespaces/{namespace}/pods/{name}/log` |
| Events | `/api/v1/namespaces/{namespace}/events` |
| Nodes | `/api/v1/nodes` |
| Namespaces | `/api/v1/namespaces` |
| Services | `/api/v1/namespaces/{namespace}/services` |
| ConfigMaps | `/api/v1/namespaces/{namespace}/configmaps` |
| Secrets | `/api/v1/namespaces/{namespace}/secrets` |

### Log Query Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `tailLines` | Last N lines | `?tailLines=100` |
| `previous` | Previous container | `?previous=true` |
| `timestamps` | Include timestamps | `?timestamps=true` |
| `sinceSeconds` | Logs from last N seconds | `?sinceSeconds=3600` |
| `follow` | Stream logs | `?follow=true` |

### Event Field Selectors

| Selector | Description | Example |
|----------|-------------|---------|
| `involvedObject.name` | Filter by object name | `?fieldSelector=involvedObject.name=my-pod` |
| `involvedObject.kind` | Filter by object kind | `?fieldSelector=involvedObject.kind=Pod` |
| `type` | Filter by event type | `?fieldSelector=type=Warning` |
| `reason` | Filter by reason | `?fieldSelector=reason=FailedScheduling` |

---

## When to Use Each Tool

### Use kubectl when:
- Quick one-off checks
- Interactive debugging sessions
- Streaming logs (`-f` flag)
- Executing commands in containers
- Port forwarding
- You need shell completion

### Use Postman when:
- Building reusable troubleshooting workflows
- Sharing with team members
- Automated health checks
- Comparing responses across clusters
- Need structured data for analysis
- Creating documentation
- Building CI/CD integration
- Training and demonstrations

### Use Both:
- Start with Postman for structured analysis
- Switch to kubectl for interactive debugging
- Use kubectl for actions (exec, port-forward)
- Use Postman for monitoring and automation

