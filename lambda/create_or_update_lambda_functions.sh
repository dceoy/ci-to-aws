#!/usr/bin/env bash
#
# ./create_or_update_lambda_functions.sh <function_path>...

set -euox pipefail

echo "ARGV:                       ${*}"
echo "LAMBDA_RUNTIME:             ${LAMBDA_RUNTIME}"
echo "LAMBDA_EXECUTION_ROLE_ARN:  ${LAMBDA_EXECUTION_ROLE_ARN}"
echo "LAMBDA_ARCHITECTURE:        ${LAMBDA_ARCHITECTURE}"

FUNCTION_ARNS=$(aws lambda list-functions | jq -r '.Functions[].FunctionArn')

for p in "${@}"; do
  function_name="$(basename "${p%.*}")"
  function_arn=$(echo "${FUNCTION_ARNS}" | grep -e ":${function_name}$" | head -1 || :)
  zip --junk-paths "${function_name}.zip" "${p}"
  if [[ -n "${function_arn}" ]]; then
    aws lambda update-function-code \
      --function-name "${function_arn}" --zip-file "fileb://${function_name}.zip"
  else
    aws lambda create-function \
      --function-name "${function_name}" --zip-file "fileb://${function_name}.zip" \
      --runtime "${LAMBDA_RUNTIME}" --handler "${function_name}.lambda_handler" \
      --role "${LAMBDA_EXECUTION_ROLE_ARN}" --architectures "${LAMBDA_ARCHITECTURE}"
  fi
  rm "${function_name}.zip"
done
