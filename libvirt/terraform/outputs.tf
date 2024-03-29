output "inventory" {
    value = templatefile("${path.module}/templates/inventory.tpl", { hosts = local.all_hosts })
}

output "qemu_config" {
    value = templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = local.all_hosts })
}

output "ssh_private_key" {
    value = tls_private_key.id_rsa.private_key_pem
    sensitive   = true
}

output "ssh_private_keyfile" {
    value = local_sensitive_file.ssh_private_key.filename
}

output "ssh_public_key" {
    value = tls_private_key.id_rsa.public_key_openssh
    sensitive   = true
}

output "ssh_public_keyfile" {
    value = local_sensitive_file.ssh_public_key.filename
}
