# backing image to save disk space for multiple vms
# https://kashyapc.fedorapeople.org/virt/lc-2012/snapshots-handout.html
resource "libvirt_volume" "base_volume_master" {
  name   = "${var.project}-base_master"
  pool   = libvirt_pool.pool.name
  source = var.openshift_master_baseimage
  format = var.baseimage_format

  depends_on = [libvirt_pool.pool]
}

resource "libvirt_volume" "volume_master" {
  # unique image (based on backing file) for each host
  for_each = toset(var.openshift_master_nodes)

  name           = "${var.project}-cow-${each.value}"
  pool           = libvirt_pool.pool.name
  base_volume_id = libvirt_volume.base_volume_master.id
  size           = var.disk
}

resource "libvirt_domain" "host_master" {
  # create each host
  for_each = toset(var.openshift_master_nodes)

  name   = each.value
  memory = var.memory
  vcpu   = var.vcpu

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
    volume_id = libvirt_volume.volume_master[each.value].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}