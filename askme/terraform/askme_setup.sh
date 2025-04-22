#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

set -e  # Exit script if any command fails

terraform init
TF_VAR_TENANCY=$OCI_TENANCY TF_VAR_REGION=$OCI_REGION terraform apply -auto-approve
sh askme_output.sh