## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_mysql_mysql_db_system" "askme_dbsystem" {
    display_name = "${local.common_identifier}-dbsystem"
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    shape_name = local.mysql_shape
    subnet_id = data.oci_core_subnet.get_askme_private_vcn_subnet.id
    admin_username = local.mysql_username
    admin_password = local.mysql_password
    mysql_version = local.mysql_version
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_mysql_heat_wave_cluster" "askme_heatwave_cluster" {
    db_system_id = oci_mysql_mysql_db_system.askme_dbsystem.id
    cluster_size = local.heatwave_nodes
    is_lakehouse_enabled = true
    shape_name = local.heatwave_shape
}