$TARGETFOLDER = "E:\"
$VM = "kali-linux"
$VMFOLDER = Join-Path $TARGETFOLDER $VM
$7ZIP = "C:\PROGRA~1\7-Zip\7z.exe"
$VMWare = "C:\PROGRA~2\VMware\VMware Player\vmplayer.exe"
$scriptFolder = "E:\buildscripts\"
$kaliScriptfolder = "/home/kali/scripts/"
$packedVM = "E:\kali-linux.7z"
$kaliSetupScript = $kaliScriptfolder+"kali_setup.sh"
$logfile = $kaliScriptfolder+"kali_setup.log"

$URL = "https://cdimage.kali.org/current/"
$WebResponseObj = Invoke-WebRequest -Uri $URL
$WebResponseObj.Links | Foreach {
    $FILE = $_.href

    if (Select-String -InputObject $FILE -Pattern "vmware-amd64") {
        if (Select-String -InputObject $FILE -Pattern ".torrent") { } else {
            $targetFile = Join-Path $TARGETFOLDER $FILE
            $DL = $URL+$FILE
            
            Write-host "[Info] Downloading", $DL, "to", $targetFile
            $dlobj = New-Object System.Net.WebClient
            $dlobj.DownloadFile($DL, $targetFile)
            
            Write-host "[Info] Generating hash of file", $targetFile
            Get-FileHash $targetFile -Algorithm SHA256 | Format-List

            if (Test-Path -Path $VMFOLDER) {
                Write-host "[Info] Deleting old VM in", $VMFOLDER
                Remove-Item $VMFOLDER -Recurse
            }

            Write-Host "[Info] Unpacking", $targetFile, "to", $VMFOLDER
            $command = "$7ZIP e $targetFile -o$VMFOLDER -y -bd"
            $out = Invoke-Expression $command

            $vmxFileObj = Get-ChildItem -Path $VMFOLDER "*.vmx"
            $vmxFile = Join-Path $VMFOLDER $vmxFileObj.Name
            Write-Host "[Info] Modifying Configfile", $vmxFile
            ((Get-Content -path $vmxFile -Raw) -replace 'memsize = "2048"','memsize = "8192"') | Set-Content -Path $vmxFile

            Write-Host "[Info] Starting Virtual Machine..."
            $VMX = Get-VMX -Path $VMFOLDER
            Start-VMX -VMXName $VMX.VMXName -config $vmxFile
            
            Write-Host "[Info] Waiting for VMTools to be started..."
            $VMXToolsState = ""
            while ($VMXToolsState.State -ne "running") {
                Start-Sleep -Seconds 1
                $VMXToolsState = Get-VMXToolsState -VMXName $VMX.VMXName -config $VMX.config
            }

            Start-Sleep -Seconds 15
            Write-Host "[Info] Transfering",$scriptFolder,"to",$kaliScriptfolder
            # Copy-VMXDirHost2Guest has a bug in the concationating part of pathes
            # it removes the \ from the windows path instead converting it into /
            #Copy-VMXDirHost2Guest -VMXName $VMX.VMXName -config $VMX.config -Sourcepath $scriptFolder -targetpath $kaliScriptfolder -Guestuser kali -Guestpassword kali
            Invoke-VMXBash -VMXName $VMX.VMXName -config $VMX.config -Guestuser kali -Guestpassword kali -Scriptblock "mkdir $kaliScriptfolder"
            Get-ChildItem -Path $scriptFolder "*.sh" | foreach {
                $fname = $_
                $srcFile = Join-Path $scriptFolder $fname
                $dstFile = $kaliScriptfolder+$fname
                write-host "Transfering $srcFile to $dstFile"
                Copy-VMXFile2Guest -VMXName $VMX.VMXName -config $VMX.config -Guestuser kali -Guestpassword kali -Sourcefile $srcFile -targetfile $dstFile
            }
            Start-Sleep -Seconds 5
            Invoke-VMXBash -VMXName $VMX.VMXName -config $VMX.config -Guestuser kali -Guestpassword kali -Scriptblock "chmod +x $kaliScriptfolder/*.sh"

            Write-Host "[Info] Starting $kaliSetupScript..."
            Write-Host "[Info] This will take a long time!"
            Invoke-VMXBash -VMXName $VMX.VMXName -config $VMX.config -Guestuser kali -Guestpassword kali -Scriptblock "echo kali | sudo -S $kaliSetupScript >$logfile"

            Write-Host "[Info] Stopping Virtual Machine..."
            $VMX = Get-VMX -Path $VMFOLDER
            Stop-VMX -VMXName $VMX.VMXName -config $vmxFile -Mode Soft
            
            Write-Host "[Info] Waiting for VMTools to be stopped..."
            $VMXToolsState = ""
            while ($VMXToolsState.State -eq "running") {
                Start-Sleep -Seconds 1
                $VMXToolsState = Get-VMXToolsState -VMXName $VMX.VMXName -config $VMX.config
            }

            # Deactivated - VMWare is encountering filesystem errors in the VMDK afterwards
            #Write-Host "[Info] Optimizing Disk..."
            #$vmxScsiDisk = Get-VMXScsiDisk -VMXName $VMX.VMXName -config $VMX.config
            #Optimize-VMXDisk -DiskPath $vmxScsiDisk.DiskPath -Disk $vmxScsiDisk.Disk

            if (Test-Path -Path $packedVM) {
                Write-host "[Info] Renaming old VM-Archive from", $packedVM, "to", $packedVM".bak"
                Rename-Item -Path $packedVM -NewName $packedVM".bak"
                Rename-Item -Path $packedVM".sha256" -NewName $packedVM".sha256.bak"
            }

            Write-Host "[Info] Packing", $VMFOLDER, "to", $packedVM
            $command = "$7ZIP a $packedVM $VMFOLDER"
            $out = Invoke-Expression $command

            Write-host "[Info] Generating hash of file", $packedVM
            $hash = Get-FileHash $targetFile -Algorithm SHA256
            write-host $hash.Hash
            Set-Content $packedVM".sha256" $hash.Hash
        }
    }
}
