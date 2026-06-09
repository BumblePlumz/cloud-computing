#!/bin/bash
# restore.sh — PRA (Plan de Reprise d'Activité) automatisé
# Usage : ./restore.sh [scenario]
#   s3-restore | infra-rebuild | network-lockdown | kms-rotation
# Note : utilise `awslocal` en dev (LocalStack) ou `aws` en prod.

set -euo pipefail
CLI="${CLI:-awslocal}"
SCENARIO="${1:-}"
log() { echo "[PRA $(date +%H:%M:%S)] $1"; }

case "$SCENARIO" in
  s3-restore)
    log "DEBUT restauration S3"
    $CLI s3api list-object-versions --bucket app-files-securises
    log "Identifiez le VersionId a restaurer, puis :"
    log "$CLI s3api copy-object --copy-source BUCKET/KEY?versionId=ID ..."
    ;;
  infra-rebuild)
    log "DEBUT reconstruction infrastructure"
    terraform destroy -auto-approve
    terraform apply -auto-approve
    log "Infrastructure reconstruite"
    ;;
  network-lockdown)
    log "LOCKDOWN reseau - blocage d'urgence"
    $CLI ec2 revoke-security-group-ingress \
      --group-name app-securisee-sg --protocol tcp \
      --port 0-65535 --cidr 0.0.0.0/0 || true
    log "Reseau isole"
    ;;
  kms-rotation)
    log "Rotation cle KMS suite compromission"
    $CLI kms disable-key --key-id alias/app-securisee || true
    terraform apply -target=aws_kms_key.main -auto-approve
    log "Nouvelle cle deployee - re-chiffrement necessaire"
    ;;
  *)
    echo "Usage: $0 [s3-restore|infra-rebuild|network-lockdown|kms-rotation]"
    exit 1
    ;;
esac
