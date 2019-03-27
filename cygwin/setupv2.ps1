Set-PSDebug -Trace 2

if ( ! $env:BUILD_BINARIESDIRECTORY ) { exit 1 }

if ( ! $env:BUILD_ARTIFACTSTAGINGDIRECTORY ) { exit 1 }

if ( ! $env:AGENT_PROXYURL ) { exit 1 }

if ( ! $env:AGENT_WORKFOLDER ) { exit 1 }

Set-Location -Path $env:BUILD_BINARIESDIRECTORY

\\vboxsrv\cygwinv2\setup-x86_64.exe --version | Out-Default

\\vboxsrv\cygwinv2\setup-x86_64.exe --version | Out-Default

echo \\vboxsrv\cygwinv2\setup-x86_64.exe --arch x86_64 --delete-orphans --force-current --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-version-check --local-install --quiet-mode --local-package-dir \\vboxsrv\cygwinv2\ --root "$env:BUILD_ARTIFACTSTAGINGDIRECTORY" --upgrade-also --verbose --packages "wget,gcc-g++,rsync" | Out-Default
\\vboxsrv\cygwinv2\setup-x86_64.exe --arch x86_64 --delete-orphans --force-current --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-version-check --local-install --quiet-mode --local-package-dir \\vboxsrv\cygwinv2\ --root "$env:BUILD_ARTIFACTSTAGINGDIRECTORY" --upgrade-also --verbose --packages "wget,gcc-g++,rsync" | Out-Default

Copy-Item \\vboxsrv\cygwinv2\cygwin1.dll-2.11.2-gentoo-r0 $env:BUILD_ARTIFACTSTAGINGDIRECTORY\bin\cygwin1.dll
