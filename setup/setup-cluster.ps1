# setup-cluster.ps1
# Creates a Kind cluster and deploys sample applications for troubleshooting demo

$ErrorActionPreference = "Stop"

$ClusterName = "k8s-troubleshooting-demo"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Kubernetes Troubleshooting Demo Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker info | Out-Null
    Write-Host "  ✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check Kind
try {
    kind version | Out-Null
    Write-Host "  ✓ Kind is installed" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Kind is not installed. Please install Kind first." -ForegroundColor Red
    Write-Host "    Run: choco install kind" -ForegroundColor Gray
    exit 1
}

# Check kubectl
try {
    kubectl version --client | Out-Null
    Write-Host "  ✓ kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "  ✗ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if cluster already exists
Write-Host "[2/6] Checking for existing cluster..." -ForegroundColor Yellow
$existingClusters = kind get clusters 2>$null
if ($existingClusters -contains $ClusterName) {
    Write-Host "  ! Cluster '$ClusterName' already exists." -ForegroundColor Yellow
    $response = Read-Host "  Delete and recreate? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "  Deleting existing cluster..." -ForegroundColor Yellow
        kind delete cluster --name $ClusterName
    } else {
        Write-Host "  Using existing cluster." -ForegroundColor Green
    }
}

Write-Host ""

# Create cluster
Write-Host "[3/6] Creating Kind cluster..." -ForegroundColor Yellow
$configPath = Join-Path $RootDir "kind-config.yaml"

if (!(kind get clusters 2>$null | Select-String $ClusterName)) {
    kind create cluster --config $configPath
    Write-Host "  ✓ Cluster created successfully" -ForegroundColor Green
} else {
    Write-Host "  ✓ Using existing cluster" -ForegroundColor Green
}

Write-Host ""

# Set kubectl context
Write-Host "[4/6] Configuring kubectl context..." -ForegroundColor Yellow
kubectl cluster-info --context "kind-$ClusterName"
Write-Host "  ✓ kubectl configured" -ForegroundColor Green

Write-Host ""

# Create demo namespace
Write-Host "[5/6] Creating demo namespace..." -ForegroundColor Yellow
kubectl create namespace troubleshooting-demo --dry-run=client -o yaml | kubectl apply -f -
Write-Host "  ✓ Namespace 'troubleshooting-demo' ready" -ForegroundColor Green

Write-Host ""

# Deploy sample applications
Write-Host "[6/6] Deploying sample applications..." -ForegroundColor Yellow
$sampleAppsDir = Join-Path $RootDir "sample-apps"

$apps = @(
    "00-healthy-app.yaml",
    "01-crashloop-app.yaml",
    "02-imagepull-error.yaml",
    "03-pending-pod.yaml"
)

foreach ($app in $apps) {
    $appPath = Join-Path $sampleAppsDir $app
    if (Test-Path $appPath) {
        kubectl apply -f $appPath -n troubleshooting-demo
        Write-Host "  ✓ Deployed: $app" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not found: $app" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start kubectl proxy:  kubectl proxy --port=8001" -ForegroundColor White
Write-Host "  2. Import Postman collection from: postman/" -ForegroundColor White
Write-Host "  3. Select 'Kind-Proxy' environment in Postman" -ForegroundColor White
Write-Host ""
Write-Host "View pods:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n troubleshooting-demo" -ForegroundColor White
Write-Host ""

# Show current pod status
Write-Host "Current pod status:" -ForegroundColor Yellow
Start-Sleep -Seconds 3  # Give pods time to start
kubectl get pods -n troubleshooting-demo -o wide

