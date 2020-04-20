---
page_title: "Terraform :: Modules :: Azure :: vmss_for_each_rg"
tags:
  - Terraform
  - tf_modules
  - Linux
  - VMSS
  - VM Scale Set
---
# vmss_for_each_rg

Deploys a set of Linux VM Scale Set (VMSS) resources into each corresponding regional Resource Group (RG) specified by the values of the `region_rg_map`.

By default, module deploys an internal Load Balancer (LB) with SKU `Standard` along each VMSS. The internal LB is configured to assign as a Frontend a `Dynamic` IP from the same subnet as the VMSS instances. The internal LB has a single Backend Pool where each VM from the Scale Set is placed. If `conf_module.enable_lb_int_rule_ha` is `true`, LB rule for Hight-Availability Ports is created balancing all `TCP/UDP` packets to any port of the Frontend IP. If `conf_module.enable_lb_int_rule_ha` is `false`, LB rule for the port `TCP/22 (SSH)` is associated with the internal LB and a Health Probe for the same port is deployed.

If `conf_module.enable_const_capacity` is `true`, each Scale Set is configured with an auto-scale rule to maintain constant instance count (useful for `Spot` instances).

If `conf_module.enable_lb_ext` is `true`, module deploys another external LB with a static Public IP (PIP) in each region. By default, an LB rule for the port `TCP/22 (SSH)` is associated with the external LB and a Health Probe for the same port is deployed. However if `enable_lb_ext_nat_ssh` is `true`, deploys a NAT Pool instead of the LB rule to directly map `TCP/20000, TCP/20001 ... TCP/20000+N` into `TCP/22 (SSH)` for all `N` VMs in the Scale Set.

If `conf_module.enable_pip_per_vm` is `true`, module assigns individual PIPs to each VM instance in the Scale Set. If in addition `conf_module.enable_pip_prefix` is `true`, PIPs are assigned from a single PIP prefix resource. The PIP prefix allocates IPs based on the `prefix_length` that takes values between `24` and `31`. Module calculates `prefix_length` as `32 - ceil(log(vm_instances, 2))`. As such, this use-case imposes a maximum limit of `vm_instances = 256` and opens up a possibility of charges for unused capacity (see below).

> **IMPORTANT!** Public IP prefixes are charged per IP per hour. As soon as a prefix is created, you are charged. So, `vm_instances` values that are not powers of 2 (e.g. `2`, `4`, `8`, `16`) will result in unused but billed Public IPs. For example, if you deploy a VMSS with `vm_instances = 5` the PIP prefix will be created with `prefix_length = 29` and would contain `8` IPs in total. While your VMSS only uses `5` PIPs from the prefix, you will be billed for `8` PIPs allocated throgh the PIP prefix.

If `conf_module.enable_zone_specific` is `true`, VMSS and internal LB's Frontend are deployed in a specific zone defined by the `availability_zone` option.

> **NOTE:** LB Frontends configured with a Public IP do not support zone-specific deployment. As such, when `conf_module.enable_lb_ext` is `true`, external LB's Frontend is deployed without anchoring to a specific Availability Zone.

if `conf_module.enable_zone_redundant` is `true`, VMSS is deployed in mult-zone configuration specified in the `zones` option.

> **NOTE:** It appears that VMSS could not be anchored in one or more zones, if it uses zone-specific PIP prefix (VMSS deployment error "Cannot specify Tags or Zones [...] for PublicIp [...] that is referencing PublicIpPrefix Id [...]"). As such, when `conf_module.enable_zone_*`, `conf_module.enable_pip_per_vm` and `conf_module.enable_pip_prefix` are `true`, each VMSS is deployed without anchoring to a single or multiple Availability Zones.

## Example Usage

