variable "project" {
    type = string
    default = "projectName"
}

variable "hosts" {
    type = list
    default = ["node0", "node1"]
}

variable "vcpu" {
    type = number
    default = 1
}

variable "memory" {
    type = number
    default = 1048
}

variable "disk" {
    type = number
    default = "12000000000"
    description = "The size of the libvirt volume in bytes (default 12G)"
}

variable "cloudinit_iso" {
    type = string
    default = "commoninit.iso"
    description = "Destination of the cloud-init iso image"
}

variable "cloudinit_userdata" {
    type = string
    default = "cloud_init.cfg"
    description = "cloud-init userdata config"
}

variable "cloudinit_networkconfig" {
    type = string
    default = "network_config.cfg"
    description = "cloud-init network config file"
}

variable "baseimage" {
    type = string
    default = "https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
    description = "URL to a qcow2 image used as backing image for all VMs"
}

variable "baseimage_format" {
    type = string
    default = "qcow2"
    description = "Format of the baseimage used as backing image for all VMs"
}

variable "domain" {
    type = string
    default = ".libvirt"
    description = "Domain name for the virtual network"
}

variable "network" {
    type = string
    default = "10.66.3.0/24"
    description = "Subnet of the virtual network"
}