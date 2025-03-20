## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

output "askme_instance_public_ip" {
    value = oci_core_instance.askme_instance.public_ip
    description = "Public IP of the AskME instance"
}

output "askme_dbsystem_mysql_host_ip" {
    value = oci_mysql_mysql_db_system.askme_dbsystem.ip_address
    description = "Private IP of the AskME DBSystem"
}

output "askme_dbsystem_mysql_username" {
    value = local.mysql_username
    description = "Username of the AskME DBSystem admin user"
}

output "askme_dbsystem_mysql_password" {
    value = local.mysql_password
    description = "Password of the AskME DBSystem admin user"
    sensitive = true
}