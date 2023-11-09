provider "google" {
  project = "opz0-397319"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

#####==============================================================================
##### vpc module call.
#####==============================================================================
module "vpc" {
  source                                    = "git::git@github.com:opsstation/terraform-gcp-vpc.git?ref=master"
  name                                      = "app"
  environment                               = "test"
  label_order                               = ["name", "environment"]
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

#####==============================================================================
##### subnet module call.
#####==============================================================================
module "subnet" {
  source        = "git::git@github.com:opsstation/terraform-gcp-subnet.git?ref=master"
  name          = "subnet"
  environment   = "test"
  label_order   = ["name", "environment"]
  gcp_region    = "asia-northeast1"
  network       = module.vpc.vpc_id
  ip_cidr_range = "10.10.0.0/16"
}

#####==============================================================================
##### firewall module call.
#####==============================================================================
module "firewall" {
  source        = "git::git@github.com:opsstation/terraform-gcp-firewall.git?ref=master"
  name          = "app"
  environment   = "test"
  label_order   = ["name", "environment"]
  network       = module.vpc.vpc_id
  source_ranges = ["0.0.0.0/0"]

  allow = [
    { protocol = "tcp"
      ports    = ["22", "80"]
    }
  ]
}

#####==============================================================================
##### instance_template module call.
#####==============================================================================
module "instance_template" {
  source               = "git::git@github.com:opsstation/terraform-gcp-vm-template-instance.git?ref=master"
  instance_template    = true
  name                 = "template"
  environment          = "test"
  label_order          = ["name", "environment"]
  region               = "asia-northeast1"
  source_image         = "ubuntu-2204-jammy-v20230908"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  subnetwork           = module.subnet.subnet_id
  service_account      = null
  metadata = {
    ssh-keys = <<EOF
        dev:ssh-rsa +j/FmgC27u/+L6ihYrPhcx51lj99yDW8X8W/zKU+lCBaggRjlkx4Q3NWS1gefgv3k/3mwt2y+PDQMU= suresh@suresh

      EOF
  }
  access_config = [{
    nat_ip       = ""
    network_tier = ""
  }, ]
}

#####==============================================================================
##### instance_group module call.
#####==============================================================================
module "mig" {
  source                       = "../../../"
  hostname                     = "test"
  environment                  = "instance-group"
  max_replicas                 = 2
  region                       = var.region
  target_pools                 = var.target_pools
  distribution_policy_zones    = var.distribution_policy_zones
  update_policy                = var.update_policy
  named_ports                  = var.named_ports
  health_check                 = var.health_check
  autoscaling_enabled          = var.autoscaling_enabled
  autoscaling_cpu              = var.autoscaling_cpu
  autoscaling_metric           = var.autoscaling_metric
  autoscaling_lb               = var.autoscaling_lb
  autoscaling_scale_in_control = var.autoscaling_scale_in_control
  instance_template            = module.instance_template.self_link_unique
}