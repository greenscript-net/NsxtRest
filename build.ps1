$tmpWorkingFolder = New-Item -Path (New-TemporaryFile).DirectoryName -Type Directory -Name "NsxtRest"

Copy-Item ./src/NsxtRest.psd1 $tmpWorkingFolder
Copy-Item ./src/NsxtRest.psm1 $tmpWorkingFolder

Import-Module $tmpWorkingFolder -Force

# Remove-Item $tmpWorkingFolder -Confirm:$false -Force