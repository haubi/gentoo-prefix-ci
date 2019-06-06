
if ( ! $env:BUILD_ARTIFACTSTAGINGDIRECTORY ) { exit 1 }

if ( ! $env:AGENT_PROXYURL ) { exit 1 }

Invoke-Expression -Command ${PSScriptRoot}/setupv3.ps1

Set-Location -Path "$env:BUILD_ARTIFACTSTAGINGDIRECTORY"

$found = "none"
$oldest = "20190603"

$today = Get-Date

$year = $today.Year
$month = $today.Month
$day = $today.Day

Do {
    $YYYY = $year.toString("0000")
    Do {
        $MM = $month.toString("00")
        Do {
            $DD = $day.toString("00")
            Write-Output "trying $YYYY$MM$DD snapshot ..." | Out-Default
            try {
                Invoke-WebRequest -UseBasicParsing -Proxy $env:AGENT_PROXYURL -Uri "https://cygwin.com/snapshots/x86_64/cygwin1-$YYYY$MM$DD.dll.xz" -OutFile "cygwin1-$YYYY$MM$DD.dll.xz" | Out-Default
                Invoke-WebRequest -UseBasicParsing -Proxy $env:AGENT_PROXYURL -Uri "https://cygwin.com/snapshots/x86_64/cygwin-$YYYY$MM$DD.tar.xz" -OutFile "cygwin-$YYYY$MM$DD.tar.xz" | Out-Default
                $oldest = "$YYYY$MM$DD"
                Write-Output "unpack $YYYY$MM$DD snapshot ..." | Out-Default
                .\bin\xz.exe -d "cygwin1-$YYYY$MM$DD.dll.xz"
                .\bin\chmod.exe +x "cygwin1-$YYYY$MM$DD.dll"
                .\bin\cp.exe "bin/cygwin1.dll" "bin/cygwin1.dll.vanilla"
                .\bin\mv.exe -f "cygwin1-$YYYY$MM$DD.dll" "bin/cygwin1.dll"
                Write-Output " using $YYYY$MM$DD snapshot" | Out-Default
                $found = "$YYYY$MM$DD"
            } catch {
            }

            if ("$YYYY$MM$DD" -le $oldest) { Break }
        } While (--$day -ge 1)
        if ("$YYYY$MM$DD" -le $oldest) { Break }

        $day = 31;
    } While (--$month -ge 1)
    if ("$YYYY$MM$DD" -le $oldest) { Break }

    $month = 12;
} While (--$year -ge 2018)

if ( $found -eq "none" ) {
    Write-Out "downloading snapshot failed" | Out-Default
    exit 1
}
