# Terraform/Ansible Workflow on Proxmox VE (PVE)

This repository describes a workflow which helps me to (re)create multiple similar VMs for testing purposes.

## 1 Preparation
### 1.1 PVE Varibles
Define authentication variables for the [PVE API](https://github.com/Telmate/proxmox-api-go). The Terraform provider relies on the PVE API which requires you to defined the following environment variables:
```
export PM_USER=test@pve
export PM_PASS="secret"
export PM_API_URL="https://cloud.proxmox.org/api2/json"
#export TF_LOG=DEBUG
```

### 1.2 Unicast MAC Addresses and Terraform Variables
Generate a unicast MAC foreach VM. For instance, use a bash script to do so:
```
#!/bin/sh
function macaddr() {
 echo $RANDOM | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/'
}
```

Use environment variables or create a new file `./terraform/terraform.tfvars` to specify the details for the VMs (see also `./terraform/variables.tf`). Among other variables, insert the mac addresses from above:
```
# terraform.tfvars
hosts = ["host0"]
macaddr = {
    host0 = "02:a2:1d:38:31:1c"
}
```

## 2 Run Terraform

Run Terraform:
```
terraform plan
terraform apply
```

* Terraform automatically recreates the Ansible inventory and the mapping of Qemu VM id to hostnames (see next section), whenever one of the hosts is added or removed (i.e., the Terraform `id` is changed).
* Terraform writes the SSH private key into the file `./ssh/id_rsa`.

## 3 Terraform Outputs

If the Ansible inventory or the mapping of Qemu VM id to hostname needs to be updated manually, the values can be retrieved from the Terraform output any time:
```
terraform output inventory > ../ansible/inventory
terraform output qemu_config > ../ansible/qemu-config.yml

# inspect the name of the key file, see instructions below
terraform output ssh_private_keyfile
```

## 4 Ansible

### 4.1 Preconditions and Preparations
Ansible depends on the following files written by Terraform, see section "2 Run Terraform" and "3 Terraform Outputs":
1. `./ansible/inventory`: The Ansible inventory containing a local connection and one group of remote hosts
2. `./ansible/qemu-config.yml`: The mapping of Qemu VM ids to hostnames

Adjust variables in `./ansible/group_vars/all.yml`:
* `ssh_identity_file`: Relative path name to the SSH privat key (output of `terraform output ssh_private_keyfile`)
* Set `ssh_proxy_jump` and `ansible_user` if necessary
* Ensure `pve_api` points to your compiled PVE API binary
* Define `additional_users` as needed

### 4.2 Run Ansible

The Ansible playbook runst the following tasks:
1. Retrieve the IP of the VMs via Qemu guest agent
2. Write the IP to the file `./ansible/qemu-config.yml`
3. Build the `./ssh/ssh_config` based on the information in the previous step
4. Add additional users `additional_users`

It is necessary to run ansible, because the IP address of the hosts cannot be retrieved by Terraform (the PVE provider is not mature enough yet). Therefore, we need to retrieve the IP addresses of the hosts via the Qemu guest agents running in the VMs. This process is automated and it will amend the IPs to the file `./ansible/qemu-config.yml`. Furthermore, the playbook will set the hostname and restart networking inside the VMs, such that then hostnames is published to the DNS server and the hosts are known/addressable by name.

Run the playbook:
```
# build ssh config from qemu-config.yml
ansible-playbook playbook.yml -i inventory -l local
# set hostname, restart networking, modify users and keys
ansible-playbook playbook.yml -i inventory -l qemu
```

If you choose an unprivileged `ansible_user` to reach the VMs, you may need to specfiy a privileged user to run some of the tasks. Specifically, restarting the network and modifying users requires more privileges. Further, you might not want to touch all hosts and limit the execution to a specific host:
```
# set hostname, restart networking, modify users and keys as privileged user on "myhost"
ansible-playbook playbook.yml -i inventory -l myhost -e ansible_user=root
```


## 5 Troubleshooting, Tips & Tricks

### 5.1 Recreate
To recreate some of the infra:
```
terraform apply -target="proxmox_vm_qemu.mongodb2" -target="proxmox_vm_qemu.mongodb1"
```

### 5.2 Delete
To delete some of the the infra:
```
~/gocode/src/github.com/Telmate/proxmox-api-go/proxmox-api-go destroy 116
terraform refresh
```

### 5.3 Retrive private key without running Terraform
If needed, retrieve the SSH key (again) without re-applying changes:
```
terraform output ssh_private_key > ../ssh/id_rsa
```

Terraform takes care of writing this private key file the first time you run `terraform apply`, however, you might want to retrieve the key again without re-running Terraform.

---
## Dependencies
* PVE API: https://github.com/Telmate/proxmox-api-go
* Terraform provider for Proxmox: https://github.com/Telmate/terraform-provider-proxmox

