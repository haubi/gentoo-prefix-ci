Set-PSDebug -Trace 2

Get-Location

if ( ! $env:TEMP ) { exit 1 }

Set-Location -Path $env:TEMP

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$cmds = 'Invoke-WebRequest'
$cmds += ' -UseBasicParsing'
$cmds += ' -Uri https://cygwin.com/setup-x86_64.exe'
$cmds += ' -OutFile setup-x86_64.exe'
if ( $env:https_proxy ) {
  $cmds += ' -Proxy $env:https_proxy'
}

$cmds += ' | Out-Default'
echo "$cmds"
Invoke-Expression "$cmds"

.\setup-x86_64.exe --version | Out-Default

$cmds = './setup-x86_64.exe'
$cmds += ' --arch x86_64'
$cmds += ' --delete-orphans'
$cmds += ' --force-current'
$cmds += ' --no-admin'
$cmds += ' --no-desktop'
$cmds += ' --no-replaceonreboot'
$cmds += ' --no-shortcuts'
$cmds += ' --no-startmenu'
$cmds += ' --no-version-check'
$cmds += ' --only-site'
$cmds += ' --site http://mirror.easyname.at/cygwin/'
$cmds += ' --quiet-mode'
if ( $env:https_proxy ) {
  $cmds += ' --proxy "$env:https_proxy"'
}
$cmds += ' --local-package-dir "$env:TEMP"'
$cmds += ' --root "C:/cygwin64"'
$cmds += ' --upgrade-also'
$cmds += ' --verbose'
$cmds += ' --packages "wget,gcc-g++,rsync"'

$cmds += ' | Out-Default'
echo "$cmds"
Invoke-Expression "$cmds"
