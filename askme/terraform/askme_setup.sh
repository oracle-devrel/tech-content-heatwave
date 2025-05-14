#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

set -e  # Exit script if any command fails

terraform init
ip_cidr_defined=`echo "var.public_vcn_subnet_ocid != null || var.private_vcn_subnet_ocid != null" | terraform console -var-file terraform.tfvars 2>/dev/null`
if [[ "$ip_cidr_defined" == *"true" ]]
then
    # If both subnets are defined, IP CIDR block isn't required => default argument value
    # If one subnet is defined, terraform will raise an error
    export TF_VAR_ip_cidr_block_allowed="0.0.0.0/0"
fi
TF_VAR_TENANCY=$OCI_TENANCY TF_VAR_REGION=$OCI_REGION terraform apply -auto-approve -var-file="terraform.tfvars" -replace="oci_core_instance.askme_instance" -replace="time_sleep.user_agent_wait"
sh askme_output.sh