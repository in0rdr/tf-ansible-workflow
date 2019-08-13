# variable "mac_id" {
#   default = "0"
# }

# resource "random_id" "macaddr" {
#     keepers = {
#         # Generate a new id each time we switch to a new MAC id
#         mac_id = "${var.mac_id}"
#     }
#     byte_length = 1
# }

# network {
#         # Read the MAC id "through" the mac_id resource to ensure that
#         # both will change together.
#         # macaddr = "${random_id.macaddr.hex}"
# }



# Can we use "count" for multiple instancances and seed the Mac addr
# from a pool of mac addresses ?


resource "tls_private_key" "id_rsa" {
    algorithm = "RSA"
}

resource "local_file" "ssh_key" {
    sensitive_content = "${tls_private_key.id_rsa.private_key_pem}"
    filename          = "${path.module}/id_rsa"
    provisioner "local-exec" {
        command = "chmod 600 ${path.module}/id_rsa"
    }
}

resource "proxmox_vm_qemu" "bastion0" {
    name = "bastion0"
    desc = "Dacadoo jumphost"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:6f:c0:8f:1e:4a"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"

    # provisioner "file" {
    #     content     = "${tls_private_key.id_rsa.private_key_pem}"
    #     destination = "/home/${self.ciuser}/.ssh/id_rsa"
    # }

    # provisioner "remote-exec" {
    #     inline = [
    #     "chmod 600 /home/${self.ciuser}/.ssh/id_rsa"
    #     ]
    # }
}

resource "proxmox_vm_qemu" "elastic0" {
    name = "elastic0"
    desc = "Elasticsearch with Logstash and Kibana"

    cores = 2
    sockets = 2
    memory = 4096

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 100
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:0e:1e:34:c7:23"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "kubernetes0" {
    name = "kubernetes0"
    desc = "Kubernets master"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:0c:21:fc:c7:9b"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "kubernetes1" {
    name = "kubernetes1"
    desc = "Kubernets worker"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:4f:82:ed:7a:27"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "mongodb0" {
    name = "mongodb0"
    desc = "MongoDB Node 0"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:d1:b5:ed:45:4f"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "mongodb1" {
    name = "mongodb1"
    desc = "MongoDB Node 1"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:f5:99:e8:9c:5c"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "mongodb2" {
    name = "mongodb2"
    desc = "MongoDB Node 2"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:94:38:0f:05:3d"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "consul0" {
    name = "consul0"
    desc = "Consul Node 0"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:65:50:da:ae:af"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "consul1" {
    name = "consul1"
    desc = "Consul Node 1"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:7a:5b:7a:25:f3"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "consul2" {
    name = "consul2"
    desc = "Consul Node 2"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:20:34:63:b8:1e"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "vault0" {
    name = "vault0"
    desc = "Vault Node 0"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:05:4e:c7:b6:9d"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "vault1" {
    name = "vault1"
    desc = "Vault Node 1"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:79:99:60:ba:ab"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

resource "proxmox_vm_qemu" "vault2" {
    name = "vault2"
    desc = "Vault Node 2"

    cores = 2
    sockets = 2
    memory = 2048

    bootdisk = "scsi0"
    scsihw = "virtio-scsi-pci"
    disk {
        id = 0
        size = 40
        type = "scsi"
        storage = "local-lvm"
        storage_type = "lvm"
    }

    network {
        id = 0
        model = "virtio"
        bridge = "vmbr0"
        macaddr = "02:c2:ea:eb:f0:b9"
    }

    target_node = "wolke4"
    pool = "dacadoo"
    clone = "CentOS7-GenericCloud"
    agent = 1

    os_type = "cloud-init"
    ipconfig0 = "ip=dhcp"
    ciuser = "root"
    cipassword = "root"
    sshkeys = "${tls_private_key.id_rsa.public_key_openssh}"
}

# locals {
#   ids = "[]"
# }

# data "templatefile"${file("${path.module}/inventory.tpl")}"
#   vars = {
#     ids = 
#   }
# }inventory_hostname



# resource "null_resource" "update_inventory" {

#     triggers = {
#         template = "${data.template_file.inventory.rendered}"
#     }

#     provisioner "local-exec" {
#         command = "echo '${templatefile("${path.module}/inventory.tpl", { ids = [proxmox_vm_qemu.bastion0.id, proxmox_vm_qemu.elastic0.id] })}' > inventory"
#     }
# }

locals {
    qemu_hosts = [
        {
            id: proxmox_vm_qemu.bastion0.id,
            fqdn: proxmox_vm_qemu.bastion0.name },
        {
            id: proxmox_vm_qemu.elastic0.id,
            fqdn: proxmox_vm_qemu.elastic0.name },
        {
            id: proxmox_vm_qemu.kubernetes0.id,
            fqdn: proxmox_vm_qemu.kubernetes0.name },
        {
            id: proxmox_vm_qemu.kubernetes1.id,
            fqdn: proxmox_vm_qemu.kubernetes1.name },
        {
            id: proxmox_vm_qemu.mongodb0.id,
            fqdn: proxmox_vm_qemu.mongodb0.name },
        {
            id: proxmox_vm_qemu.mongodb1.id,
            fqdn: proxmox_vm_qemu.mongodb1.name },
        {
            id: proxmox_vm_qemu.mongodb2.id,
            fqdn: proxmox_vm_qemu.mongodb2.name },
        {
            id: proxmox_vm_qemu.consul0.id,
            fqdn: proxmox_vm_qemu.consul0.name },
        {
            id: proxmox_vm_qemu.consul1.id,
            fqdn: proxmox_vm_qemu.consul1.name },
        {
            id: proxmox_vm_qemu.consul2.id,
            fqdn: proxmox_vm_qemu.consul2.name },
        {
            id: proxmox_vm_qemu.vault0.id,
            fqdn: proxmox_vm_qemu.vault0.name },
        {
            id: proxmox_vm_qemu.vault1.id,
            fqdn: proxmox_vm_qemu.vault1.name },
    ]
}

output "inventory" {
    value = "${templatefile("${path.module}/inventory.tpl", { hosts = local.qemu_hosts })}"
}

output "qemu_config" {
    value = "${templatefile("${path.module}/qemu-config.yml.tpl", { hosts = local.qemu_hosts })}"
}

output "ssh_key" {
    value = "${tls_private_key.id_rsa.private_key_pem}"
    sensitive   = true
}

output "ssh_keyfile" {
    value = "${local_file.ssh_key.filename}"
}