## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

module "vcn" {
    # Create 1 vcn if no public subnet or no private subnet is provided
    count = local.public_vcn_subnet_ocid != null && local.private_vcn_subnet_ocid != null ? 0 : 1
    source = "oracle-terraform-modules/vcn/oci"
    version = "3.6.0"
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    region = local.region
    vcn_name = "${local.common_identifier}-vcn"
    create_internet_gateway = true
    create_nat_gateway = false
    create_service_gateway = false
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_core_security_list" "askme_public_security_list"{
    # Create 1 public security list if no public subnet is provided
    count = local.public_vcn_subnet_ocid != null ? 0 : 1
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn[0].vcn_id
    display_name = "${local.common_identifier}-security-list-for-public-subnet"
    egress_security_rules {
        stateless = false
        destination = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        protocol = "all"
    }
    ingress_security_rules {
        stateless = false
        source = local.ip_cidr_block_allowed
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
        protocol = "6"
        tcp_options {
            min = 22
            max = 22
        }
    }
    ingress_security_rules {
        stateless = false
        source = local.ip_cidr_block_allowed
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1
        protocol = "1"
        # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
        icmp_options {
            type = 3
            code = 4
        }
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1
        protocol = "1"
        # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
        icmp_options {
            type = 3
        }
    }
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_core_subnet" "askme_vcn_public_subnet"{
    # Create 1 public subnet if no public subnet is provided
    count = local.public_vcn_subnet_ocid != null ? 0 : 1
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn[0].vcn_id
    cidr_block = "10.0.0.0/24"
    route_table_id = module.vcn[0].ig_route_id
    security_list_ids = [oci_core_security_list.askme_public_security_list[0].id]
    display_name = "${local.common_identifier}-public-subnet"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

data "oci_core_subnet" "get_askme_public_vcn_subnet" {
    # Use public_vcn_subnet_ocid if public_vcn_subnet_ocid is provided,
    # otherwise use id of the newly created public subnet
    subnet_id = local.public_vcn_subnet_ocid != null ? local.public_vcn_subnet_ocid : oci_core_subnet.askme_vcn_public_subnet[0].id
}

resource "oci_core_security_list" "askme_private_security_list"{
    # Create 1 private security list if no private subnet is provided
    count = local.private_vcn_subnet_ocid != null ? 0 : 1
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn[0].vcn_id
    display_name = "${local.common_identifier}-security-list-for-private-subnet"
    egress_security_rules {
        stateless = false
        destination = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        protocol = "all"
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
        protocol = "6"
        tcp_options {
            min = 22
            max = 22
        }
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1
        protocol = "1"
        # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
        icmp_options {
            type = 3
            code = 4
        }
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1
        protocol = "1"
        # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
        icmp_options {
            type = 3
        }
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
        protocol = "6"
        tcp_options {
            min = 3306
            max = 3306
        }
    }
    ingress_security_rules {
        stateless = false
        source = "10.0.0.0/16"
        source_type = "CIDR_BLOCK"
        # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
        protocol = "6"
        tcp_options {
            min = 33060
            max = 33060
        }
    }
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_core_subnet" "askme_vcn_private_subnet"{
    # Create 1 private subnet if no private subnet is provided
    count = local.private_vcn_subnet_ocid != null ? 0 : 1
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn[0].vcn_id
    cidr_block = "10.0.1.0/24"
    route_table_id = module.vcn[0].nat_route_id
    security_list_ids = [oci_core_security_list.askme_private_security_list[0].id]
    display_name = "${local.common_identifier}-private-subnet"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

data "oci_core_subnet" "get_askme_private_vcn_subnet" {
    # Use private_vcn_subnet_ocid if private_vcn_subnet_ocid is provided,
    # otherwise use id of the newly created private subnet
    subnet_id = local.private_vcn_subnet_ocid != null ? local.private_vcn_subnet_ocid : oci_core_subnet.askme_vcn_private_subnet[0].id
}