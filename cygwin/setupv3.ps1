Set-PSDebug -Trace 2

if ( ! $env:BUILD_BINARIESDIRECTORY ) { exit 1 }

if ( ! $env:BUILD_ARTIFACTSTAGINGDIRECTORY ) { exit 1 }

if ( ! $env:AGENT_PROXYURL ) { exit 1 }

if ( ! $env:BUILD_BINARIESDIRECTORY ) { exit 1 }

Set-Location -Path $env:BUILD_BINARIESDIRECTORY

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -UseBasicParsing -Uri https://cygwin.com/setup-x86_64.exe -Proxy $env:AGENT_PROXYURL -OutFile setup-x86_64.exe

.\setup-x86_64.exe --version | Out-Default

echo .\setup-x86_64.exe --arch x86_64 --delete-orphans --force-current --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-version-check --only-site --site http://mirror.easyname.at/cygwin/ --quiet-mode --proxy "$env:AGENT_PROXYURL" --local-package-dir "$env:BUILD_BINARIESDIRECTORY" --root "$env:BUILD_ARTIFACTSTAGINGDIRECTORY" --upgrade-also --verbose --packages "wget,gcc-g++,rsync" | Out-Default
.\setup-x86_64.exe --arch x86_64 --delete-orphans --force-current --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-version-check --only-site --site http://mirror.easyname.at/cygwin/ --quiet-mode --proxy "$env:AGENT_PROXYURL" --local-package-dir "$env:BUILD_BINARIESDIRECTORY" --root "$env:BUILD_ARTIFACTSTAGINGDIRECTORY" --upgrade-also --verbose --packages "wget,gcc-g++,rsync" | Out-Default

echo Invoke-WebRequest -UseBasicParsing -Uri https://dev.gentoo.org/~haubi/cygwin-gentoo/x86_64/cygwin-3.0.7-gentoo-r0/cygwin1.dll -Proxy $env:AGENT_PROXYURL -OutFile "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\bin\cygwin1.dll"
Invoke-WebRequest -UseBasicParsing -Uri https://dev.gentoo.org/~haubi/cygwin-gentoo/x86_64/cygwin-3.0.7-gentoo-r0/cygwin1.dll -Proxy $env:AGENT_PROXYURL -OutFile "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\bin\cygwin1.dll"
