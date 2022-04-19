#!/usr/bin/env bash
#
# ./create_or_update_step_functions_state_machines.sh <asl_yml_path>...

set -euox pipefail

echo "ARGV:                               ${*}"
echo "STEP_FUNCTIONS_EXECUTION_ROLE_ARN:  ${STEP_FUNCTIONS_EXECUTION_ROLE_ARN}"

STATE_MACHINE_ARNS=$(aws stepfunctions list-state-machines | jq -r '.stateMachines[].stateMachineArn')

for p in "${@}"; do
  state_machine_name="$(basename "${p%.asl.yml}")"
  state_machine_arn=$(echo "${STATE_MACHINE_ARNS}" | grep -e ":${state_machine_name}$" | head -1)
  ruby -rjson -ryaml -e 'print JSON.pretty_generate(YAML.load(STDIN.read))' \
    < "${p}" | tee "${state_machine_name}.asl.json"
  if [[ -n "${state_machine_arn}" ]]; then
    aws stepfunctions update-state-machine \
      --state-machine-arn "${state_machine_arn}" \
      --definition "file://${state_machine_name}.asl.json"
  else
    aws stepfunctions create-state-machine \
      --name "${state_machine_name}" \
      --role-arn "${STEP_FUNCTIONS_EXECUTION_ROLE_ARN}" \
      --definition "file://${state_machine_name}.asl.json"
  fi
  rm "${state_machine_name}.asl.json"
done
