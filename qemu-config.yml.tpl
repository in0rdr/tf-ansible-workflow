---

# qemu_hosts:
# %{ for host in hosts ~}
#   - fqdn: ${host.fqdn}
#     id:   ${split("/",host.id)[2]}
# %{ endfor ~}

%{ for host in hosts ~}
- fqdn: ${host.fqdn}
  id: ${split("/",host.id)[2]}
%{ endfor ~}