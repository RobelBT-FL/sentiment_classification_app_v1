#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 06-ops.sh — Day-to-day operations: logs, status, rollback, scale, teardown
# Usage: bash 06-ops.sh <command>
# Commands: logs | status | revisions | rollback | scale-warm | scale-zero | teardown
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-config.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

COMMAND="${1:-help}"

case "${COMMAND}" in

# ── Stream live logs ──────────────────────────────────────────────────────────
logs)
  info "Streaming live logs from '${ACA_APP}' (Ctrl+C to stop)..."
  az containerapp logs show \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --follow \
    --tail 50
  ;;

# ── Show app status + live URL ────────────────────────────────────────────────
status)
  info "App status for '${ACA_APP}'..."
  az containerapp show \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "{Name:name, FQDN:properties.configuration.ingress.fqdn, ProvisioningState:properties.provisioningState, RunningStatus:properties.runningStatus}" \
    --output table

  FQDN=$(az containerapp show \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv)
  echo ""
  echo "  🌐 Live API  : https://${FQDN}"
  echo "  📖 API Docs  : https://${FQDN}/docs"
  echo ""

  info "Current scaling:"
  az containerapp show \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "{MinReplicas:properties.template.scale.minReplicas, MaxReplicas:properties.template.scale.maxReplicas}" \
    --output table
  ;;

# ── List all revisions ────────────────────────────────────────────────────────
revisions)
  info "Revision history for '${ACA_APP}'..."
  az containerapp revision list \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "[].{Revision:name, Active:properties.active, Traffic:properties.trafficWeight, Created:properties.createdTime, State:properties.healthState}" \
    --output table
  ;;

# ── Roll back to previous revision ────────────────────────────────────────────
rollback)
  info "Available revisions:"
  az containerapp revision list \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "[].{Revision:name, Active:properties.active, Created:properties.createdTime}" \
    --output table

  echo ""
  read -r -p "  Enter revision name to activate: " TARGET_REVISION

  if [[ -z "${TARGET_REVISION}" ]]; then
    error "No revision specified."
  fi

  warn "Rolling back to revision: ${TARGET_REVISION}"
  az containerapp revision activate \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --revision "${TARGET_REVISION}" \
    --output none

  success "Rollback complete. Traffic now routed to: ${TARGET_REVISION}"
  ;;

# ── Scale to always-warm (min-replicas=1, removes cold start) ─────────────────
scale-warm)
  warn "Switching to always-warm (min-replicas=1). This increases cost (~\$50-80/month extra)."
  read -r -p "  Confirm? [y/N]: " CONFIRM
  [[ "${CONFIRM}" =~ ^[Yy]$ ]] || { info "Cancelled."; exit 0; }

  az containerapp update \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --min-replicas 1 \
    --max-replicas "${ACA_MAX_REPLICAS}" \
    --output none

  success "App set to always-warm (min-replicas=1). No more cold starts."
  ;;

# ── Scale to zero (save money, accept cold starts) ────────────────────────────
scale-zero)
  info "Switching to scale-to-zero (min-replicas=0). Cold starts will occur but cost is minimal."

  az containerapp update \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --min-replicas 0 \
    --max-replicas "${ACA_MAX_REPLICAS}" \
    --output none

  success "App set to scale-to-zero (min-replicas=0)."
  ;;

# ── Update environment variable ───────────────────────────────────────────────
set-env)
  KEY="${2:-}"
  VAL="${3:-}"
  if [[ -z "${KEY}" || -z "${VAL}" ]]; then
    error "Usage: bash 06-ops.sh set-env KEY VALUE"
  fi
  info "Setting env var: ${KEY}=..."
  az containerapp update \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --set-env-vars "${KEY}=${VAL}" \
    --output none
  success "Environment variable '${KEY}' updated."
  ;;

