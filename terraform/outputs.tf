output "inventory" {
    value = "${templatefile("${path.module}/templates/inventory.tpl", { hosts = proxmox_vm_qemu.host })}"
}

output "qemu_config" {
    value = "${templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = proxmox_vm_qemu.host })}"
}

output "ssh_key" {
    value = "${tls_private_key.id_rsa.private_key_pem}"
    sensitive   = true
}

output "ssh_keyfile" {
    value = "${local_file.ssh_key.filename}"
}