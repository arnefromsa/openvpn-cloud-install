$cloudProvider = ""
$subscriptionName = ""
$subscriptionId = ""
$resourceGroupName = ""

do 
{
    Clear-Host
    Write-Host ""
    Write-Host "========== OpenVPN Cloud Installer =========="
    Write-Host "What Cloud Provider are you targeting ?"
    Write-Host "1 : Azure"
    Write-Host "2 : Amazon Web Services(AWS)"
    $selection = Read-Host "Please make a selection: "
    switch ($selection)
     {
         '1' {
            $cloudProvider = "Azure"
         } '2' {
             $cloudProvider = "AWS"
         } 
    }
}
until ($selection -eq '1' -or $selection -eq '2')
Write-Host ""
Write-Host ("Setting up with "+$cloudProvider)

if($cloudProvider = "Azure") 
{
    #Test if module Az is installed
    if (Get-Module -ListAvailable -Name Az) {
        Write-Host "Azure Az module already installed"
    } 
    else {
        Install-Module Az -Force -AllowClobber
    }

    Write-Host ""
    Write-Host "You will now be requested to log into your Azure account"
    pause    
    Login-AzAccount -InformationAction SilentlyContinue
    Clear-Host
    Write-Host "Retrieving subscription list ..."
    # Get subscription to use
    $subscriptionList = Get-AzSubscription -InformationAction SilentlyContinue
    Clear-Host
    Write-Host "Now, you have to select which Azure Subscription to use : "
    do{
        $counter = 1
        foreach($subscription in $subscriptionList)
        {
            Write-host ($counter.ToString()+" : "+$subscription.Name+" ("+$subscription.Id+")")
            $counter = $counter + 1
        }
        $selection = Read-Host "Please make a selection: "
    }
    until ([int]$selection -lt $counter )
    $subscriptionName = $subscriptionList[[int]$selection-1].Name
    $subscriptionId =  $subscriptionList[[int]$selection-1].Id
    
    Clear-Host
    Write-Host "Retrieving Azure Subscription locations ..."
    $locations = Get-AzLocation
    Clear-Host

    Write-Host ("Cloud Provider : "+$cloudProvider)
    Write-Host ("Subscription : "+$subscriptionName+" ("+$subscriptionId+")")
    Write-Host ""
    
    $counter = 1
    foreach($location in $locations) 
    {
        Write-Host ($counter.ToString()+" : "+$location.Location)
        $counter = $counter+1
    }
    $selection = Read-Host "Provide hosting location ?" 
    $resourceLocation = $locations[[int]$selection-1].Location

    Clear-Host
    Write-Host ("Cloud Provider : "+$cloudProvider)
    Write-Host ("Subscription : "+$subscriptionName+" ("+$subscriptionId+")")
    Write-Host ("Resource Location : "+$resourceLocation)
    Write-Host ""

    $resourceGroupName = Read-Host "Please provide a resource group name to host your cloud resources in "


    ##### RESOURCE CREATION START #####
    Clear-Host
    Write-Host ("Cloud Provider : "+$cloudProvider)
    Write-Host ("Subscription : "+$subscriptionName+" ("+$subscriptionId+")")
    Write-Host ("Resource Location : "+$resourceLocation)
    Write-Host ("Resource Group Name : "+$resourceGroupName)
    Write-Host ""    
    Write-Host "*********************************"
    Write-Host "Resource Creation will now start"
    Write-Host "*********************************"
    Set-AzContext -Subscription $subscriptionId -InformationAction SilentlyContinue
    Write-Host "Creating Resource Group..."
    $resourceGroupObject = New-AzResourceGroup -Name $resourceGroupName -Location australiaeast -InformationAction SilentlyContinue
    if($resourceGroupObject.ProvisioningState -eq "Succeeded") 
    {
        Write-Host "... Resource Group Created"
    }
    $adminPassword = Read-Host -AsSecureString "Password for VM "

    Write-Host "Creating Virtual Environment..."
    $deployment = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateParameterFile ./arm/parameters.json -TemplateFile ./arm/template.json -adminUsername "azureuser" -adminPassword $adminPassword -virtualMachineName $resourceGroupName -virtualMachineComputerName $resourceGroupName -virtualMachineRG $resourceGroupName
    if($deployment.ProvisioningState -eq "Succeeded")
    {
        Write-Host "... Resources Created"
    }

}
