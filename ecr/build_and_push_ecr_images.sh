#!/usr/bin/env bash
#
# ./build_and_push_ecr_images.sh <dockerfile_path>...

set -euox pipefail

echo "ARGV:           ${*}"
echo "IMAGE_TAG:      ${IMAGE_TAG}"

AWS_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

for p in "${@}"; do
  dockerfile_dir_path="$(dirname "${p}")"
  if [[ "${dockerfile_dir_path}" = '.' ]]; then
    image_name="$(basename "${PWD}")"
  else
    image_name="$(basename "${dockerfile_dir_path}")"
  fi
  aws ecr describe-repositories --repository-names "${image_name}" \
    || aws ecr create-repository --repository-name "${image_name}"
  docker image build \
    --tag "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" --file "${p}" "${dockerfile_dir_path}" \
    && docker image tag \
      "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" "${ECR_REGISTRY}/${image_name}:latest" \
    && docker image push "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" \
    && docker image push "${ECR_REGISTRY}/${image_name}:latest"
done