```hcl
module "linux_scale_set" {
  source = "github.com/undp/tf-modules//azure_landing_zone/vmss_for_each_rg?ref=v0.1.4rc1"

  region_rg_map = {
    eastus        = "rg1"
    canadacentral = "rg2"
  }

  conf_module = {
    enable_const_capacity = true
    enable_lb_ext         = true
    enable_lb_ext_nat_ssh = true
  }

  conf_common = {
    vm_size      = "Standard_DS1_v2"
    vm_instances = 2

    image_publisher = "Canonical"
    image_offer     = "UbuntuServer"
    image_sku       = "18.04-LTS"
    image_version   = "latest"

    os_disk_ephemeral = true
  }

  conf_map = {
    eastus  = {
      name = "alice"
      admin_username = "admin_alice"
      public_key = file("alice_ssh_key.pub")
    }
    canadacentral = {
      name = "bob"
      admin_username = "admin_bob"
      public_key = file("bob_ssh_key.pub")
    }
  }

  namespace = "deep"

  tags = {
    BU    = "Enterprise"
    Owner = "Security"
  }
}
```

## Input variables

The following module arguments are supported:

* `region_rg_map` - Map of locations to RG names where resources are deployed for each region.

* `conf_module` - Map of parameters defining module-wide functionality.

* `conf_common` - Common configuration parameters applied to all regions.

* `conf_map` - (Optional) Map of locations to region-specific configuration parameters applied to each individual region.

* `namespace` - (Optional) Namespace to use as a prefix in resource names and in tags.

* `tags` - (Optional) Tags to be assigned to each deployed resource.

## Configuration Parameters

### Module Functionality

A `conf_module` parameter supports the following options:

* `enable_const_capacity` - (Optional) Does each Scale Set has an auto-scale rule to maintain constant instance capacity? If unspecified, module uses `false` as a default.

* `enable_lb_int_rule_ha` - (Optional) Does each internal LB of a Scale Set has a rule implementing HA Ports balancing instead of the regular `TCP/22 (SSH)`? If unspecified, module uses `false` as a default.

* `enable_lb_ext` - (Optional) Does each Scale Set has an external LB with a static PIP and a balancing rule for `TCP/22 (SSH)` assigned to it? If unspecified, module uses `false` as a default.

* `enable_lb_int_rule_ha` - (Optional) Does each internal LB have a balancing rule for High-Availability ports configured (useful for network virtual appliance deployment)? If unspecified, module uses `false` as a default.

* `enable_lb_ext_nat_ssh` - (Optional) Does each external LB have a NAT Pool configured instead of the balancing rule to reach individual VMs in the Scale Set over `SSH` to PIP and port `20000 + N` where `N` is the instance number? If unspecified, module uses `false` as a default.

  > **NOTE:** This parameter is considered only if `enable_lb_ext` is set to `true`.

* `enable_pip_per_vm` - (Optional) Does each Scale Set assign individual PIPs directly to each VM? If unspecified, module uses `false` as a default.

* `enable_pip_prefix` - (Optional) Does each Scale Set uses a common PIP prefix to assign individual PIPs directly to each VM? If unspecified, module uses `false` as a default.

  > **NOTE:** This parameter is considered only if `enable_pip_per_vm` is set to `true`.

* `enable_zone_redundant` - (Optional) Are VMs in each Scale Set deployed in multiple Availability Zones? If `true`, allows usage of `zones` and `zone_balance` VMSS parameters. This setting is mutually-exclusive with `enable_zone_specific` and takes precedence over it. If unspecified, module uses `false` as a default.

* `enable_zone_specific` - (Optional) Are all resources supporting zonality deployed in a specific Availability Zone? This setting is mutually-exclusive with `enable_zone_redundant` and is overruled by it. If `true`, allows usage of `availability_zone`. If unspecified, module uses `false` as a default.

  > **EXAMPLE**: If `enable_zone_redundant` is `true`, `enable_zone_specific` is considered to be `false` regardless of the actual value.

### Resource Options

VM Scale Set parameters are defined by either parameters in the `conf_common` map for all regions at once, or by `conf_map` for each region individually. Common parameters from `conf_common` get precedence over region-specific ones from `conf_map`. If no parameter is provided in any of the two, default value is assigned.

  > **IMPORTANT!** Keys for `region_rg_map` and `conf_map` must match.

