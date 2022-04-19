#!/usr/bin/env bash
#
# ./execute_step_functions_state_machines.sh <state_machine_name> <param_yml_path>...

set -euox pipefail

echo "ARGV:   ${*}"

STATE_MACHINE_NAME="${1}" && shift 1
AWS_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')"
AWS_REGION="$(aws configure get region)"

for p in "${@}"; do
  ruby -rjson -ryaml -e 'print JSON.pretty_generate(YAML.load(STDIN.read))' < "${p}" \
    | xargs -0 aws stepfunctions start-execution \
      --state-machine-arn \
      "arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:stateMachine:${STATE_MACHINE_NAME}" \
      --input
done
