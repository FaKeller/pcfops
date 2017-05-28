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


# create a pipeline for each product containing all stages
L_PRODUCTS=$(echo ${PRODUCTS} | tr "," "\n")
L_STAGES=$(echo ${STAGES} | tr "," "\n")

for product in L_PRODUCTS; do
    PIPELINE_NAME="upgrade-${product}"
    PIPELINE_PATH="generated_pipelines/${PIPELINE_NAME}"
    echo "> Generating pipeline for '${product}'"

    # generate staged pipeline for current product
    PIPE=$(spruce merge pcfops/pipelines/upgrade-tile/skeleton.yml credentials/${CREDENTIALS_PATH_PREFIX}/common-credentials.yml)
    for stage in L_STAGES; do
        # 1. get base template for single stage
        PIPE=$(echo ${PIPE} | spruce --skip-eval merge - pcfops/pipelines/upgrade-tile/stage-template.yml)

        # 2. merge pcfops product config
        PRODUCT_CONFIG="pcfops/products/${product}.yml"
        if [ -f "$PRODUCT_CONFIG" ]; then
            echo "Merging: pcfops support for ${product}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${PRODUCT_CONFIG})
        else
            echo "No pcfops support for ${product} found"
        fi

        # 3. merge user global stage config
        USER_COMMON_CONFIG="config/${CONFIG_PATH_PREFIX}/common-${stage}.yml"
        if [ -f "$USER_COMMON_CONFIG" ]; then
            echo "Merging: user common stage config from: ${USER_COMMON_CONFIG}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${USER_COMMON_CONFIG})
        fi

        # 4. merge user product common config
        USER_PRODUCT_CONFIG="config/${CONFIG_PATH_PREFIX}/${product}.yml"
        if [ -f "$USER_PRODUCT_CONFIG" ]; then
            echo "Merging: user '${product}' config from: ${USER_PRODUCT_CONFIG}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${USER_PRODUCT_CONFIG})
        fi

        # 5. merge user product stage config
        USER_PRODUCT_STAGE_CONFIG="config/${CONFIG_PATH_PREFIX}/${product}-${stage}.yml"
        if [ -f "$USER_PRODUCT_STAGE_CONFIG" ]; then
            echo "Merging: user '${product}':'${stage}' config from: ${USER_PRODUCT_STAGE_CONFIG}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${USER_PRODUCT_STAGE_CONFIG})
        fi

        # 6. merge user common credentials for stage
        USER_COMMON_CRED="credentials/${CREDENTIALS_PATH_PREFIX}/common-${stage}.yml"
        if [ -f "$USER_COMMON_CRED" ]; then
            echo "Merging: user common credentials from: ${USER_COMMON_CRED}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${USER_COMMON_CRED})
        fi

        # 7. merge user product credentials for stage
        USER_PRODUCT_CRED="credentials/${CREDENTIALS_PATH_PREFIX}/${product}-${stage}.yml"
        if [ -f "$USER_PRODUCT_CRED" ]; then
            echo "Merging: user '${product}' credentials from: ${USER_PRODUCT_CRED}"
            PIPE=$(echo ${PIPE} | spruce --skip-eval merge - ${USER_PRODUCT_CRED})
        fi

        # 8. clean stage meta
        PIPE=$(echo ${PIPE} | spruce merge --prune meta.stage -)
    done


    # update pipeline
    rm ${PIPELINE_PATH}
    echo ${PIPE} >> ${PIPELINE_PATH}

    echo "About to set-pipeline ${PIPELINE_NAME}"
    ./fly --target self set-pipeline \
      --non-interactive \
      --pipeline ${PIPELINE_NAME} \
      --config ${PIPELINE_PATH}
    echo "Finished set-pipeline for ${PIPELINE_NAME}"
done