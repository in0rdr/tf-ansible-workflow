[local]
localhost ansible_connection=local

[qemu]
%{ for host in hosts ~}
${host.fqdn}
%{ endfor ~}