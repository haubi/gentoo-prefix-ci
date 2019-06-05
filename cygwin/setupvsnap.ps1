
if ( ! $env:BUILD_ARTIFACTSTAGINGDIRECTORY ) { exit 1 }

if ( ! $env:AGENT_PROXYURL ) { exit 1 }

Invoke-Expression -Command ${PSScriptRoot}/setupv3.ps1

Set-Location -Path "$env:BUILD_ARTIFACTSTAGINGDIRECTORY"

$found = "20190603"

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
            Write-Output "trying $YYYY$MM$DD" | Out-Default
            try {
                $result = Invoke-WebRequest -UseBasicParsing -Proxy $env:AGENT_PROXYURL -Uri "https://cygwin.com/snapshots/x86_64/cygwin-$YYYY$MM$DD.tar.xz" -OutFile "cygwin-$YYYY$MM$DD.tar.xz"
                $found = "$YYYY$MM$DD"
                Write-Output "using snapshot from $found" | Out-Default
                .\bin\xz.exe -d -c "cygwin-$found.tar.xz" | .\bin\tar.exe -v -x -f - --strip-components=1 usr/bin/cygwin1.dll
            } catch {
                Write-Output "no $YYYY$MM$DD snapshot" | Out-Default
            }

            if ("$YYYY$MM$DD" -le $found) { Break }
        } While (--$day -ge 1)
        if ("$YYYY$MM$DD" -le $found) { Break }

        $day = 31;
    } While (--$month -ge 1)
    if ("$YYYY$MM$DD" -le $found) { Break }

    $month = 12;
} While (--$year -ge 2018)