Both `conf_common` and `conf_map` parameters support the following options:

* `name` - (Required) Constant part of a resource name. Module generates regional resource names following the template `{{prefix}}_{{resource_name}}_{{location}}_{{suffix}}` with the substitutions below:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{resource_name}}` is the value of `conf_common.name`, if defined. Otherwise, `conf_map[*].name` for each regional resource. If `conf_map[*].name` parameter does not exist for some keys, `{{resource_name}}` is dropped from the name.

  * `{{location}}` is the keys of `region_rg_map`.

  * `{{suffix}}` is defined based on the type of the resource and follows this mapping:
    * `autoscale` for VMSS Auto-scaling Profile
    * `lb_ext` for external LB
    * `lb_ext_backend` for Backend Pool of the external LB
    * `lb_ext_pip` for external LB's Public IP
    * `lb_ext_pool_ssh` for optional NAT Pool associated with the external LB
    * `lb_ext_probe_ssh` for a Health Probe of `TCP/22 (SSH)` associated with the external LB
    * `lb_ext_rule_ssh` for the external LB Rule balancing inbound traffic to `TCP/22 (SSH)`
    * `lb_int` for internal LB
    * `lb_int_backend` for Backend Pool of the internal LB
    * `lb_int_probe_ssh` for a Health Probe of `TCP/22 (SSH)` associated with the internal LB
    * `lb_int_rule_ha` for the internal LB Rule implementing HA Ports
    * `lb_int_rule_ssh` for the internal LB Rule balancing inbound traffic to `TCP/22 (SSH)`
    * `prefix` for Public IP Prefix
    * `vmss` for the Scale Set

* `computer_name_prefix` - (Optional) The prefix which should be used as part of the hostname for each VM in the Scale Set. If unspecified, module uses `null` causing `azurerm` provider to default to the value for the `name` field.

* `vm_size` - (Required) The Virtual Machine SKU for the Scale Set, such as `Standard_F2`. If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

* `vm_instances` - (Required) The number of VMs in the Scale Set. If unspecified, module uses `1`.

* `overprovision` - (Optional) Should Azure over-provision VMs in the Scale Set? This means that multiple VMs will be provisioned and Azure will keep the instances which become available first - which improves provisioning success rates and improves deployment time. Over-provisioned VMs are not billed and don't count towards the Subscription Quota.  If unspecified, module uses `false` as a default.

* `priority` - (Optional) The Priority of the Virtual Machine Scale Set. Possible values are `Regular` and `Spot`. If unspecified, module uses `Regular` as a default.

* `eviction_policy` - (Optional) The Policy which should be used when VMs are Evicted from the Scale Set. Possible values are `Deallocate` and `Delete`. If unspecified, module uses `Delete` as a default.

  > **NOTE:** This parameter is only used if `priority` is set to `Spot`. Otherwise, module ignores this parameter and uses `null` as a value.

* `admin_username` - (Optional) The username of the local administrator on each Virtual Machine Scale Set instance. If unspecified, module uses `vmssadmin` as a default.

  > **NOTE:** Same username is used to deploy the SSH key for each VM in the Scale Set.

* `public_key` - (Required) The SSH Public Key which should be used for authentication, which needs to be at least 2048-bit and in `ssh-rsa` format.

  > **NOTE:** The module does not allow to configure password-based SSH access and sets `admin_password` to `null` and `disable_password_authentication` to `true` for all VMs in the Scale Set.

* `availability_zone` - (Optional) Specific Availability Zone in which all supported resources should be created in. If unspecified, module uses `1`.

  > **NOTE:** This parameter is considered only if `conf_module.enable_zone_specific` is `true`. Otherwise, module ignores this parameter and uses `null` as a value.

* `zones` - (Optional) A list of Availability Zones in which the VMs in the Scale Set should be created in. If unspecified, module uses empty list `[]`.

  > **NOTE:** This parameter is considered only if `conf_module.enable_zone_redundant` is `true`. Otherwise, module ignores this parameter and uses `null` as a value.

* `zone_balance` - (Optional) Should the Virtual Machines in the Scale Set be strictly evenly distributed across Availability Zones? If unspecified, module uses `true`.

  > **NOTE:** This parameter is considered only if `conf_module.enable_zone_redundant` is `true`. Otherwise, module ignores this parameter and uses `null` as a value.

* `provision_vm_agent` - (Optional) Should the Azure VM Agent be provisioned on each VM in the Scale Set? If unspecified, module uses `true` as a default.

* `image_publisher` - (Required) Specifies the image publisher reference that each VM in the Scale Set should be based on. If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

  > **NOTE:** If `source_image_id` is set, this parameter is ignored.

* `image_offer` - (Required) Specifies the the image offer reference that each VM in the Scale Set should be based on. If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

  > **NOTE:** If `source_image_id` is set, this parameter is ignored.

* `image_sku` - (Required) Specifies the the image SKU reference that each VM in the Scale Set should be based on. If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

  > **NOTE:** If `source_image_id` is set, this parameter is ignored.

* `image_version` - (Required) Specifies the the image version reference that each VM in the Scale Set should be based on. If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

  > **NOTE:** If `source_image_id` is set, this parameter is ignored.

* `source_image_id` - (Optional) The ID of an image which each VM in the Scale Set should be based on.

* `os_disk_caching` - (Optional) The type of caching which should be used for the OS disk of each VM in the Scale Set. Possible values are `None`, `ReadOnly` and `ReadWrite`. If unspecified, module uses `None` as a default.

  > **NOTE:** If `os_disk_ephemeral` is set to `true`, the module uses `ReadOnly` regardless of the actual value specified in this parameter.

* `os_disk_type` - (Optional) The type of Storage Account which should back the OS disk of each VM in the Scale Set. Possible values are `Standard_LRS`, `StandardSSD_LRS` and `Premium_LRS`. If unspecified, module uses `Standard_LRS` as a default.

  > **NOTE:** If `os_disk_ephemeral` is set to `true`, the module uses `Standard_LRS` regardless of the actual value specified in this parameter.

* `os_disk_ephemeral` - (Optional) Should the OS disk be provisioned as ephemeral (changes are not saved between reboots) for each VM in the Scale Set? If unspecified, module uses `false` as a default.

* `data_disk_disk_count` - (Optional) The number of data disks to be attached to each VM in the Scale Set. If unspecified, module uses `0` as a default and no data disks created.

* `data_disk_caching` - (Optional) The type of caching which should be used for all data disks attached to each VM in the Scale Set. Possible values are `None`, `ReadOnly` and `ReadWrite`. If unspecified, module uses `None` as a default.

  > **NOTE:** If `data_disk_disk_count` is set to `0`, this parameter is ignored.

* `data_disk_type` - (Optional) The type of Storage Account which should back all data disks to be attached to each VM in the Scale Set. Possible values include `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS` and `UltraSSD_LRS`. If unspecified, module uses `Standard_LRS` as a default.

  > **NOTE:** If `data_disk_disk_count` is set to `0`, this parameter is ignored.

* `data_disk_disk_size_gb` - (Optional) The size in Gb of each data disk to be attached to each VM in the Scale Set. If unspecified, module uses `10` as a default.

  > **NOTE:** If `data_disk_disk_count` is set to `0`, this parameter is ignored.

* `vnet_name` - (Required) Constant part of the VNET name where the Scale Set is deployed for each region. Module expects regional VNET names to follow the template `{{prefix}}_{{name}}_{{location}}_vnet` with the following substitutions:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{name}}` is the value of `vnet_name`.

  * `{{location}}` is the keys of `region_rg_map`.

