## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

data "oci_core_images" "ol9_latest" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    operating_system = "Oracle Linux"
    operating_system_version = "9"
    shape = local.compute_shape
}

resource "oci_core_instance" "askme_instance" {
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    shape = local.compute_shape
    shape_config {
        ocpus = "1"
        memory_in_gbs = local.compute_memory
    }
    source_details {
        source_id = data.oci_core_images.ol9_latest.images.0.id
        source_type = "image"
    }
    display_name = "${local.compartment_name}-instance"
    create_vnic_details {
        assign_public_ip = true
        subnet_id = oci_core_subnet.askme_vcn_public_subnet.id
    }
    metadata = {
        ssh_authorized_keys = local.ssh_key
        user_data = base64encode(templatefile("instance_init.tpl",
                                              { OCI_COMPARTMENT_ID = data.oci_identity_compartment.get_askme_compartment.id,
                                                OCI_REGION = local.region,
                                                REPO_URL = local.demos_repo_url,
                                                REPO_SUBFOLDER = local.demos_repo_subfolder }))
    }
    preserve_boot_volume = false
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
    depends_on = [
        oci_vault_secret.askme_mysql_host_ip_secret,
        oci_vault_secret.askme_mysql_username_secret,
        oci_vault_secret.askme_mysql_password_secret,
        oci_mysql_heat_wave_cluster.askme_heatwave_cluster
    ]
}

# Sleep time to make sure the instance user_data was executed
resource "time_sleep" "user_agent_wait" {
    depends_on = [oci_core_instance.askme_instance]
    create_duration = "5m"
}