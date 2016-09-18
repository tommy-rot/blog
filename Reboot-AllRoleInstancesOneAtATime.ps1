#requires -Version 1 -Modules Azure, Microsoft.PowerShell.Utility
$InformationPreference = 'Continue'
$serviceName = 'rebootme'
$deployment = Get-AzureDeployment -ServiceName $serviceName -Slot Production
$instances = $deployment.RoleInstanceList 
Write-Information "Rebooting $($instances.count) instances in cloud service $($serviceName)"
$executionTimeTaken = Measure-Command -Expression {
  # reboot one instance at a time  
  foreach($instance in $instances)
  {
    Write-Information -MessageData "Rebooting instance $($instance.InstanceName)"
    $rebootTimeTaken = Measure-Command -Expression {
      Reset-AzureRoleInstance -ServiceName $serviceName -Slot Production -InstanceName $instance.InstanceName -Reboot  
      do
      {
        $instanceStatus = ((Get-AzureDeployment -ServiceName $serviceName -Slot Production).RoleInstanceList `
          | Where-Object -FilterScript {
            $_.InstanceName -eq $instance.InstanceName
        }).InstanceStatus
      }
      until ($instanceStatus -eq 'ReadyRole')
    }
    Write-Information -MessageData "Completed reboot of instance $($instance.InstanceName) in $($rebootTimeTaken.Minutes) minutes and $($rebootTimeTaken.Seconds) seconds"
  }
}
Write-Information -MessageData "Completed reboot of alls instances in $($executionTimeTaken.Minutes) minutes and $($executionTimeTaken.Seconds) seconds"

