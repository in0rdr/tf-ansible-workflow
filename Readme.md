# Proxmox VE (PVE) Terraform and Ansible Workflow

## 1 Preparation: Unicast MAC Address and TF Files
Generate a unicast MAC foreach VM:
```
network {
 ..
  macaddr = "A2:15:1C:5C:D8:31"
 ..
}
```

For instance, use a bash script to do so:
```
#!/bin/sh
function macaddr() {
 echo $RANDOM | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/'
}
```

Also, make any changes to the `.tf` files for your infrastructure.

## 2 Run Terraform

Run Terraform:
```
terraform plan
terraform apply
```

## 3 Terraform Outputs

Save following outputs:
```
terraform output inventory > inventory
terraform output qemu_config > qemu-config.yml

# inspect the name of the key file, see instructions below
terraform output ssh_keyfile
```

Adjust variables in `group_vars/all.yml`:
* `ssh.identity_file`: Output of `terraform output ssh_keyfile`
* also, set `ssh.proxy_jump` and `user` if needed
* make sure `pve_api` points to your compiled pve api binary (https://github.com/Telmate/proxmox-api-go)

Make sure that `id_rsa` matches both:
1. the name of `identity_file` in the file `ssh_config`
2. and `terraform output ssh_keyfile`

## 4 Ansible

Run playbook:
```
ansible-playbook playbook.yml -i inventory
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
terraform output ssh_key > id_rsa
```

Terraform takes care of writing this private key file the first time you run `terraform apply`, however, you might want to retrieve the key again without re-running Terraform.