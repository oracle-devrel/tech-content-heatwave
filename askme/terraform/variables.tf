## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

# Default values of input variables
locals {
    default_common_identifier = "heatwave-genai-askme"
    default_ip_cidr_block_allowed = "0.0.0.0/0"
}

variable "REGION" {
    type = string
    description = "Identifier of the current region"
}

variable "TENANCY" {
    type = string
}

variable "common_identifier" {
    type = string
    nullable = false
    description = "Prefix of the new resources to create to setup AskME (default: 'heatwave-genai-askme')"

    validation {
        condition = length(var.common_identifier) == 0 || (length(var.common_identifier) >= 4 && length(var.common_identifier) <= 20)
        error_message = "The common identifier length must be between 4 and 20."
    }
}

variable "ip_cidr_block_allowed" {
    type = string
    nullable = false
    description = "AskME compute instance reachability: Allowed IPv4 CIDR block (default: '0.0.0.0/0'). Set of IPv4 addresses (CIDR notation) allowed to connect to the compute instance. For more information, see https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm#:~:text=CIDR%20NOTATION"

    validation {
        condition = length(var.ip_cidr_block_allowed) == 0 || can(cidrhost(var.ip_cidr_block_allowed, 0))
        error_message = "Invalid IPv4 CIDR block notation. For more information, see https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm#:~:text=CIDR%20NOTATION"
    }
}

variable "ssh_authorized_key" {
    type = string
    nullable = false
    description = "AskME compute instance connection: SSH authorized key. Content of the SSH public key file (OpenSSH format) located in your local machine. For more information about Key Pair management and generation, see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingkeypairs.htm"

    validation {
        condition = length(var.ssh_authorized_key) > 4 && substr(var.ssh_authorized_key, 0, 4) == "ssh-"
        error_message = "The SSH public key value must follow the OpenSSH format, starting with \"ssh-\". For more information, see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingkeypairs.htm"
    }
}

variable "parent_compartment_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.parent_compartment_ocid == null ? true : (length(var.parent_compartment_ocid) > 18 && substr(var.parent_compartment_ocid, 0, 18) == "ocid1.compartment.") || (length(var.parent_compartment_ocid) > 14 && substr(var.parent_compartment_ocid, 0, 14) == "ocid1.tenancy.")
        error_message = "Wrong format for the parent compartment OCID."
    }
}

variable "compartment_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.compartment_ocid == null ? true : (length(var.compartment_ocid) > 18 && substr(var.compartment_ocid, 0, 18) == "ocid1.compartment.")
        error_message = "Wrong format for the compartment OCID."
    }
}

variable "vault_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.vault_ocid == null ? true : (length(var.vault_ocid) > 12 && substr(var.vault_ocid, 0, 12) == "ocid1.vault.")
        error_message = "Wrong format for the vault OCID."
    }
}

variable "vault_key_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.vault_key_ocid == null ? true : (length(var.vault_key_ocid) > 10 && substr(var.vault_key_ocid, 0, 10) == "ocid1.key.")
        error_message = "Wrong format for the vault key OCID."
    }
}

variable "public_vcn_subnet_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.public_vcn_subnet_ocid == null ? true : (length(var.public_vcn_subnet_ocid) > 13 && substr(var.public_vcn_subnet_ocid, 0, 13) == "ocid1.subnet.")
        error_message = "Wrong format for the public subnet OCID."
    }
}

variable "private_vcn_subnet_ocid" {
    type = string
    nullable = true

    validation {
        # Short-circuit doesn't work with ||, need to use ternary condition to prevent "argument must not be null" errors.
        condition = var.private_vcn_subnet_ocid == null ? true : (length(var.private_vcn_subnet_ocid) > 13 && substr(var.private_vcn_subnet_ocid, 0, 13) == "ocid1.subnet.")
        error_message = "Wrong format for the private subnet OCID."
    }
}

variable "dynamic_group_and_policy_created" {
    type = bool
    nullable = false
}

variable "mysql_shape" {
    type = string
    nullable = false
}

variable "mysql_version" {
    type = string
    nullable = false
}

variable "heatwave_shape" {
    type = string
    nullable = false
}

variable "heatwave_nodes" {
    type = number
    nullable = false
	validation {
		condition = tonumber(var.heatwave_nodes) == floor(var.heatwave_nodes) && var.heatwave_nodes > 0
		error_message = "heatwave_nodes should be a natural number."
	}
}

variable "compute_shape" {
    type = string
    nullable = false
}

variable "compute_memory" {
    type = number
    nullable = false
	validation {
		condition = tonumber(var.compute_memory) == floor(var.compute_memory) && var.compute_memory > 0
		error_message = "compute_memory should be a natural number."
	}
}

