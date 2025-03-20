## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

module "vcn" {
    source = "oracle-terraform-modules/vcn/oci"
    version = "3.6.0"
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    region = local.region
    vcn_name = "${local.compartment_name}-vcn"
    create_internet_gateway = true
    create_nat_gateway = false
    create_service_gateway = false
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_core_security_list" "askme_public_security_list"{
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn.vcn_id
    display_name = "${local.compartment_name}-security-list-for-public-subnet"
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
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn.vcn_id
    cidr_block = "10.0.0.0/24"
    route_table_id = module.vcn.ig_route_id
    security_list_ids = [oci_core_security_list.askme_public_security_list.id]
    display_name = "${local.compartment_name}-public-subnet"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_core_security_list" "askme_private_security_list"{
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn.vcn_id
    display_name = "${local.compartment_name}-security-list-for-private-subnet"
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
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    vcn_id = module.vcn.vcn_id
    cidr_block = "10.0.1.0/24"
    route_table_id = module.vcn.nat_route_id
    security_list_ids = [oci_core_security_list.askme_private_security_list.id]
    display_name = "${local.compartment_name}-private-subnet"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}