Set-PSDebug -Trace 2

if ( ! $env:BUILD_BINARIESDIRECTORY ) { exit 1 }

if ( ! $env:BUILD_ARTIFACTSTAGINGDIRECTORY ) { exit 1 }

Set-Location -Path $env:BUILD_BINARIESDIRECTORY

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$cmds = 'Invoke-WebRequest'
$cmds += ' -UseBasicParsing'
$cmds += ' -Uri https://cygwin.com/setup-x86_64.exe'
$cmds += ' -OutFile setup-x86_64.exe'
if ( $env:AGENT_PROXYURL ) {
  $cmds += ' -Proxy $env:AGENT_PROXYURL'
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
if ( $env:AGENT_PROXYURL ) {
  $cmds += ' --proxy "$env:AGENT_PROXYURL"'
}
$cmds += ' --local-package-dir "$env:BUILD_BINARIESDIRECTORY"'
$cmds += ' --root "$env:BUILD_ARTIFACTSTAGINGDIRECTORY"'
$cmds += ' --upgrade-also'
$cmds += ' --verbose'
$cmds += ' --packages "wget,gcc-g++,rsync"'

$cmds += ' | Out-Default'
echo "$cmds"
Invoke-Expression "$cmds"

$cmds = 'Invoke-WebRequest'
$cmds += ' -UseBasicParsing'
$cmds += ' -Uri https://dev.gentoo.org/~haubi/cygwin-gentoo/x86_64/cygwin-3.0.7-gentoo-r0/cygwin1.dll'
$cmds += ' -OutFile "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\bin\cygwin1.dll"'
if ( $env:AGENT_PROXYURL ) {
  $cmds += ' -Proxy $env:AGENT_PROXYURL'
}

$cmds += ' | Out-Default'
echo "$cmds"
Invoke-Expression "$cmds"
