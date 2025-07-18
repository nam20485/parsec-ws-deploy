#!/bin/sh

set -e

sudo apt update && 
    sudo apt install -y -qq --no-install-recommends \
                                            google-cloud-sdk \
                                            terraform

                                            

# if [ -z "$1" ]; then
#     echo "Usage: $0 <project_id>"
#     exit 1
# fi

# export GOOGLE_CLOUD_PROJECT=$1
# export TF_VAR_gcp_project=$1

# echo "export GOOGLE_CLOUD_PROJECT=$1"
# echo "export TF_VAR_gcp_project=$1"

# gcloud auth application-default login

# echo "gcloud auth application-default login"

# terraform init