# ── Restart current revision ──────────────────────────────────────────────────
restart)
  info "Restarting latest revision of '${ACA_APP}'..."
  LATEST_REVISION=$(az containerapp revision list \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "[0].name" \
    --output tsv)

  az containerapp revision restart \
    --name "${ACA_APP}" \
    --resource-group "${RESOURCE_GROUP}" \
    --revision "${LATEST_REVISION}" \
    --output none

  success "Revision '${LATEST_REVISION}' restarted."
  ;;

# ── Show cost estimate ────────────────────────────────────────────────────────
cost)
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "  Cost Estimate — Azure Container Apps (Canada Central)"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  echo "  Your config: ${ACA_CPU} vCPU + ${ACA_MEMORY} RAM"
  echo ""
  echo "  Rate: (${ACA_CPU} × \$0.000024) + (8 × \$0.000003) = \$0.00012/sec active"
  echo ""
  printf "  %-30s %s\n" "Scenario" "Monthly Cost (USD)"
  printf "  %-30s %s\n" "──────────────────────────────" "──────────────────"
  printf "  %-30s %s\n" "1 hr/day active (demo)"       "~\$13/month"
  printf "  %-30s %s\n" "4 hrs/day (moderate use)"     "~\$52/month"
  printf "  %-30s %s\n" "Always-warm (min-replicas=1)"  "~\$311/month"
  printf "  %-30s %s\n" "ACR Basic (always)"            "~\$5/month"
  printf "  %-30s %s\n" "Blob Storage 9GB (always)"     "~\$1.62/month"
  echo ""
  echo "  Recommended for portfolio/demo: scale-to-zero (~\$20-25/total)"
  echo "  Tip: bash 06-ops.sh scale-zero  ← saves money"
  echo "════════════════════════════════════════════════════════════"
  ;;

# ── Teardown: delete everything ───────────────────────────────────────────────
teardown)
  echo ""
  warn "⚠️  DANGER: This permanently deletes EVERYTHING in resource group '${RESOURCE_GROUP}':"
  echo "    - Azure Container App"
  echo "    - Azure Container Registry (all images)"
  echo "    - Azure Blob Storage (model file)"
  echo "    - ACA Environment"
  echo ""
  read -r -p "  Type the resource group name to confirm deletion: " CONFIRM_NAME
  if [[ "${CONFIRM_NAME}" != "${RESOURCE_GROUP}" ]]; then
    info "Name mismatch. Deletion cancelled."
    exit 0
  fi

  warn "Deleting resource group '${RESOURCE_GROUP}' — this takes 2-3 minutes..."
  az group delete \
    --name "${RESOURCE_GROUP}" \
    --yes \
    --no-wait

  success "Deletion initiated. Resources will be removed in a few minutes."
  warn "Your local model and data files are NOT affected — they are safe on your PC."
  ;;

# ── Help ──────────────────────────────────────────────────────────────────────
help|*)
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "  06-ops.sh — Azure Operations Cheatsheet"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  echo "  Usage: bash 06-ops.sh <command>"
  echo ""
  printf "  %-20s %s\n" "Command" "Description"
  printf "  %-20s %s\n" "────────────────────" "──────────────────────────────────────"
  printf "  %-20s %s\n" "logs"       "Stream live container logs (Ctrl+C to stop)"
  printf "  %-20s %s\n" "status"     "Show app status, URL, and scaling config"
  printf "  %-20s %s\n" "revisions"  "List all deployment revision history"
  printf "  %-20s %s\n" "rollback"   "Roll back to a previous revision"
  printf "  %-20s %s\n" "scale-warm" "Set min-replicas=1 (always-on, no cold start)"
  printf "  %-20s %s\n" "scale-zero" "Set min-replicas=0 (save money, cold starts)"
  printf "  %-20s %s\n" "set-env"    "Update env var: bash 06-ops.sh set-env KEY VAL"
  printf "  %-20s %s\n" "restart"    "Restart the current running revision"
  printf "  %-20s %s\n" "cost"       "Show cost estimate for your configuration"
  printf "  %-20s %s\n" "teardown"   "⚠️  Delete ALL Azure resources (irreversible)"
  echo ""
  echo "════════════════════════════════════════════════════════════"
  ;;

esac
