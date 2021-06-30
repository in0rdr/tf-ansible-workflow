resource "null_resource" "update_inventory" {
    triggers = {
        # when a host id changes
        host_ids = join(" ", concat(values(libvirt_domain.host)[*].id, values(libvirt_domain.hosts_type2)[*].id))
    }
    provisioner "local-exec" {
        # recreate ansible inventory
        command = "echo '${templatefile("${path.module}/templates/inventory.tpl", { hosts = merge(libvirt_domain.host, libvirt_domain.hosts_type2) })}' > ../ansible/inventory"
    }
    provisioner "local-exec" {
        # recreate mapping of qemu VM id to hostnames
        command = "echo '${templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = merge(libvirt_domain.host, libvirt_domain.hosts_type2) })}' > ../ansible/qemu-config.yml"
    }
}