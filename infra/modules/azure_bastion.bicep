param parName string
param parLocation string
param parVnetResourceId string
param parTags object = {}

module modBastionHost 'br/public:avm/res/network/bastion-host:0.6.1' = {
  name: 'bastionHostDeployment'
  params: {
    name: parName
    virtualNetworkResourceId: parVnetResourceId
    location: parLocation
    skuName: 'Standard'
    tags: parTags
  }
}
