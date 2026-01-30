# get-api-credentials.ps1
# Extracts Kubernetes API credentials for direct Postman access (token authentication)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Kubernetes API Credentials Extractor" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get cluster info
Write-Host "[1/4] Getting cluster information..." -ForegroundColor Yellow

try {
    $clusterInfo = kubectl cluster-info 2>&1
    Write-Host $clusterInfo
} catch {
    Write-Host "  ✗ Cannot connect to cluster. Is the cluster running?" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get API Server URL
Write-Host "[2/4] Extracting API Server URL..." -ForegroundColor Yellow

$apiServer = kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
Write-Host "  API Server: $apiServer" -ForegroundColor Green

Write-Host ""

# Create a service account token (valid for 24 hours)
Write-Host "[3/4] Creating service account token..." -ForegroundColor Yellow

# First, ensure we have cluster-admin access for the demo
# Create a service account if it doesn't exist
$saYaml = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: postman-admin
  namespace: troubleshooting-demo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: postman-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: postman-admin
  namespace: troubleshooting-demo
"@

# Create namespace if it doesn't exist
kubectl create namespace troubleshooting-demo --dry-run=client -o yaml | kubectl apply -f - 2>$null

# Apply the service account
$saYaml | kubectl apply -f - 2>$null

# Generate token
$token = kubectl create token postman-admin -n troubleshooting-demo --duration=24h

Write-Host "  ✓ Token created (valid for 24 hours)" -ForegroundColor Green

Write-Host ""

# Get CA certificate (for HTTPS verification)
Write-Host "[4/4] Extracting CA certificate..." -ForegroundColor Yellow

$caCert = kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'

if ($caCert) {
    $caPath = Join-Path $PSScriptRoot "ca.crt"
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($caCert)) | Out-File -FilePath $caPath -Encoding utf8
    Write-Host "  ✓ CA certificate saved to: $caPath" -ForegroundColor Green
} else {
    Write-Host "  ! CA certificate not found (may be using insecure connection)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Credentials Ready!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "For Postman Configuration:" -ForegroundColor Yellow
Write-Host ""
Write-Host "API Server URL:" -ForegroundColor White
Write-Host $apiServer -ForegroundColor Cyan
Write-Host ""
Write-Host "Bearer Token (copy this entire line):" -ForegroundColor White
Write-Host $token -ForegroundColor Cyan
Write-Host ""

Write-Host "Postman Setup Instructions:" -ForegroundColor Yellow
Write-Host "  1. Open the 'Kind-Token-Auth' environment in Postman" -ForegroundColor White
Write-Host "  2. Set 'base_url' to: $apiServer" -ForegroundColor White
Write-Host "  3. Set 'bearer_token' to the token above" -ForegroundColor White
Write-Host "  4. In Postman Settings, disable 'SSL certificate verification'" -ForegroundColor White
Write-Host "     (Settings > General > SSL certificate verification > OFF)" -ForegroundColor White
Write-Host ""

# Also save to a file for easy copy-paste
$credentialsPath = Join-Path $PSScriptRoot "credentials.txt"
@"
Kubernetes API Credentials
Generated: $(Get-Date)
Valid for: 24 hours

API Server URL:
$apiServer

Bearer Token:
$token

Usage in Postman:
- Header: Authorization: Bearer <token>
- Or use Postman's Authorization tab with Type: Bearer Token
"@ | Out-File -FilePath $credentialsPath -Encoding utf8

Write-Host "Credentials also saved to: $credentialsPath" -ForegroundColor Gray

