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
    subnet_id = "${openstack_networking_subnet_v2.kz8s-net.id}"
}

# Create a Security Group
resource "openstack_compute_secgroup_v2" "SSH" {
    name = "SSH"
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
}