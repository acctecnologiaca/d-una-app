$targets = @('dart', 'node', 'adb', 'python', 'chromedriver')
Get-CimInstance Win32_Process | Where-Object { 
    $targets -contains $_.Name.Replace('.exe','') -and -not (Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue) 
} | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force
    Write-Host "Eliminado proceso huerfano: $($_.Name) (PID $($_.ProcessId))" 
}