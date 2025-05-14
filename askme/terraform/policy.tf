## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_identity_dynamic_group" "askme_dynamic_group" {
    # Create 1 dynamic group in the root compartment if dynamic_group_and_policy_created is false
    count = local.dynamic_group_and_policy_created ? 0 : 1
    compartment_id = local.tenancy
    description = "AskME dynamic group"
    matching_rule = "ANY{instance.compartment.id = '${data.oci_identity_compartment.get_askme_compartment.id}', resource.compartment.id = '${data.oci_identity_compartment.get_askme_compartment.id}'}"
    name = "${local.common_identifier_unique}-dynamic-group"
    provider = oci.home
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_identity_policy" "askme_policy" {
    # Create 1 policy in the root compartment if dynamic_group_and_policy_created is false
    count = local.dynamic_group_and_policy_created ? 0 : 1
    compartment_id = local.tenancy
    description = "AskME policy"
    name = "${local.common_identifier_unique}-policy.pl"
    provider = oci.home
    statements = [
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read volume-family in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read instance-family in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read objectstorage-namespaces in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read buckets in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to manage objects in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read vaults in compartment id ${data.oci_kms_vault.get_askme_vault.compartment_id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to read secret-bundles in compartment id ${data.oci_kms_vault.get_askme_vault.compartment_id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to use generative-ai-chat in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to use generative-ai-text-generation in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to use generative-ai-text-summarization in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to use generative-ai-text-embedding in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group[0].name} to use generative-ai-model in compartment id ${data.oci_identity_compartment.get_askme_compartment.id}"
    ]
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}