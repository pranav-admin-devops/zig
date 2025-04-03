resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_virtual_network" "linux-vnet" {
  name                = "win-network"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5", "8.8.8.8"]
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_subnet" "linux-sub" {
  name                 = "win-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.linux-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_public_ip" "linux-pip" {
  name                = "win-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "linux-nic" {
  name                = "win-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.linux-sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.linux-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "linux-vm" {
  name                = "linux-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = "pranav"
  admin_password = "Pranav@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.linux-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  provisioner "file" {
    source = "log.txt"
    destination = "/tmp/log-backup.txt"
  }
  connection {
    type     = "ssh"
    user     = self.admin_username
    password = self.admin_password
    host     = self.public_ip_address
  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt update && sudo apt install nginx -y"
     ]   
  }
  provisioner "local-exec" {
    command = "echo http://${self.public_ip_address} > webserver_ip.txt"
  }
}

resource "azurerm_network_security_group" "linux-sg" {
  name                = "linux-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-internet"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "linix-association" {
  network_interface_id      = azurerm_network_interface.linux-nic.id
  network_security_group_id = azurerm_network_security_group.linux-sg.id
}
