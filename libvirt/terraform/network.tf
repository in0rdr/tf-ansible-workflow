provider "libvirt" {
  uri = "qemu:///system"
}

# libvirt pool for the images in the path of the tf module
resource "libvirt_pool" "pool" {
  name = var.project
  type = "dir"
  path = abspath("${path.module}/libvirt-pool-${var.project}")
}

resource "libvirt_network" "network" {
  name = var.project

  # mode can be: "nat" (default), "none", "route", "bridge"
  mode      = "nat"
  autostart = true

  #  the domain used by the DNS server in this network
  domain = var.domain

  # list of subnets the addresses allowed for domains connected
  # also derived to define the host addresses
  # also derived to define the addresses served by the DHCP server
  addresses = [var.network]

  # (Optional) DNS configuration
  dns {
    # (Optional, default false)
    # Set to true, if no other option is specified and you still want to
    # enable dns.
    enabled = true
    # (Optional, default false)
    # true: DNS requests under this domain will only be resolved by the
    # virtual network's own DNS server
    # false: Unresolved requests will be forwarded to the host's
    # upstream DNS server if the virtual network's DNS server does not
    # have an answer.
    local_only = true
  }

  dhcp {
    enabled = true
  }
}

resource "null_resource" "update_inventory" {
  triggers = {
    # when a host id changes
    host_ids = join(" ", values(merge({loadbalancer = libvirt_domain.host_loadbalancer, bootstrap = libvirt_domain.host_bootstrap}, libvirt_domain.host_master))[*].id)
  }
  provisioner "local-exec" {
    # recreate ansible inventory
    command = "echo '${templatefile("${path.module}/templates/inventory.tpl", { hosts = merge({loadbalancer = libvirt_domain.host_loadbalancer, bootstrap = libvirt_domain.host_bootstrap}, libvirt_domain.host_master) })}' > ../ansible/inventory"
  }
  provisioner "local-exec" {
    # recreate mapping of qemu VM id to hostnames
    command = "echo '${templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = merge({loadbalancer = libvirt_domain.host_loadbalancer, bootstrap = libvirt_domain.host_bootstrap}, libvirt_domain.host_master) })}' > ../ansible/qemu-config.yml"
  }
}
