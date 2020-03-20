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
    pool   = var.project
    source = var.baseimage
    format = var.baseimage_format

    # todo: required for "terraform destroy"
    depends_on = [libvirt_pool.pool]
}

resource "libvirt_volume" "volume" {
    # unique image (based on backing file) for each host
    for_each       = toset(var.hosts)

    name           = "${var.project}-cow-${each.value}"
    pool           = var.project
    base_volume_id = libvirt_volume.base_volume.id
}


# ssh private key
resource "tls_private_key" "id_rsa" {
    algorithm = "RSA"
}
resource "local_file" "ssh_private_key" {
    sensitive_content = tls_private_key.id_rsa.private_key_pem
    filename          = "${path.module}/../ssh/id_rsa"
    provisioner "local-exec" {
        command = "chmod 600 ${path.module}/../ssh/id_rsa"
    }
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
        network_name = "default"
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