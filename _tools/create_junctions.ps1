<#
.SYNOPSIS
    Creates junctions from "E:\Apps\_odin\examples", "E:\Apps\_odin\core" and "E:\Apps\_odin\vendor" to "examples", "core" and "vendor" inside the "_refs" folder.

.DESCRIPTION
    This script creates junction points from the specified source directories to the target directories.

.PARAMETER examplesSource
    The source directory for the examples junction. Default is "E:\Apps\_odin\examples".

.PARAMETER examplesTarget
    The target directory where the examples junction will be created. Default is "_refs\examples".

.PARAMETER coreSource
    The source directory for the core junction. Default is "E:\Apps\_odin\core".

.PARAMETER coreTarget
    The target directory where the core junction will be created. Default is "_refs\core".

.PARAMETER vendorSource
    The source directory for the vendor junction. Default is "E:\Apps\_odin\vendor".

.PARAMETER vendorTarget
    The target directory where the vendor junction will be created. Default is "_refs\vendor".

.EXAMPLE
    .\create_junctions.ps1 -coreSource "E:\Apps\_odin\core" -coreTarget "../_refs\core" -vendorSource "E:\Apps\_odin\vendor" -vendorTarget "../_refs\vendor"
#>


param (
  [string]$examplesSource = 'E:\Apps\_odin\examples',
  [string]$examplesTarget = '',
  [string]$coreSource = 'E:\Apps\_odin\core',
  [string]$coreTarget = '',
  [string]$vendorSource = 'E:\Apps\_odin\vendor',
  [string]$vendorTarget = ''
)

$refFolder = '..\_refs'

if ($examplesTarget -eq '') {
  $examplesTarget = "$refFolder\examples"
}
if ($coreTarget -eq '') {
  $coreTarget = "$refFolder\core"
}
if ($vendorTarget -eq '') {
  $vendorTarget = "$refFolder\vendor"
}

# Ensure the $refFolder directories exist
if (!(Test-Path $refFolder)) {
  Write-Host "This script must be run inside the ""_tools"" and the ""$refFolder"" folder must exists" -ForegroundColor Red
  Exit 1
}

# Ensure the target directories exist
$examplesTargetDir = Split-Path -Path $examplesTarget -Parent
if (!(Test-Path $examplesTargetDir)) {
  New-Item -Path $examplesTargetDir -ItemType Directory -Force
}
$coreTargetDir = Split-Path -Path $coreTarget -Parent
if (!(Test-Path $coreTargetDir)) {
  New-Item -Path $coreTargetDir -ItemType Directory -Force
}
$vendorTargetDir = Split-Path -Path $vendorTarget -Parent
if (!(Test-Path $vendorTargetDir)) {
  New-Item -Path $vendorTargetDir -ItemType Directory -Force
}

# Create the junctions
if (!(Test-Path $examplesTarget)) {
  New-Item -Path $examplesTarget -ItemType Junction -Value $examplesSource
  Write-Host "Junction created from $examplesSource to $examplesTarget" -ForegroundColor Green
} else {
  Write-Host "Junction already exists at $examplesTarget" -ForegroundColor Yellow
}
if (!(Test-Path $coreTarget)) {
  New-Item -Path $coreTarget -ItemType Junction -Value $coreSource
  Write-Host "Junction created from $coreSource to $coreTarget" -ForegroundColor Green
} else {
  Write-Host "Junction already exists at $coreTarget" -ForegroundColor Yellow
}
if (!(Test-Path $vendorTarget)) {
  New-Item -Path $vendorTarget -ItemType Junction -Value $vendorSource
  Write-Host "Junction created from $vendorSource to $vendorTarget" -ForegroundColor Green
} else {
  Write-Host "Junction already exists at $vendorTarget" -ForegroundColor Yellow
}