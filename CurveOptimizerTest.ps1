$core=$args[0]
$step=[int]$args[1]
if ($step -eq 0) { $step = 10 }
$delay = 0
$start = Get-Date -format "dd.MM.yyyy HH:mm:ss"
Add-Content CurveOptimizerTest.log "dummy"
Remove-item CurveOptimizerTest.log
Add-Content CurveOptimizerTest.log "Loop Started at $start with init step $step ms"  
Start-Process -WindowStyle Minimized -FilePath "Cinebench.exe" -ArgumentList "g_CinebenchCpu1Test=true","g_CinebenchMinimumTestDuration=1800"
get-process Cinebench | % { $_.ProcessorAffinity = 1 }

$logic_cpu = (Get-CIMInstance -Class 'CIM_Processor').NumberOfLogicalProcessors
$cores_cpu = (Get-CIMInstance -Class 'CIM_Processor').NumberOfCores

$hyper_cpu = $logic_cpu + $cores_cpu - 1
$cores = 0 .. $hyper_cpu
$single_cpu = 1

#Fill cores array with bitmask HT ST ST ...
for ($i = 0; $i -le $hyper_cpu; $i++) {
   if (($i % 3) -eq 0) {
      $cores[$i] = $single_cpu + $single_cpu * 2
      $i = $i++
   } else {
      $cores[$i] = $single_cpu
      $single_cpu = $single_cpu * 2
   }
}
#Sort workaround ST ST HT
$cores = $cores | Sort-Object

Write-Host "                                                                                                                        " -ForegroundColor black -BackgroundColor white
Write-Host " AMD Curve Optimizer Test v0.0.1 (alpha) by exceeder                                                                    " -ForegroundColor black -BackgroundColor white
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "                                                                                                                        " -ForegroundColor black -BackgroundColor white
Write-Host " Test configuration combining affinition to logical cores (T0, T1) and whole core (HyperThreading T1+T2) in the loop.   " -ForegroundColor black -BackgroundColor white
Write-Host " It leads also to mid range load which will test the whole curve, not only the maximum load (hope so).                  " -ForegroundColor black -BackgroundColor white
Write-Host " In case of reboot or Cinebench's 23 error, modify (negative) magnitude in AMD Curve Optimizer (bios).                  " -ForegroundColor black -BackgroundColor white
Write-Host " Last testing Core is in the CurveOptimizerTest.log (same folder as this cool script).                                  " -ForegroundColor black -BackgroundColor white
Write-Host " After the finished loop, delay period between switching is increased little (can be tuned in .cmd +10ms).              " -ForegroundColor black -BackgroundColor white
Write-Host " Touching the PC during the test isn't recommended (can leads to false - positivive)!                                   " -ForegroundColor black -BackgroundColor white
Write-Host " Another Core (without load) can fail too! It's not perfect!                                                            " -ForegroundColor black -BackgroundColor white
Write-Host " Cinebench 23 and SSD drive required + you can watch frequency and switching in hwinfo.                                 " -ForegroundColor black -BackgroundColor white                                                  
Write-Host " If you wanna see Cinebench's result, start and run 30 min CPU (Single Core) before the script.                         " -ForegroundColor black -BackgroundColor white                                                  
Write-Host " Currently, only all core loop supported, single core tunning will be in future relases.                                " -ForegroundColor black -BackgroundColor white                                                  
Write-Host "                                                                                                                        " -ForegroundColor black -BackgroundColor white                                                  
Write-Host ""
Write-Host " Detected Cores: $cores_cpu"
Write-Host " Detected Threads: $logic_cpu"
Write-Host " Initial switching step: $step ms"
Write-Host ""

do {
  $cpu = 0
  $logic = 0
  ForEach ($core in $cores) {
    $core_binary = [convert]::tostring($core, 2).padleft($logic_cpu, '0')
    if (($core % 3) -eq 0) {
      Write-Progress -Activity "Setting Cinebench's affinity to Core $cpu HT" -Status $core_binary
      Add-Content CurveOptimizerTest.log "Setting Cinebench's affinity to Core $cpu HT"
      $cpu++
      $logic = 0
    } else {
      Write-Progress -Activity "Setting Cinebench's affinity to Core $cpu T$logic" -Status $core_binary
      Add-Content CurveOptimizerTest.log "Setting Cinebench's affinity to Core $cpu T$logic"
      $logic++
    }
    Start-Sleep -m 100 
    if((get-process "Cinebench" -ea SilentlyContinue) -eq $Null) {   
      $complete = 1
      break    
    } else {
      get-process Cinebench | % { $_.ProcessorAffinity = $core }
    }
    Start-Sleep -m $delay
  }
  $delay = $delay + $step
} while ($complete -ne 1)
Write-Host "Test loop complete"
Add-Content CurveOptimizerTest.log "Test loop completed"
