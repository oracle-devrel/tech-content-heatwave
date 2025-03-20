## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_kms_vault" "askme_vault" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    display_name = "${local.compartment_name}-vault"
    vault_type = "DEFAULT"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_kms_key" "askme_vault_key" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    management_endpoint = oci_kms_vault.askme_vault.management_endpoint
    display_name = "${local.compartment_name}-vault-key"
    key_shape {
        algorithm = "AES"
        length = 32
    }
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_vault_secret" "askme_mysql_host_ip_secret" {
	compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vault_id = oci_kms_vault.askme_vault.id
	key_id = oci_kms_key.askme_vault_key.id
	secret_name = local.mysql_host_ip_vault_secret_name
	secret_content {
        content = base64encode(oci_mysql_mysql_db_system.askme_dbsystem.ip_address)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_vault_secret" "askme_mysql_username_secret" {
	compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vault_id = oci_kms_vault.askme_vault.id
	key_id = oci_kms_key.askme_vault_key.id
	secret_name = local.mysql_username_vault_secret_name
	secret_content {
        content = base64encode(local.mysql_username)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_vault_secret" "askme_mysql_password_secret" {
	compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vault_id = oci_kms_vault.askme_vault.id
	key_id = oci_kms_key.askme_vault_key.id
	secret_name = local.mysql_password_vault_secret_name
	secret_content {
        content = base64encode(local.mysql_password)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}