locals {
    # Input parameters
    tenancy = var.TENANCY
    region = var.REGION
    common_identifier = length(var.common_identifier) == 0 ? local.default_common_identifier : var.common_identifier
    ip_cidr_block_allowed = length(var.ip_cidr_block_allowed) == 0 ? local.default_ip_cidr_block_allowed : var.ip_cidr_block_allowed
    ssh_key = var.ssh_authorized_key

    # OCI regions supporting Generative AI (see https://docs.oracle.com/en-us/iaas/Content/generative-ai/overview.htm#regions)
    is_genai_region = contains(["sa-saopaulo-1", "eu-frankfurt-1", "ap-osaka-1", "uk-london-1", "us-chicago-1"], local.region)

    # Resource tags
    resource_tag_key = "demo"
    resource_tag_value = local.common_identifier

    # Flexible resources
    parent_compartment_ocid = var.parent_compartment_ocid == null ? local.tenancy : var.parent_compartment_ocid
    compartment_ocid = var.compartment_ocid
    vault_ocid = var.vault_ocid
    vault_key_ocid = var.vault_key_ocid
    public_vcn_subnet_ocid = var.public_vcn_subnet_ocid
    private_vcn_subnet_ocid = var.private_vcn_subnet_ocid
    dynamic_group_and_policy_created = var.dynamic_group_and_policy_created

    # Compute and DBSystem parameters
    mysql_shape = var.mysql_shape
    mysql_version = var.mysql_version
    heatwave_shape = var.heatwave_shape
    heatwave_nodes = var.heatwave_nodes
    compute_shape = var.compute_shape
    compute_memory = var.compute_memory
}

#########################
# Assertion section: using ternary operators to throw errors when inconsistent state is detected
#########################

data "oci_identity_compartment" "get_askme_compartment_for_assertion" {
    count = local.compartment_ocid == null ? 0 : 1
    id = local.compartment_ocid
    provider = oci.home
}

data "oci_kms_vault" "get_askme_vault_for_assertion" {
    count = local.vault_ocid == null ? 0 : 1
    vault_id = local.vault_ocid
}

data "oci_kms_key" "get_askme_vault_key_for_assertion" {
    count = local.vault_ocid == null || local.vault_key_ocid == null ? 0 : 1
    key_id = local.vault_key_ocid
    management_endpoint = data.oci_kms_vault.get_askme_vault_for_assertion[0].management_endpoint
}

data "oci_core_subnet" "get_askme_public_vcn_subnet_for_assertion" {
    count = local.public_vcn_subnet_ocid == null ? 0 : 1
    subnet_id = local.public_vcn_subnet_ocid
}

data "oci_core_subnet" "get_askme_private_vcn_subnet_for_assertion" {
    count = local.private_vcn_subnet_ocid == null ? 0 : 1
    subnet_id = local.private_vcn_subnet_ocid
}

data "oci_core_internet_gateways" "get_askme_vcn_gateway_for_assertion" {
    count = local.public_vcn_subnet_ocid == null ? 0 : 1
    compartment_id = data.oci_core_subnet.get_askme_public_vcn_subnet_for_assertion[0].compartment_id
    vcn_id = data.oci_core_subnet.get_askme_public_vcn_subnet_for_assertion[0].vcn_id
}

locals {
    #######
    # If vault_key_ocid is provided, then the Vault should exist and the vault key should be associated to the Vault
    assert_vault_key_in_vault_condition = local.vault_key_ocid == null ? true : (local.vault_key_ocid == null ? false : data.oci_kms_key.get_askme_vault_key_for_assertion[0].vault_id == data.oci_kms_vault.get_askme_vault_for_assertion[0].id)
    assert_vault_key_in_vault = local.assert_vault_key_in_vault_condition ? true : tobool("ERROR: vault_key_ocid is not associated to the vault.")

    #######
    # If one public/private subnet is defined, the other private/public subnet needs to be defined too. They need to come from the same VCN and the same compartment. The VCN needs to have at least one internet gateway.
    assert_both_subnets_defined_condition = (local.public_vcn_subnet_ocid == null) == (local.private_vcn_subnet_ocid == null)
    assert_both_subnets_defined = local.assert_both_subnets_defined_condition ? true : tobool("ERROR: both subnets need to be defined.")

    assert_subnets_from_same_vcn_condition = (local.public_vcn_subnet_ocid == null || local.private_vcn_subnet_ocid == null) ? true : data.oci_core_subnet.get_askme_public_vcn_subnet_for_assertion[0].vcn_id == data.oci_core_subnet.get_askme_private_vcn_subnet_for_assertion[0].vcn_id
    assert_subnets_from_same_vcn = local.assert_subnets_from_same_vcn_condition ? true : tobool("ERROR: both subnets need to come from the same VCN.")

    assert_subnets_from_same_compartment_condition = (local.public_vcn_subnet_ocid == null || local.private_vcn_subnet_ocid == null) ? true : data.oci_core_subnet.get_askme_public_vcn_subnet_for_assertion[0].compartment_id == data.oci_core_subnet.get_askme_private_vcn_subnet_for_assertion[0].compartment_id
    assert_subnets_from_same_compartment = local.assert_subnets_from_same_compartment_condition ? true : tobool("ERROR: both subnets need to come from the same compartment.")

    assert_vcn_internet_gateway_condition = local.public_vcn_subnet_ocid == null ? true : length(data.oci_core_internet_gateways.get_askme_vcn_gateway_for_assertion[0].gateways) > 0
    assert_vcn_internet_gateway = local.assert_vcn_internet_gateway_condition ? true : tobool("ERROR: the VCN associated to the subnets does not have an internet gateway.")
}