## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

data "oci_objectstorage_namespace" "askme_namespace" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    # Need to wait a bit longer than bucket creation to get this information
    # otherwise namespace not found
    depends_on = [
        oci_mysql_mysql_db_system.askme_dbsystem
    ]
}

resource "oci_objectstorage_bucket" "askme_bucket" {
    compartment_id = data.oci_identity_compartment.get_askme_compartment.id
    name = "${local.compartment_name}-bucket"
    namespace = data.oci_objectstorage_namespace.askme_namespace.namespace
    access_type = "NoPublicAccess"
    freeform_tags = {"${local.resource_tag_key}"="${local.resource_tag_value}"}
}

resource "oci_objectstorage_object" "askme_empty_file_example" {
    bucket    = oci_objectstorage_bucket.askme_bucket.name
    namespace = data.oci_objectstorage_namespace.askme_namespace.namespace
    object    = "workaround_empty/empty_doc.pdf"
    source    = abspath("documents/empty_doc.pdf")
}

resource "oci_objectstorage_object" "askme_file_example" {
    bucket    = oci_objectstorage_bucket.askme_bucket.name
    namespace = data.oci_objectstorage_namespace.askme_namespace.namespace
    object    = "documentation/heatwave-en.pdf"
    source    = abspath("documents/heatwave-en.pdf")
}