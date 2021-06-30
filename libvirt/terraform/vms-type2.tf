resource "libvirt_volume" "base_volume_type2" {
# resource "libvirt_volume_type2" "volume" {
    name   = "${var.project}-base"
    pool   = libvirt_pool.pool.name
    source = var.baseimage_type2
    format = var.baseimage_format

    # todo: required for "terraform destroy"
    depends_on = [libvirt_pool.pool]
}

resource "libvirt_volume" "volume_type2" {
    # unique image (based on backing file) for each host
    for_each       = toset(var.type2_hosts)

    name           = "${var.project}-cow-${each.value}"
    pool           = libvirt_pool.pool.name
    base_volume_id = libvirt_volume.base_volume_type2.id
    size           = var.disk
}

resource "libvirt_domain" "hosts_type2" {
    # create each host
    for_each = toset(var.type2_hosts)

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
        volume_id = libvirt_volume.volume_type2[each.value].id
    }

    graphics {
        type        = "spice"
        listen_type = "address"
        autoport    = true
    }
}