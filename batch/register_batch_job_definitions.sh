#!/usr/bin/env bash
#
# ./register_batch_job_definitions.sh <image_name>...

set -euox pipefail

echo "ARGV:                       ${*}"
echo "ECR_REGISTRY:               ${ECR_REGISTRY}"
echo "IMAGE_TAG:                  ${IMAGE_TAG}"
echo "BATCH_JOB_ROLE_ARN:         ${BATCH_JOB_ROLE_ARN}"
echo "BATCH_EXECUTION_ROLE_ARN:   ${BATCH_EXECUTION_ROLE_ARN}"

TEMPLATE_DIR_PATH="$(realpath "${0}" | xargs dirname)"
for i in "${@}"; do
  for p in 'ec2' 'fargate'; do
    j="${TEMPLATE_DIR_PATH}/${p}.job-definition.j2.json"
    [[ -f "${j}" ]] \
      && jq ".jobDefinitionName=\"${p}-${i}\"" < "${j}" \
        | jq ".containerProperties.image=\"${ECR_REGISTRY}/${i}:${IMAGE_TAG}\"" \
        | jq ".containerProperties.jobRoleArn=\"${BATCH_JOB_ROLE_ARN}\"" \
        | jq ".containerProperties.executionRoleArn=\"${BATCH_EXECUTION_ROLE_ARN}\"" \
        | tee "${i}.${p}.job-definition.json"
    aws batch register-job-definition \
      --cli-input-json "file://${i}.${p}.job-definition.json"
    aws batch describe-job-definitions \
      --job-definition-name "${p}-${i}" \
      | jq '.jobDefinitions[] | select(.status == "ACTIVE").revision' \
      | sed -e '1d' \
      | xargs -t -I{} aws batch deregister-job-definition \
        --job-definition "${p}-${i}:{}"
  done
done
