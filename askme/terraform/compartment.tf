## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_identity_compartment" "askme_compartment" {
    compartment_id = local.tenancy
    description = "AskME compartment"
    name = local.compartment_name
    enable_delete = true
    provider = oci.home
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

# Sleep time to make sure the compartment creation is propagated in regions
resource "time_sleep" "compartment_propagation_wait" {
    depends_on = [oci_identity_compartment.askme_compartment]
    create_duration = "2m"
}

data "oci_identity_compartment" "get_askme_compartment" {
    id = oci_identity_compartment.askme_compartment.id
    provider = oci.home
    depends_on = [time_sleep.compartment_propagation_wait]
}

data "oci_identity_availability_domains" "ads" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
}