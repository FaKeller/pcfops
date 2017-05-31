#!/bin/bash -e

# check required variables
if [ -z "$PIPELINE_NAME" ]; then
    echo "Could not generate pipeline: please specify \$PIPELINE_NAME"
    exit 1
fi
if [ -z "$PIPELINE_PATH" ]; then
    echo "Could not generate pipeline: please specify \$PIPELINE_PATH"
    exit 1
fi
if [ -z "$product" ]; then
    echo "Could not generate pipeline: please specify \$product"
    exit 1
fi
if [ -z "$stage" ]; then
    echo "Could not generate pipeline: please specify \$stage"
    exit 1
fi

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