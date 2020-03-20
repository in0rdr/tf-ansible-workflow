---

%{ for host in hosts ~}
- fqdn: ${host.name}
  macaddr: ${tolist(host.network_interface)[0]["mac"]}
  ip4: ${tolist(host.network_interface)[0]["addresses"][0]}
  id: ${host.id}
%{ endfor ~}