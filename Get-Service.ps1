$services = get-service
$processes = get-process
$objects = @()
$noProcessButRunnings = @()
foreach($service in $services){
  foreach ($process in $processes){
    if ($process.Name -eq $service.Name){
      $object = New-Object -TypeName PSObject 
      $object | Add-Member -MemberType NoteProperty -Name Service -Value $service.Name 
      $object | Add-Member -MemberType NoteProperty -Name PID -Value $process.Id
      $objects += $object
      
    }
  }
      $noProcessButRunning = New-Object -TypeName PSObject 
      $noProcessButRunning | Add-Member -MemberType NoteProperty -Name Service -Value $service.Name 
      $noProcessButRunning | Add-Member -MemberType NoteProperty -Name PID -Value ''
      $noProcessButRunnings += $noProcessButRunning
}

$objects
$noProcessButRunnings