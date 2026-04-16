resource "azurerm_resource_group" "test-rg" {
    location = var.location
    name = "rg-test"
    
}

resource "azurerm_virtual_network" "test-net" {
    location = var.location
    name = "vnet-test"
    resource_group_name = azurerm_resource_group.test-rg.name
    address_space = [ "10.0.0.0/16" ]   
}

resource "azurerm_subnet" "subnet-one" {
    name = "subnet-test"
    resource_group_name = azurerm_resource_group.test-rg.name
    virtual_network_name = azurerm_virtual_network.test-net.name
    address_prefixes = [ "10.0.0.0/24" ]
    default_outbound_access_enabled = false
}

resource "azurerm_subnet" "subnet-bastion" {
    name = "AzureBastionSubnet"
    resource_group_name = azurerm_resource_group.test-rg.name
    virtual_network_name = azurerm_virtual_network.test-net.name
    address_prefixes = [ "10.0.1.0/26" ]
    default_outbound_access_enabled = false
}

resource "azurerm_public_ip" "pip-bastion" {
    allocation_method = "Static"
    location = var.location
    name = "pip-bastion"
    resource_group_name = azurerm_resource_group.test-rg.name
    sku = "Standard"
}

resource "azurerm_public_ip" "pip-natgateway" {
    allocation_method = "Static"
    location = var.location
    name = "pip-natgateway"
    resource_group_name = azurerm_resource_group.test-rg.name
    sku = "Standard"
}

resource "azurerm_bastion_host" "test-bastion" {
    location = var.location
    name = "bastion-test"
    resource_group_name = azurerm_resource_group.test-rg.name
    dns_name = "bastion-test"
    tunneling_enabled = true

    ip_configuration {
        name = "bastion-ip-config"
        subnet_id = azurerm_subnet.subnet-bastion.id
        public_ip_address_id = azurerm_public_ip.pip-bastion.id
    }
}

resource "azurerm_nat_gateway" "test-nat" {
    location = var.location
    name = "nat-test"
    resource_group_name = azurerm_resource_group.test-rg.name
    sku_name = "Standard"    
}

resource "azurerm_nat_gateway_public_ip_association" "pip-nat-assoc" {
    nat_gateway_id = azurerm_nat_gateway.test-nat.id
    public_ip_address_id = azurerm_public_ip.pip-natgateway.id    
}

resource "azurerm_subnet_nat_gateway_association" "test-nat-assoc" {
    nat_gateway_id = azurerm_nat_gateway.test-nat.id
    subnet_id = azurerm_subnet.subnet-one.id    
}

resource "azurerm_network_interface" "test-nic" {
    location = var.location
    name = "nic-test"
    resource_group_name = azurerm_resource_group.test-rg.name
 
    ip_configuration {
        name = "ip-config-test"
        private_ip_address_allocation = "Dynamic"
        subnet_id = azurerm_subnet.subnet-one.id
    }
}

resource "azurerm_linux_virtual_machine" "test-vm" {
    location = var.location
    name = "vm-test"
    network_interface_ids = [ azurerm_network_interface.test-nic.id ]
    resource_group_name = azurerm_resource_group.test-rg.name
    size = "Standard_D4ads_v6"
    
    os_disk {
        name = "osdisk-test"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb = 256
    }
    
    source_image_reference {
      publisher = "Canonical"
      offer = "ubuntu-24_04-lts"
      sku = "server"
      version = "latest"
    }

    admin_username = "ladmin"

    admin_ssh_key {
        username = "ladmin"
        public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }

    custom_data = base64encode(file("${path.module}/scripts/ms-apt-repo.yaml"))
}