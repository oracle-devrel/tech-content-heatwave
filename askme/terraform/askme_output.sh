#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

set -e  # Exit script if any command fails

terraform init >/dev/null
public_ip=`terraform output -json askme_instance_public_ip 2>/dev/null || echo ""`
public_ip=`echo $public_ip | tr -d '"'`
if [ -z "$public_ip" ]
then
    echo "No terraform resource detected.."
    echo "Please run the deployment instructions to create the resources."
else
    echo "================================================"
    echo "Open a terminal in your local computer, and run:"
    echo "  ssh -L 8501:localhost:8501 opc@$public_ip"
    echo "Then in your web browser, open the URL:"
    echo "  127.0.0.1:8501"
    echo "================================================"
fi