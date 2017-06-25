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
if [ -z "$stages" ]; then
    echo "Could not generate pipeline: please specify \$stage"
    exit 1
fi
L_STAGES=$(echo ${stages} | tr "," "\n")

# by default, assume resources reside in their respective directories relative to
# the working directory (i.e. the default concourse setup).
if [ -z "$PCFOPS_LOCATION" ]; then
    export PCFOPS_LOCATION="pcfops"
fi
if [ -z "$CONFIG_LOCATION" ]; then
    export CONFIG_LOCATION="pcfops"
fi
if [ -z "$CREDENTIALS_LOCATION" ]; then
    export CREDENTIALS_LOCATION="pcfops"
fi


# 0. start with empty pipeline
PIPE=$(echo "meta:")

# 1. merge upgrade tile skeleton
PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${PCFOPS_LOCATION}/pipelines/upgrade-tile/skeleton.yml)

PREVIOUS_JOB="fetch-resources"

for stage in $L_STAGES; do
    echo "STAGE: ${stage}, PREVIOUS: ${PREVIOUS_JOB}"
    # 2. get base template for single stage
    PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${PCFOPS_LOCATION}/pipelines/upgrade-tile/stage-template.yml)

    # 3. set stage and previous job name
    TMP_FILE=$(mktemp -p ./)
    cat <<EOF > ${TMP_FILE}
meta:
  stage:
    name: ${stage}
    job-previous: ${PREVIOUS_JOB}
EOF
    PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${TMP_FILE})
    rm ${TMP_FILE}
    PREVIOUS_JOB="upgrade-tile-"$stage

    # 4. merge pcfops product config
    PRODUCT_CONFIG="${PCFOPS_LOCATION}/products/${product}.yml"
    if [ -f "$PRODUCT_CONFIG" ]; then
        echo "Merging: pcfops support for ${product}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${PRODUCT_CONFIG})
    else
        echo "No pcfops support for ${product} found"
    fi

    # 5. merge common config
    COMMON_CONFIG="${CONFIG_LOCATION}/${CONFIG_PATH_PREFIX}/common.yml"
    if [ -f "$COMMON_CONFIG" ]; then
        echo "Merging: common config ${COMMON_CONFIG}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${COMMON_CONFIG})
    fi

    # 6. merge user global stage config
    USER_COMMON_CONFIG="${CONFIG_LOCATION}/${CONFIG_PATH_PREFIX}/common-${stage}.yml"
    if [ -f "$USER_COMMON_CONFIG" ]; then
        echo "Merging: user common stage config from: ${USER_COMMON_CONFIG}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${USER_COMMON_CONFIG})
    fi

    # 7. merge user product common config
    USER_PRODUCT_CONFIG="${CONFIG_LOCATION}/${CONFIG_PATH_PREFIX}/${product}.yml"
    if [ -f "$USER_PRODUCT_CONFIG" ]; then
        echo "Merging: user '${product}' config from: ${USER_PRODUCT_CONFIG}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${USER_PRODUCT_CONFIG})
    fi

    # 8. merge user product stage config
    USER_PRODUCT_STAGE_CONFIG="${CONFIG_LOCATION}/${CONFIG_PATH_PREFIX}/${product}-${stage}.yml"
    if [ -f "$USER_PRODUCT_STAGE_CONFIG" ]; then
        echo "Merging: user '${product}':'${stage}' config from: ${USER_PRODUCT_STAGE_CONFIG}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${USER_PRODUCT_STAGE_CONFIG})
    fi

    # 9. merge user common credentials for stage
    USER_COMMON_CRED="${CREDENTIALS_LOCATION}/${CREDENTIALS_PATH_PREFIX}/common-${stage}.yml"
    if [ -f "$USER_COMMON_CRED" ]; then
        echo "Merging: user common credentials from: ${USER_COMMON_CRED}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${USER_COMMON_CRED})
    fi

    # 10. merge user product credentials for stage
    USER_PRODUCT_CRED="${CREDENTIALS_LOCATION}/${CREDENTIALS_PATH_PREFIX}/${product}-${stage}.yml"
    if [ -f "$USER_PRODUCT_CRED" ]; then
        echo "Merging: user '${product}' credentials from: ${USER_PRODUCT_CRED}"
        PIPE=$(echo "${PIPE}" | spruce merge --skip-eval - ${USER_PRODUCT_CRED})
    fi

    # 11. clean stage meta
    PIPE=$(echo "${PIPE}" | spruce merge --prune meta.stage -)
done


# update pipeline
if [ -f "$PIPELINE_PATH" ]; then
    echo "Removing existing pipeline ${PIPELINE_PATH}"
    rm ${PIPELINE_PATH}
fi
echo "Writing pipeline to ${PIPELINE_PATH}"
echo "${PIPE}" >> ${PIPELINE_PATH}