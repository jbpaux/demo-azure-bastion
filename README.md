
# Azure Bastion Demo

Small project to demonstrate Azure Bastion capabilities

## Content

- Deploy 2 peered VNets (Hub and Spoke) with NSG
- Deploy 2 VMs in Spoke VNet (one Windows and one Linux using SSH Key)
- Deploy one Key Vault to store SSH Private Key
- Deploy Azure Bastion in Hub VNet
- Add logging, NSG Flow logs etc.

## How to use

1. Clone the repo and the [Microsoft CARML module library](https://github.com/Azure/ResourceModules)

   ```bash
   git clone https://github.com/jbpaux/demo-azure-bastion.git
   git clone https://github.com/Azure/ResourceModules.git
   cd demo-azure-bastion
   ```

2. Create/Gather exisisting SSH Keys for your Ubuntu VM
3. Create a Resource Group in your subscription

   ```azcli
   az group create -n bastion-demo -l westeurope
   ```

4. Deploy the infra (you will be prompt for VMs username, Windows VM Password, and update ssh key files references)

   ```azcli
   $userID = $(az ad signed-in-user show --query id -o tsv)
   az deployment group create -g bastion-demo --template-file '.\main.bicep' --name bastiondeploy `
    -p keyData=@".\authorized_key.txt" `
    -p privateKeyData=@".\ssh-rsa.key" `
    -p userID=$userID
   ```

5. If you want you can install nginx in the Ubuntu VM and copy the index.html file to show tunneling capabilities
6. Use the `Connect-Bastion.azcli` file to see the different ways to connect to your VMs

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is open source and available under the [MIT License](LICENSE).
