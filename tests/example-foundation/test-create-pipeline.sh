#!/usr/bin/env bash


cd ../../
export PCFOPS_LOCATION="."
export CONFIG_LOCATION="example-foundation"
export CREDENTIALS_LOCATION="example-foundation"


export product="mysql"
export stages="dev,prod"
export PIPELINE_NAME="upgrade-${product}"
export PIPELINE_PATH="tests/example-foundation/generated_pipelines/${PIPELINE_NAME}.yml"

export CONFIG_PATH_PREFIX="config"
export CREDENTIALS_PATH_PREFIX="credentials"

source tasks/update-pipeline/generate-pipeline.sh