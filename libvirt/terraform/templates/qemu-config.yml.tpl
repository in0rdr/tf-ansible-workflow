---

%{ for host in hosts ~}
- fqdn: ${host.name}
  macaddr: ${tolist(host.network_interface)[0]["mac"]}
  ipv4: ${tolist(host.network_interface)[0]["addresses"][0]}
  id: ${host.id}
%{ endfor ~}