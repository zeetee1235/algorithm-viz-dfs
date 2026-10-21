#!/usr/bin/env bash
set -euo pipefail

readonly REGION="${AWS_REGION:-ap-northeast-1}"
readonly SERVICE_NAME="algorithm-viz-dfs"
readonly SERVICE_ARN="arn:aws:apprunner:ap-northeast-1:681498213984:service/algorithm-viz-dfs/016d1f8d13124cf49a9d7bd9370a0837"

usage() {
  printf 'Usage: %s {status|pause|resume|wait|delete} [argument]\n' "$0"
  printf '  wait [STATUS]       Wait for STATUS (default: RUNNING)\n'
  printf '  delete SERVICE_NAME Permanently delete; confirmation is required\n'
}

require_aws() {
  command -v aws >/dev/null 2>&1 || {
    printf 'AWS CLI is required.\n' >&2
    exit 1
  }
  aws sts get-caller-identity >/dev/null
}

status() {
  aws apprunner describe-service \
    --region "$REGION" \
    --service-arn "$SERVICE_ARN" \
    --query 'Service.{Status:Status,URL:ServiceUrl,AutoDeployments:SourceConfiguration.AutoDeploymentsEnabled}' \
    --output table
}

action="${1:-}"
require_aws

case "$action" in
  status)
    status
    ;;
  pause)
    aws apprunner pause-service --region "$REGION" --service-arn "$SERVICE_ARN" >/dev/null
    printf 'Pause requested for %s.\n' "$SERVICE_NAME"
    ;;
  resume)
    aws apprunner resume-service --region "$REGION" --service-arn "$SERVICE_ARN" >/dev/null
    printf 'Resume requested for %s.\n' "$SERVICE_NAME"
    ;;
  wait)
    expected="${2:-RUNNING}"
    while true; do
      current="$(aws apprunner describe-service --region "$REGION" --service-arn "$SERVICE_ARN" --query 'Service.Status' --output text)"
      printf 'Status: %s\n' "$current"
      [[ "$current" == "$expected" ]] && break
      [[ "$current" == *FAILED ]] && exit 1
      sleep 10
    done
    ;;
  delete)
    confirmation="${2:-}"
    if [[ "$confirmation" != "$SERVICE_NAME" ]]; then
      printf 'Deletion cancelled. Re-run with: %s delete %s\n' "$0" "$SERVICE_NAME" >&2
      exit 2
    fi
    aws apprunner delete-service --region "$REGION" --service-arn "$SERVICE_ARN" >/dev/null
    printf 'Permanent deletion requested for %s.\n' "$SERVICE_NAME"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
