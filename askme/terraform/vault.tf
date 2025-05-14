## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_kms_vault" "askme_vault" {
    # Create 1 vault if no vault_ocid is provided
    count = local.vault_ocid != null ? 0 : 1
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    display_name = "${local.common_identifier}-vault"
    vault_type = "DEFAULT"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

# Required to mitigate issue in https://github.com/oracle/terraform-provider-oci/issues/1955
resource "time_sleep" "vault_wait" {
    depends_on = [oci_kms_vault.askme_vault]
    create_duration = "1m"
}

data "oci_kms_vault" "get_askme_vault" {
    # Use vault_ocid if provided, otherwise use id of the newly created vault
    vault_id = local.vault_ocid != null ? local.vault_ocid : oci_kms_vault.askme_vault[0].id
    depends_on = [time_sleep.vault_wait]
}

resource "oci_kms_key" "askme_vault_key" {
    # Create 1 vault key if no vault_key_ocid is provided
    count = local.vault_key_ocid != null ? 0 : 1
    compartment_id = data.oci_kms_vault.get_askme_vault.compartment_id
    management_endpoint = data.oci_kms_vault.get_askme_vault.management_endpoint
    display_name = "${local.common_identifier}-vault-key"
    key_shape {
        algorithm = "AES"
        length = 32
    }
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

# Required to mitigate issue in https://github.com/oracle/terraform-provider-oci/issues/1955
resource "time_sleep" "vault_key_wait" {
    depends_on = [oci_kms_key.askme_vault_key]
    create_duration = "1m"
}

data "oci_kms_key" "get_askme_vault_key" {
    # Use vault_key_ocid if provided, otherwise use id of the newly created vault key
    key_id = local.vault_key_ocid != null ? local.vault_key_ocid : oci_kms_key.askme_vault_key[0].id
    management_endpoint = data.oci_kms_vault.get_askme_vault.management_endpoint
    depends_on = [time_sleep.vault_key_wait]
}

locals {
    # Vault secret keys names
    mysql_username_vault_secret_name = "${local.common_identifier_unique}-mysql_username"
    mysql_password_vault_secret_name = "${local.common_identifier_unique}-mysql_password"
    mysql_host_ip_vault_secret_name = "${local.common_identifier_unique}-mysql_host_ip"
}

resource "oci_vault_secret" "askme_mysql_username_secret" {
	compartment_id = data.oci_kms_vault.get_askme_vault.compartment_id
    vault_id = data.oci_kms_vault.get_askme_vault.id
	key_id = data.oci_kms_key.get_askme_vault_key.id
	secret_name = local.mysql_username_vault_secret_name
	secret_content {
        content = base64encode(local.mysql_username)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_vault_secret" "askme_mysql_password_secret" {
	compartment_id = data.oci_kms_vault.get_askme_vault.compartment_id
    vault_id = data.oci_kms_vault.get_askme_vault.id
	key_id = data.oci_kms_key.get_askme_vault_key.id
	secret_name = local.mysql_password_vault_secret_name
	secret_content {
        content = base64encode(local.mysql_password)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_vault_secret" "askme_mysql_host_ip_secret" {
	compartment_id = data.oci_kms_vault.get_askme_vault.compartment_id
    vault_id = data.oci_kms_vault.get_askme_vault.id
	key_id = data.oci_kms_key.get_askme_vault_key.id
	secret_name = local.mysql_host_ip_vault_secret_name
	secret_content {
        content = base64encode(oci_mysql_mysql_db_system.askme_dbsystem.ip_address)
        content_type = "BASE64"
	}
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}