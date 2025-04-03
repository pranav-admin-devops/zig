variable "rg_name" {
  default = "pranav-rg"
}
variable "rg_location" {
  default = "centralindia"
}
variable "size" {
  default = "Standard_F2"
}

variable "pip_name" {
  type    = string
  default = "linux-pip"
}

variable "ssh-port" {
  type    = number
  default = 22
}

variable "web-port" {
  type    = number
  default = 80
}

variable "is_prod" {
  type    = bool
  default = false
}

variable "rg" {
  type = map(string)
  default = {
    "pranav-prod"    = "centralindia"
    "pranav-dev"     = "centralindia"
    "pranav-test"    = "centralindia"
    "pranav-stage"   = "centralindia"
    "pranav-default" = "centralindia"
  }
}


variable "sg-rule" {
  type = list(object({
    name     = string
    priority = number
    port     = number
  }))
  default = [{
    name     = "allow-ssh"
    priority = 100
    port     = 22
    },
    {
      name     = "allow-http"
      priority = 101
      port     = 80
    },
    {
      name     = "allow-rdp"
      priority = 103
      port     = 3389
  }]
}


variable "subscription_id" {}  #TF_VAR
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "vm_size" {
  default = "Standard_F2"
}