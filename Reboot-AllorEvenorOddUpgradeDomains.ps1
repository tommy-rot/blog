#requires -Version 2 -Modules Azure, Microsoft.PowerShell.Utility
$InformationPreference = 'Continue'
$serviceName = 'rebootme'

function Restart-RoleInstance
{
  param(
    [string]$serviceName,
    [ValidateSet('EvenUpgradeDomain','OddUpgradeDomain','AllUpgradeDomain')]
    [string]$UpgradeDomain
  )
  
  $deployment = Get-AzureDeployment -ServiceName $serviceName -Slot Production
  $instances = $deployment.RoleInstanceList 
  $rebootJobScriptBlock = {
    param(
      $serviceName,
      $Instance
    )
    $InformationPreference = 'Continue'
    Reset-AzureRoleinstance -ServiceName $serviceName -Slot Production -instanceName $instance.instanceName -Reboot
  }
  foreach($instance in $instances)
  {
    switch ($UpgradeDomain)
    {
      'EvenUpgradeDomain' 
      {
        if(([int]$instance.instanceUpgradeDomain % 2) -eq 0)
        {
          Start-Job -Name $instance.instanceName -ScriptBlock $rebootJobScriptBlock -ArgumentList $serviceName, $instance
          break
        }
      }
      'OddUpgradeDomain' 
      { 
        if(([int]$instance.instanceUpgradeDomain % 2) -eq 1)
        {
          Start-Job -Name $instance.instanceName -ScriptBlock $rebootJobScriptBlock -ArgumentList $serviceName, $instance
          break
        }
      }
      'AllUpgradeDomain' 
      {
        Start-Job -Name $instance.instanceName -ScriptBlock $rebootJobScriptBlock -ArgumentList $serviceName, $instance
      }
    }
  }
   
  Start-Sleep -Seconds 20   
  $rebootsComplete = $false
       
  do
  {
    $counter = 0
    $instanceStatus = ((Get-AzureDeployment -ServiceName $serviceName -Slot Production).RoleInstanceList).InstanceStatus
    foreach($status in $instanceStatus)
    {
      $counter++
      if($status -ne 'ReadyRole')
      {
        break
      }
      else
      {
        if($counter -eq $instanceStatus.Count)
        {
          $rebootsComplete = $true
        }
      }
    }
    Start-Sleep -Seconds 5 
  }
  until ($rebootsComplete)
}

Reboot-RoleInstance -ServiceName $serviceName -UpgradeDomain AllUpgradeDomain

'all upgrade domain reboots completed'

Restart-RoleInstance -ServiceName $serviceName -UpgradeDomain EvenUpgradeDomain
    
'even upgrade domain reboots completed'

Restart-RoleInstance -ServiceName $serviceName -UpgradeDomain OddUpgradeDomain

'odd upgrade domain reboots completed'