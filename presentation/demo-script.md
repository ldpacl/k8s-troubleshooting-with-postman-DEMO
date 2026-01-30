# Kubernetes Troubleshooting with Postman
## Presentation Demo Script

**Duration:** 15-20 minutes  
**Audience:** Intermediate Kubernetes users  
**Goal:** Show how Postman can make K8s troubleshooting more efficient

---

## Pre-Demo Checklist

- [ ] Kind cluster running with sample apps deployed
- [ ] kubectl proxy running on port 8001
- [ ] Postman desktop app open
- [ ] Collection and environments imported
- [ ] Terminal ready for kubectl commands
- [ ] Console pane open in Postman (View > Show Postman Console)

**Quick verification:**
```powershell
kubectl get pods -n troubleshooting-demo
```
Expected output shows 4 pods with various statuses.

---

## Demo Flow

### PART 1: Introduction (2 minutes)

**Talking Points:**

> "Today I'm going to show you how Postman can be a powerful tool for Kubernetes troubleshooting. Most of us are familiar with kubectl - it's great for quick checks, but when you're doing systematic troubleshooting, there are some limitations."

**Show the problem:**
```powershell
# Run these commands quickly to show the "traditional" approach
kubectl get pods -n troubleshooting-demo
kubectl describe pod crashloop-app -n troubleshooting-demo
kubectl logs crashloop-app -n troubleshooting-demo --previous
kubectl get events -n troubleshooting-demo --field-selector involvedObject.name=crashloop-app
```

> "That's 4 different commands, and the output is text that you have to read through. Now let me show you the Postman approach."

---

### PART 2: Postman Setup (2 minutes)

**Show the collection structure:**

1. Open Postman
2. Show the imported collection "K8s Troubleshooting Demo"
3. Expand folders to show organization
4. Show the environment selector (Kind-Proxy)

**Talking Points:**

> "The collection is organized by use case. We have core operations, then specific troubleshooting scenarios, and automation tools. Notice how we're using environments - I can switch between different clusters with one click."

**Demonstrate environment variables:**
- Click the eye icon to show current environment
- Point out `base_url`, `namespace`, `pod_name`

> "All our requests use these variables, so switching clusters is just changing the environment - no editing commands."

---

### PART 3: Scenario 1 - CrashLoopBackOff (5 minutes)

**kubectl approach first (30 seconds):**
```powershell
kubectl get pods -n troubleshooting-demo
kubectl describe pod crashloop-app -n troubleshooting-demo | Select-String -Pattern "State:|Restart Count:|Last State:"
```

> "With kubectl, I need to parse through the output to find the relevant information."

**Now Postman (2 minutes):**

1. Navigate to: **Scenario: CrashLoopBackOff** > **1. Check CrashLoop Pod Status**
2. Click **Send**
3. Show the response body

**Key points to highlight:**
- Structured JSON response
- Syntax highlighting
- Collapsible sections

4. Click the **Console** at the bottom
5. Show the test output

> "Look at the console - our tests automatically analyzed the response and told us exactly what's wrong: CrashLoopBackOff, restart count, and exit code. No grep required."

**Show the test script (briefly):**
- Click the **Tests** tab
- Scroll through the code

> "These tests run automatically and give us immediate insights. We can customize these for our specific applications."

**Get the logs:**

1. Navigate to: **2. Get CrashLoop Pod Logs (Previous)**
2. Click **Send**
3. Show the log output in console

> "And here's the root cause - the application is logging that it's missing a configuration file. Two clicks and we've diagnosed the problem."

**Comparison summary:**

| kubectl | Postman |
|---------|---------|
| 3-4 commands | 2 clicks |
| Manual parsing | Automated analysis |
| Copy/paste pod names | Pre-configured variables |

---

### PART 4: Scenario 2 - ImagePullBackOff (4 minutes)

**Quick kubectl check:**
```powershell
kubectl get pods -n troubleshooting-demo | Select-String imagepull
```

**Postman approach:**

1. Navigate to: **Scenario: ImagePullBackOff** > **1. Check ImagePull Pod Status**
2. Click **Send**
3. Show `containerStatuses[0].state.waiting` in response

> "The JSON structure makes it easy to find exactly what we need. The waiting state shows ImagePullBackOff and even gives us the error message."

4. Navigate to: **2. Get ImagePull Pod Events**
5. Click **Send**
6. Show console output

> "The test script finds all Failed events and shows us the image pull error. We can see the exact image name that's failing - nginx with a tag that doesn't exist."

**Highlight the field selector:**
- Show the URL with `fieldSelector=involvedObject.name=imagepull-app`

