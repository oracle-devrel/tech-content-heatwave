## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "oci_identity_dynamic_group" "askme_dynamic_group" {
    compartment_id = local.tenancy
    description = "AskME dynamic group"
    matching_rule = "ANY{instance.compartment.id = '${data.oci_identity_compartment.get_askme_compartment.id}', resource.compartment.id = '${data.oci_identity_compartment.get_askme_compartment.id}'}"
    name = "${local.compartment_name}-dynamic-group"
    provider = oci.home
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_identity_policy" "askme_policy" {
    compartment_id = local.tenancy
    description = "AskME policy"
    name = "${local.compartment_name}-policy.pl"
    provider = oci.home
    statements = [
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read volume-family in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read instance-family in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read objectstorage-namespaces in tenancy",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read buckets in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to manage objects in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read vaults in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to read secret-bundles in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to use generative-ai-chat in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to use generative-ai-text-generation in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to use generative-ai-text-summarization in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to use generative-ai-text-embedding in compartment ${data.oci_identity_compartment.get_askme_compartment.name}",
        "allow dynamic-group ${oci_identity_dynamic_group.askme_dynamic_group.name} to use generative-ai-model in compartment ${data.oci_identity_compartment.get_askme_compartment.name}"
    ]
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}