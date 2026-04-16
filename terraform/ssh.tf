resource "random_pet" "ssh_key_name" {
    prefix = "ssh"
    separator = ""
}

resource "azapi_resource_action" "ssh_public_key_gen" {
    resource_id = azapi_resource.ssh_public_key.id
    type = "Microsoft.Compute/sshPublicKeys@2025-04-01"
    action = "generateKeyPair"
    method = "POST"

    response_export_values = [
        "publicKey",
        "privateKey"
    ]
}

resource "azapi_resource" "ssh_public_key" {
    type = "Microsoft.Compute/sshPublicKeys@2025-04-01"
    name = random_pet.ssh_key_name.id
    location = azurerm_resource_group.test-rg.location
    parent_id = azurerm_resource_group.test-rg.id
}

output "key_data" {
    value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}