> "This is the same filtering that kubectl's --field-selector does, but it's saved in our request so we don't have to remember the syntax."

---

### PART 5: Scenario 3 - Pending Pod (4 minutes)

**kubectl approach:**
```powershell
kubectl get pods -n troubleshooting-demo | Select-String pending
kubectl describe pod pending-app -n troubleshooting-demo | Select-String -Pattern "Status:|Reason:|Message:"
```

**Postman approach:**

1. Navigate to: **Scenario: Pending Pod** > **1. Check Pending Pod Status**
2. Click **Send**
3. Point out `status.phase: "Pending"`
4. Show the console analysis of conditions

> "The test script checks the conditions and shows us the scheduling status. We can also see the resource requests - this pod is asking for 100 gigabytes of memory."

5. Navigate to: **3. Check Node Resources**
6. Click **Send**
7. Show node allocatable resources in console

> "And here's why it can't be scheduled - our node only has a few gigabytes available. The comparison is immediate."

**Key insight:**

> "With kubectl, you'd need to run multiple commands and manually compare the pod's requests with node capacity. Postman shows both in structured format, and we could even write tests to compare them automatically."

---

### PART 6: Automation Features (3 minutes)

**Health Check Demo:**

1. Navigate to: **Automation** > **Health Check - All Pods**
2. Click **Send**
3. Show the console output with the health summary

> "This single request scans all pods and categorizes them. Green checkmarks for healthy, warnings for problems. This is something you'd need a shell script to do with kubectl."

**Problem Detector Demo:**

1. Navigate to: **Problem Pod Detector**
2. Click **Send**
3. Show the test results (should show failures for problem pods)

> "Notice the test actually fails when it finds critical issues. This is powerful for CI/CD integration."

**Collection Runner (mention briefly):**

> "You can also use the Collection Runner to execute all these checks in sequence, export results, and even schedule them. Combine with Newman, Postman's CLI tool, for CI/CD pipelines."

---

### PART 7: Token Authentication (1 minute)

**Quick demonstration:**

1. Show the Kind-Token-Auth environment
2. Point out the `bearer_token` variable
3. Mention the get-api-credentials.ps1 script

> "For production scenarios, you'd use token authentication instead of kubectl proxy. The setup script extracts the token, and you just paste it into the environment. Same collection, different auth method."

---

### PART 8: Summary & Q&A (2 minutes)

**Side-by-side summary:**

| Feature | kubectl | Postman |
|---------|---------|---------|
| Learning curve | Commands to memorize | Visual interface |
| Response format | Plain text | Structured JSON |
| Reusability | Scripts/aliases | Saved collections |
| Multi-cluster | Context switching | Environment dropdown |
| Automation | Shell scripting | Built-in tests + Runner |
| Sharing | Documentation | Export/Import |
| CI/CD | Custom scripts | Newman integration |

**When to use each:**

> "kubectl is still essential for interactive debugging, exec into containers, port forwarding. But for systematic troubleshooting, health monitoring, and team collaboration - Postman gives you a more powerful and shareable workflow."

**Closing:**

> "All the resources from today's demo are available in this repository. You can import the collection and start using it with your own clusters. Questions?"

---

## Backup Talking Points

### If someone asks about security:
> "kubectl proxy only accepts connections from localhost, so it's safe for local development. For remote access, use token authentication with RBAC-limited service accounts."

### If someone asks about other tools:
> "Yes, there are Kubernetes dashboards and monitoring tools. Postman fills a different niche - it's for developers and operators who want direct API access with the flexibility to customize requests and write tests."

### If something fails during demo:
> "That's actually a great troubleshooting example! Let's debug it..."
- Check kubectl proxy is running
- Check environment is selected
- Check namespace variable

### If time is short:
Skip Part 5 (Pending Pod) and Part 7 (Token Auth) - cover in Q&A if asked.

---

## Post-Demo Resources

Share with attendees:
- This repository (GitHub/internal)
- Kubernetes API documentation: https://kubernetes.io/docs/reference/kubernetes-api/
- Postman Learning Center: https://learning.postman.com/
- Newman (Postman CLI): https://www.npmjs.com/package/newman

---

## Demo Recovery Commands

If you need to reset the demo environment:

```powershell
# Delete and recreate sample apps
kubectl delete pods -n troubleshooting-demo --all
kubectl apply -f sample-apps/ -n troubleshooting-demo

# Restart kubectl proxy if needed
# (In new terminal)
kubectl proxy --port=8001

# Verify pods are in expected states
# Wait ~30 seconds for pods to reach their "problem" states
kubectl get pods -n troubleshooting-demo -w
```

