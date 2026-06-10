# ═══════════════════════════════════════════════════════════════════════════════
# 09-frontend-cicd-activate.ps1 — Commit + Push Frontend Workflow + Trigger CI/CD
# ═══════════════════════════════════════════════════════════════════════════════

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($msg)    { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Fail($msg)    { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  Activating Frontend GitHub CI/CD Pipeline"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""

# ───────────────────────────────────────────────────────────────
# 1. Detect Git Repo Root (bulletproof)
# ───────────────────────────────────────────────────────────────
try {
    $RepoRoot = git rev-parse --show-toplevel
} catch {
    Fail "This folder is not inside a Git repository. Initialize Git first."
}

Info "Repo root detected: $RepoRoot"

# Workflow file path
$WorkflowFile = Join-Path $RepoRoot ".github\workflows\frontend-deploy.yml"

# ───────────────────────────────────────────────────────────────
# 2. Verify workflow file exists
# ───────────────────────────────────────────────────────────────
if (-not (Test-Path $WorkflowFile)) {
    Fail "Workflow file not found: $WorkflowFile. Run 08-frontend-cicd-setup.ps1 first."
}

Info "Found workflow file: $WorkflowFile"

# ───────────────────────────────────────────────────────────────
# 3. Stage workflow file
# ───────────────────────────────────────────────────────────────
Info "Staging workflow file..."
git add $WorkflowFile

# ───────────────────────────────────────────────────────────────
# 4. Commit workflow
# ───────────────────────────────────────────────────────────────
Info "Committing workflow..."
git commit -m "Activate Frontend CI/CD Pipeline (frontend-deploy.yml)" | Out-Null

Success "Workflow committed."

# ───────────────────────────────────────────────────────────────
# 5. Push to main
# ───────────────────────────────────────────────────────────────
Info "Pushing to main..."
git push origin main

Success "Push complete. Frontend CI/CD pipeline triggered."

# ───────────────────────────────────────────────────────────────
# 6. Open GitHub Actions page
# ───────────────────────────────────────────────────────────────
$RepoURL = git remote get-url origin
$ActionsURL = $RepoURL.Replace(".git","") + "/actions"

Info "Opening GitHub Actions page..."
Start-Process $ActionsURL

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Success "Frontend CI/CD Activated!"
Write-Host "  GitHub Actions is now running your frontend pipeline."
Write-Host "════════════════════════════════════════════════════════════"
Write-Host ""
