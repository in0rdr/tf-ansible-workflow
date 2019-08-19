variable "hosts" {
    type = "list"
    default = ["node0", "node1"]
}

variable "macaddr" {
    type = "map"
    default = {
        node0 = "02:e6:df:96:00:d6"
        node1 = "02:98:f7:29:3a:82"
    }
}

variable "pool" {
    type = string
    default = "pool-name"
}

variable "cores" {
    type = number
    default = 1
}

variable "sockets" {
    type = number
    default = 1
}

variable "memory" {
    type = number
    default = 2048
}

variable "disk" {
    type = number
    default = 30
}

variable "target_node" {
    type = string
    default = "node-name"
}

variable "clone" {
    type = string
    default = "CentOS7-GenericCloud"
}