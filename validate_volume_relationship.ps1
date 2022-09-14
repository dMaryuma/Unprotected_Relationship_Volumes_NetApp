Param (
   [Parameter(Mandatory=$true)]
   [String]$sourceCluster,
   [Parameter(Mandatory=$true)]
   [String]$destCluster,
   [Parameter(Mandatory=$true)]
   [String]$sourceUsername
   )
try{
    ## Save Password in file:
    #"SomePassword" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString| out-file c:\srcPassword
    # Save into script home run
    Get-Module -ListAvailable -name dataontap | Import-Module
    $srcPassword = Get-Content C:\srcPassword | ConvertTo-SecureString
    $srcCred = New-Object -TypeName System.Management.Automation.PSCredential $sourceUsername, $srcPassword
    $srcNC = Connect-NcController -Name $sourceCluster -HTTPS -Credential $srcCred -ErrorAction stop
}catch{Write-Host $_}

# Check relationship
$dstVservers = Get-NcVserverPeer -Controller $srcNC -ea stop| ?{$_.PeerCluster -like "$destCluster"} | select peervserver
$srcVolumes = get-ncvol -Controller $srcNC | ?{$_.VolumeStateAttributes.IsNodeRoot -notlike $true -and $_.VolumeStateAttributes.IsVserverRoot -notlike $true}
foreach ($vol in $srcVolumes){
    $DestMirror = Get-NcSnapmirrorDestination -Controller $srcNC -ea stop| ?{$_.SourceVolume -like $vol.name -and $_.SourceVserver -like $vol.Vserver}
    if ($DestMirror){
        if ($DestMirror.DestinationVserver -in $dstVservers.peervserver){
            Write-Host "Volume $($vol.name) on Vserver $($vol.Vserver) Does have relationship to cluster $destCluster" -ForegroundColor Green}
    }else{Write-Host "Volume $($vol.name) on Vserver $($vol.Vserver) DOES NOT HAVE relationship $destCluster!" -ForegroundColor Red}
}