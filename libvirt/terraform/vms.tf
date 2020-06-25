# based on the example from:
# https://github.com/dmacvicar/terraform-provider-libvirt/tree/master/examples/v0.12/ubuntu

# todo: LIBVIRT_DEFAULT_URI does not work?
provider "libvirt" {
    uri = "qemu:///system"
}

# libvirt pool for the images in the path of the tf module
resource "libvirt_pool" "pool" {
    name = var.project
    type = "dir"
    path = abspath("${path.module}/libvirt-pool-${var.project}")
}

# backing image to save disk space for multiple vms
# https://kashyapc.fedorapeople.org/virt/lc-2012/snapshots-handout.html
resource "libvirt_volume" "base_volume" {
# resource "libvirt_volume" "volume" {
    name   = "${var.project}-base"
    pool   = libvirt_pool.pool.name
    source = var.baseimage
    format = var.baseimage_format

    # todo: required for "terraform destroy"
    depends_on = [libvirt_pool.pool]
}

resource "libvirt_volume" "volume" {
    # unique image (based on backing file) for each host
    for_each       = toset(var.hosts)

    name           = "${var.project}-cow-${each.value}"
    pool           = libvirt_pool.pool.name
    base_volume_id = libvirt_volume.base_volume.id
    size           = var.disk
}


# ssh private key
resource "tls_private_key" "id_rsa" {
    algorithm = "RSA"
}
resource "local_file" "ssh_private_key" {
    sensitive_content = tls_private_key.id_rsa.private_key_pem
    filename          = "${path.module}/../ssh/id_rsa"
    file_permission   = "0600"
}
resource "local_file" "ssh_public_key" {
    sensitive_content = tls_private_key.id_rsa.public_key_openssh
    filename          = "${path.module}/../ssh/id_rsa.pub"
}


# cloud init config files
data "template_file" "user_data" {
    template = file("${path.module}/${var.cloudinit_userdata}")
}
data "template_file" "network_config" {
    template = file("${path.module}/${var.cloudinit_networkconfig}")
}
# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
    name           = var.cloudinit_iso
    user_data      = data.template_file.user_data.rendered
    network_config = data.template_file.network_config.rendered
    pool           = var.project
}

resource "libvirt_domain" "host" {
    # create each host
    for_each = toset(var.hosts)

    name   = each.value
    memory = var.memory
    vcpu   = var.vcpu

    cloudinit = libvirt_cloudinit_disk.commoninit.id
    qemu_agent = true

    network_interface {
        network_name   = libvirt_network.network.name
        wait_for_lease = true
    }

    # IMPORTANT: this is a known bug on cloud images, since they expect a console
    # we need to pass it
    # https://bugs.launchpad.net/cloud-images/+bug/1573095
    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }

    console {
        type        = "pty"
        target_type = "virtio"
        target_port = "1"
    }

    disk {
        volume_id = libvirt_volume.volume[each.value].id
    }

    graphics {
        type        = "spice"
        listen_type = "address"
        autoport    = true
    }
}

resource "libvirt_network" "network" {
    name = var.project

    # mode can be: "nat" (default), "none", "route", "bridge"
    mode      = "nat"
    autostart = true

    #  the domain used by the DNS server in this network
    domain    = var.domain

    #  list of subnets the addresses allowed for domains connected
    # also derived to define the host addresses
    # also derived to define the addresses served by the DHCP server
    addresses = [var.network]

    # (optional) the bridge device defines the name of a bridge device
    # which will be used to construct the virtual network.
    # (only necessary in "bridge" mode)
    # bridge = "br7"

    # (optional) the MTU for the network. If not supplied, the underlying device's
    # default is used (usually 1500)
    # mtu = 9000

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

        # (Optional) one or more DNS forwarder entries.  One or both of
        # "address" and "domain" must be specified.  The format is:
        # forwarders {
        #     address = "my address"
        #     domain = "my domain"
        #  }
        #

        # (Optional) one or more DNS host entries.  Both of
        # "ip" and "hostname" must be specified.  The format is:
        # hosts  {
        #     hostname = "my_hostname"
        #     ip = "my.ip.address.1"
        #   }
        # hosts {
        #     hostname = "my_hostname"
        #     ip = "my.ip.address.2"
        #   }
        #

        # not possible due to cyclic dependency
        # use Ansible instead and amend manually, see ('../ansible/dhcp-static-hosts.yml')
        # dynamic "hosts" {
        #     for_each = var.hosts
        #     content {
        #         hostname = hosts.value
        #         ip = tolist(libvirt_domain.host[hosts.value].network_interface)[0]["addresses"][0]
        #     }
        # }

        # (Optional) one or more static routes.
        # "cidr" and "gateway" must be specified. The format is:
        # routes {
        #     cidr = "10.17.0.0/16"
        #     gateway = "10.18.0.2"
        #   }
    }

    dhcp {
        enabled = true
    }
}

resource "null_resource" "update_cloudinit" {
    triggers = {
        # when the ssh key in the local cloudinit file changes
        key_id   = local_file.ssh_public_key.id
    }
    provisioner "local-exec" {
        # recreate cloudinit config
        command = "echo '${templatefile("${path.module}/templates/cloud_init.cfg.tpl", { public_key = tls_private_key.id_rsa.public_key_openssh })}' > ./cloud_init.cfg"
    }
}
resource "null_resource" "update_inventory" {
    triggers = {
        # when a host id changes
        host_ids = "${join(" ", values(libvirt_domain.host)[*].id)}"
    }
    provisioner "local-exec" {
        # recreate ansible inventory
        command = "echo '${templatefile("${path.module}/templates/inventory.tpl", { hosts = libvirt_domain.host })}' > ../ansible/inventory"
    }
    provisioner "local-exec" {
        # recreate mapping of qemu VM id to hostnames 
        command = "echo '${templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = libvirt_domain.host })}' > ../ansible/qemu-config.yml"
    }
}
