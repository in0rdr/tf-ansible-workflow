# Terraform/Ansible Workflow for Libvirt

This repository describes a workflow which helps me to (re)create multiple similar VMs for testing purposes.

## 1 Preparation

### 1.1 Prerequisites
```
systemctl start libvirtd
```

Install [`cdrkit`](https://en.wikipedia.org/wiki/Cdrkit) for `mkisofs` (`genisoimage`) dependency:
* https://github.com/dmacvicar/terraform-provider-libvirt/commit/c1ed2ab5631e2c4971a4e207cb9e9294693463d3
* https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html

This is required to build the cloud-init image.

### 1.1 Environment Varibles
To debug Terraform runs, use:
```
#export TF_LOG=DEBUG
```

todo: `LIBVIRT_DEFAULT_URI` does not work as expected?

## 2 Run Terraform

Plan:
```
terraform plan
```

Run Terraform in two "stages":
```
# prepare cloud-init config file with ssh key
terraform apply -target=null_resource.update_cloudinit -auto-approve

# create the remaining resources (e.g., the cloud-init image from the config file prepared above)
terraform apply -auto-approve
```

* If the cloud-init config file is not prepared before starting the other resources, the cloud-init image will not contain the correct ssh public key.
* Terraform automatically recreates the Ansible inventory and the mapping of Qemu VM id to hostnames (see next section), whenever one of the hosts is added or removed (i.e., the Terraform `id` is changed).
* Terraform writes the SSH private key into the file `./ssh/id_rsa`.

### 2.1 Refresh SSH Keys
```
# create an active ssh (or console/vnc/spice) session
ssh root@$HOST -i ../ssh/id_rsa

# create new ssh key in the './terraform' directory on the local machine
terraform taint 'tls_private_key.id_rsa'
terraform apply -auto-approve

# update cloud-init image
terraform apply -target=libvirt_cloudinit_disk.commoninit -auto-approve

# reset cloud-init data on the remote $HOST
rm -rf /var/lib/cloud/ && poweroff

# re init cloud data
#sudo virsh shutdown $HOSTNAME
sudo virsh start $HOSTNAME

# known-host changed, remove old key
ssh-keygen -R $HOST_IP
```

Alternatively, use the [Ansible](#4-ansible) playbook and udpated the [`ssh_key`](./ansible/defaults/all.yml) and [`authorized_key`](./ansible/defaults/all.yml) to skip the re-init of cloud data (no reboot).

## 3 Terraform Outputs

If the Ansible inventory or the mapping of Qemu VM id to hostname needs to be updated manually, the values can be re
trieved from the Terraform output any time:
```
terraform output inventory > ../ansible/inventory
terraform output qemu_config > ../ansible/qemu-config.yml
```

Inspect the name of the ssh key file:
```
terraform output ssh_private_keyfile
```

## 4 Ansible

### 4.1 Preconditions and Preparations
Ansible depends on the following files written by Terraform, see section "2 Run Terraform" and "3 Terraform Outputs":
1. `./ansible/inventory`: The Ansible inventory containing a local connection and one group of remote hosts
2. `./ansible/qemu-config.yml`: The mapping of Qemu VM ids to hostnames

Adjust variables in `./ansible/group_vars/all.yml` (use/cp `./ansible/defaults/all.yml` as template):
* `ssh_identity_file`: Relative path name to the SSH privat key (output of `terraform output ssh_private_keyfile`)
* Set `ssh_proxy_jump` and `ansible_user` if necessary
* Define `additional_users` as needed

### 4.2 Run Ansible to Build the SSH Config

The Ansible playbook runst the following tasks:
1. Build the `./ssh/ssh_config` based on the information in the file `./ansible/qemu-config.yml` created with Terraform
2. Build an optional `./dnsmasq.conf` to enable static ip in dnsmasqs built-in dhcp subsystem
3. Add additional users `additional_users`

The playbook will set the hostname and restart networking inside the VMs, such that the hostnames are published to the DNS server and all hosts are known/addressable by name.

Run the playbook:
```
# build ssh config from qemu-config.yml
ansible-playbook playbook.yml -i inventory -l local

# if required, build a dnsmasq snippet for static ip allocation (dhcp)
# the snippet is written to the file './dnsmasq.conf'
ansible-playbook dhcp-static-hosts.yml -i inventory -l local

# set hostname, restart networking, modify users and keys
ansible-playbook playbook.yml -i inventory -l qemu
```

If you choose an unprivileged `ansible_user` to reach the VMs, you may need to specfiy a privileged user to run some of the tasks. Specifically, restarting the network and modifying users requires more privileges. Further, you might not want to touch all hosts and limit the execution to a specific host:
```
# set hostname, restart networking, modify users and keys as privileged user on "myhost"
ansible-playbook playbook.yml -i inventory -l myhost -e ansible_user=root
```

### 4.3 Update Known Hosts

To prepare the local host for consecutive SSH connections, you might want to update you local `./ssh/known_hosts` file as follows:
```
# update known hosts locally and confirm
ansible-playbook update-known-hosts.yml -i inventory
```

Alternatively, use the following commands:
```
cd ansible

# remove previous hosts from known hosts
for ip in $(cat qemu-config.yml | grep ip4 | awk '{print $2}'); do ssh-keygen -R $ip; done

# update known hosts and confirm
for host in $(cat qemu-config.yml | grep fqdn | awk '{print $3}'); do ssh -F ../ssh/config $host exit; done
```

## 5 Troubleshooting, Tips & Tricks

### 5.1 Delete and Recreate Hosts
You can either taint the Terraform resources or delete them with `virsh`. To taint resource "cka01":
```
terraform taint 'libvirt_domain.host["cka01"]'
```

Afterwards, re-apply to restore the Terraform state:
```
terraform apply
```

To delete with `virsh` (this will mess up the Terraform state):
```
sudo virsh destroy cka01
```

To only recreate parts of the infrastructure, choose an appropriate Terraform `target`:
```
terraform apply -target="libvirt_domain.host[\"cka01\"]" -target="libvirt_domain.host[\"cka02\"]"
```


### 5.2 Retrive private key without running Terraform
If needed, retrieve the SSH key (again) without re-applying changes:
```
terraform output ssh_private_key > ../ssh/id_rsa
```

Terraform takes care of writing this private key file the first time you run `terraform apply`, however, you might want to retrieve the key again without re-running Terraform.

### 5.3 Start Libvirt Domains
The plan will fail if you don't have the domains started (problem with `qemu-config.yml.tpl`):
```
Call to function "templatefile" failed:
./templates/qemu-config.yml.tpl:6,48-51: Invalid index; The given key does not
identify an element in this collection value..
```

---
## Dependencies
* Terraform provider for Libvirt: https://github.com/dmacvicar/terraform-provider-libvirt