* `vnet_rg_name` - (Required) Constant part of the Scale Set VNET's Resource Group. Module expects VNET RG names to follow the template `{{prefix}}_{{name}}_{{location}}` with the following substitutions:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{name}}` is the value of `vnet_rg_name`.

  * `{{location}}` is the keys of `region_rg_map`.

* `subnet_name` - (Required) Name of the subnet in each VNET where the Scale Set should be deployed.  If unspecified, module uses `null` causing `azurerm` provider to fail the deployment.

  > **IMPORTANT!** Subnet, VNET and corresponding RG imported as `data` and thus, MUST exist prior to invocation of this module.

* `asg_rg` - (Optional) Constant part of the Resource Group name containing Application Security Groups to be assigned to each VM in the Scale Set. Module expects RG names to follow the template `{{prefix}}_{{name}}_{{location}}` with the following substitutions:

  * `{{prefix}}` is the value of `namespace`, if defined. Otherwise, `{{prefix}}` is dropped from the name.

  * `{{name}}` is the value of `asg_rg`.

  * `{{location}}` is the keys of `region_rg_map`.

* `asg_list` - (Optional) List of Application Security Group names to be assigned to each VM in the Scale Set. If unspecified, module does not assign VMs in the Scale Set to ASG.

  > **IMPORTANT!** ASGs are imported as `data` and thus, MUST exist prior to invocation of this module.

