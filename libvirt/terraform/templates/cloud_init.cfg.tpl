#cloud-config
# vim: syntax=yaml
#
# ***********************
# 	---- for more examples look at: ------
# ---> https://cloudinit.readthedocs.io/en/latest/topics/examples.html
# ******************************
#
# This is the configuration syntax that the write_files module
# will know how to understand. encoding can be given b64 or gzip or (gz+b64).
# The content will be decoded accordingly and then written to the path that is
# provided.
#
# Note: Content strings here are truncated for example purposes.
ssh_pwauth: True
disable_root: False
chpasswd:
  list:
    root:root
  expire: False
ssh_authorized_keys:
  - ${public_key}