## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_identity_compartment" "askme_compartment" {
    # Create 1 compartment if no compartment_ocid is provided
    count = local.compartment_ocid != null ? 0 : 1
    compartment_id = local.parent_compartment_ocid
    description = "AskME compartment"
    name = local.common_identifier
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
    # Use compartment_ocid if provided, otherwise use id of the newly created compartment
    id = local.compartment_ocid != null ? local.compartment_ocid : oci_identity_compartment.askme_compartment[0].id
    provider = oci.home
    depends_on = [time_sleep.compartment_propagation_wait]
}

resource "time_static" "compartment_update" {
    triggers = {
        # Save the time for each switch of compartment
        compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    }
}

locals {
    # This "unique" identifier is important for root-level and shared resources (policy, dynamic group and vault secrets)
    # as the same common identifier can exist in different subcompartments but not for root-level and shared resources.
    common_identifier_unique = "${local.common_identifier}-${substr(data.oci_identity_compartment.get_askme_compartment.id, -8, -1)}-${time_static.compartment_update.unix}"
}

data "oci_identity_availability_domains" "ads" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
}