* `enable_ip_forwarding` - (Optional) Does each VM in the Scale Set support IP Forwarding? If unspecified, module uses `false` as a default.

* `upgrade_mode` - (Optional) Specifies how upgrades (e.g. changing the Image/SKU) should be performed each VM in the Scale Set. Possible values are `Automatic`, `Manual` and `Rolling`. If unspecified, module uses `Automatic` as a default.

* `rolling_upgrade_max_batch` - (Optional) The maximum percent of total VMs in the Scale Set that will be upgraded simultaneously by the rolling upgrade in one batch. As this is a maximum, unhealthy instances in previous or future batches can cause the percentage of instances in a batch to decrease to ensure higher reliability. If unspecified, module uses `20` as a default.

  > **NOTE:** This parameter is applied only if `upgrade_mode` is set to `Rolling`.

* `rolling_upgrade_max_unhealthy` - (Optional) The maximum percentage of the total VMs in the Scale Set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch. If unspecified, module uses `20` as a default.

  > **NOTE:** This parameter is applied only if `upgrade_mode` is set to `Rolling`.

* `rolling_upgrade_max_unhealthy_upgraded` - (Optional) The maximum percentage of upgraded VMs in the Scale Set that can be found to be in an unhealthy state. This check will happen after each batch is upgraded. If this percentage is ever exceeded, the rolling update aborts. If unspecified, module uses `20` as a default.

  > **NOTE:** This parameter is applied only if `upgrade_mode` is set to `Rolling`.

* `rolling_upgrade_pause_time` - (Optional) The wait time between completing the update for all VMs in one batch and starting the next batch. The time duration should be specified in ISO 8601 format. If unspecified, module uses `PT30S` as a default.

  > **NOTE:** This parameter is applied only if `upgrade_mode` is set to `Rolling`.

## Output variables

The following attributes are exported:

* `lb_ext_id_map` - Map of external LB IDs to corresponding name and resource group.
* `lb_ext_obj_map` - Map of `region_rg_map.key` to all external LB resource properties.
* `lb_ext_backend_id_map` - Map of external LB Backend IDs to corresponding name and LB ID.
* `lb_ext_backend_obj_map` - Map of `region_rg_map.key` to all external LB Backend resource properties.
* `lb_int_id_map` - Map of internal LB IDs to corresponding name and resource group.
* `lb_int_obj_map` - Map of `region_rg_map.key` to all internal LB resource properties.
* `lb_int_backend_id_map` - Map of internal LB Backend IDs to corresponding name and LB ID.
* `lb_int_backend_obj_map` - Map of `region_rg_map.key` to all internal LB Backend resource properties.
* `prefix_id_map` - Map of PIP Prefix IDs to corresponding name and resource group.
* `prefix_obj_map` - Map of `region_rg_map.key` to all PIP Prefix resource properties.
* `vmss_id_map` - Map of VMSS IDs to corresponding name and resource group.
* `vmss_obj_map` - Map of `region_rg_map.key` to all VMSS resource properties.
