

# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/coreos_ignition.html.markdown
# https://github.com/hashicorp/terraform-provider-ignition/blob/master/website/docs/index.html.markdown

#data "ignition_user" "root" {
#  name = "root"
#  ssh_authorized_keys = ["ssh-rsa ${chomp(tls_private_key.id_rsa.public_key_openssh)}"]
#}
#
#data "ignition_config" "user" {
#	users = [
#		data.ignition_user.root.rendered,
#	]
#}

# use templated .ign file, this is much easier than using yet another TF provider
resource "libvirt_ignition" "ignition" {
  name = "user.ign"
  pool = libvirt_pool.pool.name
#   content = data.ignition_config.user.rendered
content = "user.ign"
}
