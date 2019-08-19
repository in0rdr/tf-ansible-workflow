---

%{ for host in hosts ~}
- fqdn: ${host.name}
  id: ${split("/",host.id)[2]}
%{ endfor ~}