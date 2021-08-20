# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
  }
}

provider "cloudinit" {
}

# Configure the OpenStack Provider
provider "openstack" {
  cloud       = "openstack"
  cacert_file = "root.crt"
  insecure    = true
}

# Networking

resource "openstack_networking_network_v2" "network_1" {
  name           = "network_1"
  admin_state_up = "true"
}

resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  admin_state_up      = "true"
  external_network_id = "b32ae8ee-391a-4f6d-9307-30eedd6833a8"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "subnet_1"
  network_id = openstack_networking_network_v2.network_1.id
  cidr       = "192.168.109.0/24"
  ip_version = 4
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "ssh"
  description = "open ssh port"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_port_v2" "port_1" {
  name               = "port_1"
  network_id         = openstack_networking_network_v2.network_1.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.subnet_1.id
    ip_address = "192.168.109.10"
  }
}

resource "openstack_networking_port_v2" "port_2" {
  name               = "port_2"
  network_id         = openstack_networking_network_v2.network_1.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.subnet_1.id
    ip_address = "192.168.109.11"
  }
}

# Instâncias

resource "openstack_compute_instance_v2" "instance1" {
  name            = "instance1"
  image_name      = "ubuntu-20.04.1-server-64bit"
  flavor_name     = "c2.small"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  key_pair        = "Jarvis"
  network {
    port = openstack_networking_port_v2.port_1.id
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh"
    ]
  }
}


resource "openstack_compute_instance_v2" "instance2" {
  name            = "instance2"
  image_name      = "ubuntu-20.04.1-server-64bit"
  flavor_name     = "c2.small"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  key_pair        = "Jarvis"
  network {
    port = openstack_networking_port_v2.port_2.id
  }
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh"
    ]
  }
}

