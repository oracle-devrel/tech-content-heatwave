## Copyright (c) 2025 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License (UPL), Version 1.0.

resource "random_password" "mysql_password" {
    length = 32
    min_numeric = 1
    min_special = 1
    min_lower = 1
    min_upper = 1
    override_special = "!#$%&*()-_=+[]{}"
}

# Internal constants, do not change.
locals {
    # DBSystem credentials
    mysql_username = "admin"
    mysql_password = random_password.mysql_password.result

    # Code for the instance deployment
    demos_repo_url = "https://github.com/oracle-devrel/tech-content-heatwave.git"
    demos_repo_subfolder = "askme"
    demos_repo_branch = "tech-content-heatwave_askme_flexible"
}
