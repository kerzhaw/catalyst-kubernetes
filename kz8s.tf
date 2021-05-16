# Define required providers
terraform {
required_version = ">= 0.15.3"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.42.0"
    }
  }
}

provider "openstack" {  
}

# Create a Router
resource "openstack_networking_router_v2" "border-router" {
    name = "border-router"
    external_network_id = "f10ad6de-a26d-4c29-8c64-2a7418d47f8f"
}

# Create a Network  
resource "openstack_networking_network_v2" "kz8s-net" {
    name = "kz8s-net"
    admin_state_up = "true"
}

# Create a Subnet
resource "openstack_networking_subnet_v2" "kubernetes-subnet" {
    name = "kubernetes-subnet"
    network_id = "${openstack_networking_network_v2.kz8s-net.id}"
    # allocation_pools {
    #     start = "10.0.0.10"
    #     end = "10.0.0.200"
    # }
    enable_dhcp = "true"
    cidr = "10.240.0.0/24"
    ip_version = 4
}

# Create a Router interface
resource "openstack_networking_router_interface_v2" "router-interface" {
    router_id = "${openstack_networking_router_v2.border-router.id}"
    subnet_id = "${openstack_networking_subnet_v2.kubernetes-subnet.id}"
}

# Create a Security Group
resource "openstack_compute_secgroup_v2" "kubernetes-SSH" {
    name = "kubernetes-SSH"
    description = "kubernetes SSH"
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
}

# Upload SSH public key
# replace public_key with a valid SSH public key that you wish to use
resource "openstack_compute_keypair_v2" "keypair" {
  name = "kz8s"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDofvDyT4t1HaJHCADt3ljS5Q5usPm2za7dieyklwVaZ63PDk9eYsh2/VezojcxfB8fgd/IR5RXU1TfYcigH0/Z3TxHyXxfCb3E9BbdIqJ/IRVAOHEAL8EP1lQNFEYtLe3g4JE0Jeicxn9wFNIDO8nrcGOGyblHaSq1K3o5wt81n0D4t7T1nNp42/QSi9s15JucIMVn8a+sYYT7wABtETANRC8M2aXRwCRCFomuGhQ3ZDreTCR/LylfQEMUSwSZUzO2QoReFP9bN/9j74c/iZOSRyQguD796EmkGsQHbsdNFtJiB2cSg9dbESoYx4Sqk9RUBWyNg2eav0uxC+A+wN49p0VbJZ7tFNC/Dd0PX82iBS0BTXGqagIsT5MG5oigbkOuI4r3vpAPcVn7QCo1qRoIMMF6GwuoSFFPYwKIjMUcTahSHDAMFgmVjvmYOoTKJglJvrLmgq7L9dTPgcxB46t0xkXhof+0HTM1m1Qc8oXLJLZlqabRpFKArbTP5+RTw6E= paul@kerzhaw.com"
}

resource "openstack_blockstorage_volume_v2" "controller-0-volume" {
  name        = "controller-0-volume"
  size        = 100
  image_id    = "e4623196-706d-4d1e-8f42-769b2300650c" // ubuntu-20.04-x86_64
}

## Create controller-0
resource "openstack_compute_instance_v2" "controller-0" {
  name            = "controller-0"
  flavor_id       = "c62db2ea-2ccd-49f0-9b88-307cdd3d6e0e" // c1.c2r2
  key_pair        = "kz8s"
  security_groups = ["${openstack_compute_secgroup_v2.kubernetes-SSH.name}", "default"]

  block_device {
    uuid                  = "${openstack_blockstorage_volume_v2.controller-0-volume.id}"
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }

  network {
    name = "${openstack_networking_network_v2.kz8s-net.name}"
    fixed_ip_v4 = "10.240.0.10"
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh args",
    ]
  }
}

# Request a floating IP
resource "openstack_networking_floatingip_v2" "kz8s-public-ip" {
    pool = "public-net"
}

# Associate floating IP
resource "openstack_compute_floatingip_associate_v2" "kz8s-public-ip-assoc" {
  floating_ip = "${openstack_networking_floatingip_v2.kz8s-public-ip.address}"
  instance_id = "${openstack_compute_instance_v2.controller-0.id}"
}