#!/usr/bin/env bash

# fetch fly CLI
curl \
  --silent \
  --insecure \
  --output fly \
  "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

# fly login
./fly --target self login \
  --insecure \
  --concourse-url "${ATC_EXTERNAL_URL}" \
  --username "${ATC_BASIC_AUTH_USERNAME}" \
  --password "${ATC_BASIC_AUTH_PASSWORD}" \
  --team-name "${ATC_TEAM_NAME}"


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# create a pipeline for each product containing all stages
L_PRODUCTS=$(echo ${PRODUCTS} | tr "," "\n")
L_STAGES=$(echo ${STAGES} | tr "," "\n")

for product in L_PRODUCTS; do
    PIPELINE_NAME="upgrade-${product}"
    PIPELINE_PATH="generated_pipelines/${PIPELINE_NAME}"
    echo "> Generating pipeline for '${product}'"

    source $SCRIPT_DIR/generate-pipeline.sh

    echo "About to set-pipeline ${PIPELINE_NAME}"
    ./fly --target self set-pipeline \
      --non-interactive \
      --pipeline ${PIPELINE_NAME} \
      --config ${PIPELINE_PATH}
    echo "Finished set-pipeline for ${PIPELINE_NAME}"
done