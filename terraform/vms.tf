resource "proxmox_vm_qemu" "host" {
    # create each host
    for_each = toset(var.hosts)

    name = "${each.value}"

    cores = var.cores
    sockets = var.sockets
    memory = var.memory

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = var.disk
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }
    dynamic "serial" {
        #for_each = var.serial
        for_each = var.serial ? [true] : [] 
        content {
            id = 0
            type = "socket"
        }
    }
    vga {
        type = var.vga
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = var.macaddr[each.value]
    }

    target_node = var.target_node
    pool = var.pool
    clone = var.clone
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "null_resource" "update_inventory" {
    triggers = {
        # when a host id changes
        host_ids = "${join(" ", values(proxmox_vm_qemu.host)[*].id)}"
    }
    provisioner "local-exec" {
        # recreate ansible inventory
        command = "echo '${templatefile("${path.module}/templates/inventory.tpl", { hosts = proxmox_vm_qemu.host })}' > ../ansible/inventory"
    }
    provisioner "local-exec" {
        # recreate mapping of qemu VM id to hostnames 
        command = "echo '${templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = proxmox_vm_qemu.host })}' > ../ansible/qemu-config.yml"
    }
}

# ssh private key
resource "tls_private_key" "id_rsa" {
    algorithm = "RSA"
}
resource "local_file" "ssh_private_key" {
    sensitive_content = "${tls_private_key.id_rsa.private_key_pem}"
    filename          = "${path.module}/../ssh/id_rsa"
    provisioner "local-exec" {
        command = "chmod 600 ${path.module}/../ssh/id_rsa"
    }
}
resource "local_file" "ssh_public_key" {
    sensitive_content = "${tls_private_key.id_rsa.public_key_openssh}"
    filename          = "${path.module}/../ssh/id_rsa.pub"
}
