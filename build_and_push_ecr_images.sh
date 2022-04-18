#!/usr/bin/env bash
#
# ./build_and_push_ecr_images.sh <dockerfile_path>...

set -euox pipefail

echo "ARGV:           ${*}"
echo "ECR_REGISTRY:   ${ECR_REGISTRY}"
echo "IMAGE_TAG:      ${IMAGE_TAG}"

for p in "${@}"; do
  dockerfile_dir="$(dirname "${p}")"
  if [[ "${dockerfile_dir}" = '.' ]]; then
    image_name="$(basename "${PWD}")"
  else
    image_name="$(basename "${dockerfile_dir}")"
  fi
  aws ecr describe-repositories --repository-names "${image_name}" \
    || aws ecr create-repository --repository-name "${image_name}"
  docker image build \
    --tag "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" --file "${p}" "${dockerfile_dir}" \
    && docker image tag \
      "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" "${ECR_REGISTRY}/${image_name}:latest" \
    && docker image push "${ECR_REGISTRY}/${image_name}:${IMAGE_TAG}" \
    && docker image push "${ECR_REGISTRY}/${image_name}:latest"
done
