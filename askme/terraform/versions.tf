## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
  }
  required_version = ">= 1.0.0"
}