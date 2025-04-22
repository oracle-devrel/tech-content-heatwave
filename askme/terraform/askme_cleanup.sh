#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

set -e  # Exit script if any command fails

terraform init
TF_VAR_TENANCY=$OCI_TENANCY TF_VAR_REGION=$OCI_REGION TF_VAR_ip_cidr_block_allowed="127.0.0.1/32" TF_VAR_ssh_authorized_key="ssh-cleanup" terraform destroy -auto-approve