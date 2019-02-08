Set-Location -Path $env:BUILD_BINARIESDIRECTORY

Invoke-WebRequest -Uri https://cygwin.com/setup-x86_64.exe -Proxy $env:AGENT_PROXYURL -OutFile setup-x86_64.exe

.\setup-x86_64.exe --version

$cygroot = $env:BUILD_ARTIFACTSTAGINGDIRECTORY

.\setup-x86_64.exe --arch x86_64 --delete-orphans --force-current --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-version-check --only-site --site http://mirror.easyname.at/cygwin/ --quiet-mode --proxy $env:AGENT_PROXYURL --local-package-dir $env:AGENT_WORKFOLDER --root $cygroot --upgrade-also --verbose --packages wget,gcc-g++,rsync
