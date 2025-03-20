## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

# Constants for setup
locals {
    mysql_shape = "MySQL.8"
    mysql_version = "9.2.2"
    mysql_username = "admin"
    heatwave_shape = "HeatWave.512GB"
    compute_shape = "VM.Standard.E4.Flex"
    compute_memory = "16"
    demos_repo_url = "https://github.com/oracle-devrel/tech-content-heatwave.git"
    demos_repo_subfolder = "askme"
}

# Default values of input variables
locals {
    default_compartment_name = "heatwave-genai-askme"
}

variable "REGION" {
  type = string
  description = "Identifier of the current region. For more information about OCI regions supporting Generative AI, see https://docs.oracle.com/en-us/iaas/Content/generative-ai/overview.htm#regions"

  validation {
      # Can't use a default local value due to terraform limitations
      condition = contains(["sa-saopaulo-1", "eu-frankfurt-1", "ap-osaka-1", "uk-london-1", "us-chicago-1"], var.REGION)
      error_message = "Current OCI region does not support Generative AI, please choose another region and rerun the demo instructions."
  }
}

variable "TENANCY" {
  type = string
}

variable "compartment_name" {
    type = string
    description = "Name of the AskME demo compartment (default: 'heatwave-genai-askme')"

    validation {
        condition = length(var.compartment_name) == 0 || (length(var.compartment_name) >= 4 && length(var.compartment_name) <= 20)
        error_message = "The compartment name length must be between 4 and 20."
    }
}

variable "ip_cidr_block_allowed" {
    type = string
    description = "AskME compute instance reachability: Allowed IPv4 CIDR block. Set of IPv4 addresses (CIDR notation) allowed to connect to the compute instance. For more information, see https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm#:~:text=CIDR%20NOTATION"

    validation {
        condition = can(cidrhost(var.ip_cidr_block_allowed, 0))
        error_message = "Invalid IPv4 CIDR block notation. For more information, see https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm#:~:text=CIDR%20NOTATION"
    }
}

variable "ssh_authorized_key" {
    type = string
    description = "AskME compute instance connection: SSH authorized key. Content of the SSH public key file (OpenSSH format) located in your local machine. For more information about Key Pair management and generation, see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingkeypairs.htm"

    validation {
        condition = length(var.ssh_authorized_key) > 4 && substr(var.ssh_authorized_key, 0, 4) == "ssh-"
        error_message = "The SSH public key value must follow the OpenSSH format, starting with \"ssh-\". For more information, see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingkeypairs.htm"
    }
}

resource "random_password" "mysql_password" {
  length = 32
  min_numeric = 1
  min_special = 1
  min_lower = 1
  min_upper = 1
  override_special = "!#$%&*()-_=+[]{}"
}

locals {
    tenancy = var.TENANCY
    region = var.REGION
    compartment_name = length(var.compartment_name) == 0 ? local.default_compartment_name : var.compartment_name
    ip_cidr_block_allowed = var.ip_cidr_block_allowed
    ssh_key = var.ssh_authorized_key
    mysql_password = random_password.mysql_password.result
    mysql_username_vault_secret_name = "mysql_username"
    mysql_password_vault_secret_name = "mysql_password"
    mysql_host_ip_vault_secret_name = "mysql_host_ip"
    resource_tag_key = "demo"
    resource_tag_value = "askme"
}