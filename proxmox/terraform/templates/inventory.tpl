[local]
localhost ansible_connection=local

[qemu]
%{ for host in hosts ~}
${host.name}
%{ endfor ~}

[qemu:vars]
ansible_ssh_common_args='-F ../ssh/config'