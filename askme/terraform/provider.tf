## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

# Need this provider when using Cloud Shell terraform
provider "oci" {
   auth = "InstancePrincipal"
   region = local.region
}

data "oci_identity_region_subscriptions" "this" {
  tenancy_id = local.tenancy
}

provider "oci" {
   auth = "InstancePrincipal"
   region = [for i in data.oci_identity_region_subscriptions.this.region_subscriptions : i.region_name if i.is_home_region == true][0]
   alias = "home"
}