##############################################################################################
# Author: Siver Salih
# GitHub URL: https://github.com/siversalih/VMware_ESXi_Image_Builder
# Video: https://www.youtube.com/watch?v=DbqZI1V6TK4
# Version: 0.1
##############################################################################
# PowerShell script for creating a custom ESXi ISO installer image including custom network drivers (net-community and USB network flings)
##############################################################################
Write-Host "ESXi Image Builder" -ForegroundColor Green

$FilePath = "C:\Users\Outlook\Desktop\ESXi-7.0.1\"

$InputProfile = "ESXi-7.0.1-16850804-standard"
$OutputProfile = "ESXi-7.0.1-vmkusb-net-community"
$OutputFile = "ESXi-7.0.1-16850804-USBNIC-40599856-NetCom-v1.2.2"

$VMKUSBFile = "ESXi701-VMKUSB-NIC-FLING-40599856-component-17078334.zip"
$NetCommFile = "Net-Community-Driver_1.2.2.0-1vmw.700.1.0.15843807_18835109.zip"


$InputFile = ($InputProfile+".zip")
$VMWImageDepotURL = "https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml"
$CommunityDownloadURL = "https://download3.vmware.com/software/vmw-tools/community-network-driver/"
$USBDownloadURL = "https://download3.vmware.com/software/vmw-tools/USBNND/"
##############################################################################
# Prerequisites
# Only needs to be executed once, not every time an image is built
# Must be Administrator to execute prerequisites
Write-Host "Prerequisites" -ForegroundColor Green
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
Install-Module -Name VMware.PowerCLI -SkipPublisherCheck
##############################################################################

##############################################################################
# Get the base ESXi image
##############################################################################
Write-Host "Get the base ESXi image" -ForegroundColor Green
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

# Fetch ESXi image depot
Write-Host "Fetch ESXi image depot" -ForegroundColor Green
Add-EsxSoftwareDepot $VMWImageDepotURL
Set-Location $FilePath

# List avilable profiles if desired (show what images are available for download)
#Write-Host "List avilable profiles if desired" -ForegroundColor Green
#Get-EsxImageProfile

# Download desired image
Write-Host "Download the desired image" -ForegroundColor Green
Export-ESXImageProfile -ImageProfile $InputProfile -ExportToBundle -filepath $InputFile

# Remove the depot
Write-Host "Remove the depot" -ForegroundColor Green
Remove-EsxSoftwareDepot $VMWImageDepotURL

# Add default ESXi image files to installation media
Write-Host "Add ESXi image to installation media" -ForegroundColor Green
Add-EsxSoftwareDepot $InputFile


##############################################################################
# Download additional drivers (can be done via browser too) 
##############################################################################
Write-Host "Download additional drivers" -ForegroundColor Green
# Get community network driver 
Invoke-WebRequest -Uri ($CommunityDownloadURL+$NetCommFile) -OutFile $NetCommFile
# Get USB NIC driver
Invoke-WebRequest -Uri ($USBDownloadURL+$VMKUSBFile) -OutFile $VMKUSBFile


##############################################################################
# Add the additional drivers
##############################################################################
Write-Host "Add the additional drivers" -ForegroundColor Green
# Add USB NIC driver
Add-EsxSoftwareDepot ($VMKUSBFile)
# Add community network driver
Add-EsxSoftwareDepot ($NetCommFile)


##############################################################################
# Create new installation media profile and add the additional drivers to it
##############################################################################

# Create new, custom profile
Write-Host "Create new custom profile" -ForegroundColor Green
New-EsxImageProfile -CloneProfile $InputProfile -name $OutputProfile -Vendor "VMware, Inc."

# Optionally remove existing driver package (example for ne1000)
#Remove-EsxSoftwarePackage -ImageProfile "OutputProfile" -SoftwarePackage "ne1000"


Write-Host "Add driver packages to custom profile" -ForegroundColor Green
# Add USB NIC driver package to custom profile
Add-EsxSoftwarePackage -ImageProfile $OutputProfile -SoftwarePackage "vmkusb-nic-fling"
# Add community network driver package to custom profile
Add-EsxSoftwarePackage -ImageProfile $OutputProfile -SoftwarePackage "net-community"


# Export the custom profile to ISO and ZIP
Write-Host "Export the custom profile" -ForegroundColor Green
Export-ESXImageProfile -ImageProfile $OutputProfile -ExportToIso -filepath ($OutputFile+".iso")
Export-ESXImageProfile -ImageProfile $OutputProfile -ExportToBundle -filepath ($OutputFile+".zip")

# Clean up the image profile
Write-Host "Clean up the image profile" -ForegroundColor Green
Remove-EsxSoftwareDepot ("zip:"+$FilePath+$InputFile+"?index.xml")
Remove-EsxSoftwareDepot ("zip:"+$FilePath+$VMKUSBFile+"?index.xml")
Remove-EsxSoftwareDepot ("zip:"+$FilePath+$NetCommFile+"?index.xml")
Remove-EsxImageProfile -ImageProfile $OutputProfile

# Done
Write-Output "Done"
##############################################################################################