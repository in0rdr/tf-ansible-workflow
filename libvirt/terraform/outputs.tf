output "qemu_config" {
  value = templatefile("${path.module}/templates/qemu-config.yml.tpl", { hosts = merge({loadbalancer = libvirt_domain.host_loadbalancer}, {bootstrap = libvirt_domain.host_bootstrap}, libvirt_domain.host_master) })
}