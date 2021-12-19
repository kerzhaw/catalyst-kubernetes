terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.46.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
#   user_name   = "admin"
#   tenant_name = "admin"
#   password    = "pwd"
#   auth_url    = "http://myauthurl:5000/v2.0"
  region      = "nz-hlz-1"
}

resource "openstack_containerinfra_cluster_v1" "cluster" {
  name                = "cluster"
  cluster_template_id = "b9a45c5c-cd03-4958-82aa-b80bf93cb922"
  master_count        = 1
  node_count          = 2
  keypair             = "paul"
  floating_ip_enabled = true
}