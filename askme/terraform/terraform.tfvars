######################################
# Setup constants: Parent compartment.
# You can choose in which compartment the AskME compartment and resources will be deployed.
######################################

# If specified, a new compartment containing all new resources (Compute, DBSystem, ...) will be created in this parent compartment (default parent compartment: root/tenancy compartment)
# This field is ignored if the flexible resource variable "compartment_ocid" is assigned a value.
parent_compartment_ocid = null


######################################
# Setup constants: Flexible resources.
# You can add the OCID of any resource from your tenancy you would like to use.
# Compute, DBSystem and OS Bucket need to be setup by terraform, can't be flexible (script installation and credentials setup)
######################################

# If specified, all new resources (Compute, DBSystem, ...) will be deployed in this compartment.
compartment_ocid = null

vault_ocid = null
# If specified, the vault key needs to be associated to vault_ocid.
vault_key_ocid = null

# If specified, both values (public subnet and private subnet) need to be provided and need to come from the same VCN.
# The VCN/subnets don't necessarily need to be located in compartment_ocid.
public_vcn_subnet_ocid = null
private_vcn_subnet_ocid = null

# Terraform may not be able to create/access the dynamic group and the policy in the root compartment, so either:
# - Terraform assumes they were created with the right rules in the root compartment by an administrator (true)
# - Terraform tries to create them in the root compartment (default value: false)
# For more information, please check the README instructions.
dynamic_group_and_policy_created = false


######################################
# Setup constants: Compute and DBSystem parameters.
# You can change the shape, version, ...
######################################

mysql_shape = "MySQL.8"
mysql_version = "9.4.2"
heatwave_shape = "HeatWave.512GB"
heatwave_nodes = 1
compute_shape = "VM.Standard.E4.Flex"
compute_memory = 16
