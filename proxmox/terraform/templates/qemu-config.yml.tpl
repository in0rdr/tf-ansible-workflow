---

%{ for host in hosts ~}
- fqdn: ${host.name}
  macaddr: ${tolist(host.network)[0]["macaddr"]}
  id: ${split("/",host.id)[2]}
%{ endfor ~}