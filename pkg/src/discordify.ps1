param(
    [Parameter(Mandatory=$true)]
    [string]$inputFile,

    [string]$outputDir = ".",

    [int]$targetSizeMB = 25,

    [double]$initialOverheadFactor = 0.75
)

function Get-VideoDuration {
    param (
        [string]$filename
    )
    
    $ffmpegOutput = & ffmpeg -i $filename 2>&1
    $durationLine = $ffmpegOutput | Select-String "Duration" | ForEach-Object { $_.Line }
    
    if ($durationLine) {
        $durationStr = $durationLine -replace ".*Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2}).*", '$1:$2:$3'
        $timeParts = $durationStr -split ':'
        $durationSec = ($timeParts[0] -as [double]) * 3600 + ($timeParts[1] -as [double]) * 60 + ($timeParts[2] -as [double])
        return $durationSec
    } else {
        throw "Could not determine video duration."
    }
}

function Calculate-Bitrate {
    param (
        [int]$targetSizeMB,
        [double]$durationSec,
        [double]$overheadFactor
    )
    
    # Convert target size to bits
    $targetSizeBits = $targetSizeMB * 8 * 1024 * 1024
    # Calculate target bitrate in Kbps
    $targetBitrateKbps = ($targetSizeBits / $durationSec) / 1000
    # Adjust for encoding overhead
    $adjustedBitrateKbps = [math]::Floor($targetBitrateKbps * $overheadFactor)
    return $adjustedBitrateKbps
}

function Get-GPUType {
    # Check for NVIDIA GPUs
    $nvidiaGPU = Get-WmiObject -Query "SELECT * FROM Win32_VideoController" | Where-Object { $_.Caption -like "*NVIDIA*" }
    if ($nvidiaGPU) {
        return "NVIDIA"
    }
    
    # Check for AMD GPUs
    $amdGPU = Get-WmiObject -Query "SELECT * FROM Win32_VideoController" | Where-Object { $_.Caption -like "*AMD*" }
    if ($amdGPU) {
        return "AMD"
    }
    
    return "None"
}

function Reencode-Video {
    param (
        [string]$inputFile,
        [string]$tempFile,
        [int]$targetBitrateKbps,
        [string]$gpuType
    )
    
    if ($gpuType -eq "NVIDIA") {
        # NVIDIA NVENC Encoder
        & ffmpeg -y -hwaccel nvdec -i $inputFile -c:v h264_nvenc -b:v "${targetBitrateKbps}k" -pass 1 -an -f mp4 NUL
        & ffmpeg -y -hwaccel nvdec -i $inputFile -c:v h264_nvenc -b:v "${targetBitrateKbps}k" -pass 2 -b:a 128k -f mp4 $tempFile
    } elseif ($gpuType -eq "AMD") {
        # AMD VCE Encoder
        & ffmpeg -y -i $inputFile -c:v h264_amf -b:v "${targetBitrateKbps}k" -pass 1 -an -f mp4 NUL
        & ffmpeg -y -i $inputFile -c:v h264_amf -b:v "${targetBitrateKbps}k" -pass 2 -b:a 128k -f mp4 $tempFile
    } else {
        throw "No compatible GPU found. Please use a supported NVIDIA or AMD GPU."
    }
}

function Get-FileSizeMB {
    param (
        [string]$filePath
    )
    
    if (Test-Path $filePath) {
        $fileInfo = Get-Item $filePath
        return [math]::Round($fileInfo.Length / 1MB, 2)
    } else {
        throw "File does not exist: $filePath"
    }
}

# Main Script
$durationSec = Get-VideoDuration -filename $inputFile
$targetBitrateKbps = Calculate-Bitrate -targetSizeMB $targetSizeMB -durationSec $durationSec -overheadFactor $initialOverheadFactor
$gpuType = Get-GPUType

# Ensure the output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Generate the output file paths
$outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile) + '_reencoded.mp4'
$tempFile = Join-Path -Path $outputDir -ChildPath ($outputFileName + '.tmp')
$finalOutputFile = Join-Path -Path $outputDir -ChildPath $outputFileName

# Perform initial encoding
Reencode-Video -inputFile $inputFile -tempFile $tempFile -targetBitrateKbps $targetBitrateKbps -gpuType $gpuType

# Check the file size and re-encode if necessary
$fileSizeMB = Get-FileSizeMB -filePath $tempFile

if ($fileSizeMB -gt $targetSizeMB) {
    # Reduce the overhead factor by 25%
    $newOverheadFactor = $initialOverheadFactor * 0.75
    Write-Host "File size is too large ($fileSizeMB MB). Re-encoding with more aggressive settings..."

    # Recalculate bitrate with the new overhead factor
    $targetBitrateKbps = Calculate-Bitrate -targetSizeMB $targetSizeMB -durationSec $durationSec -overheadFactor $newOverheadFactor

    # Re-encode video with the new bitrate
    Reencode-Video -inputFile $inputFile -tempFile $tempFile -targetBitrateKbps $targetBitrateKbps -gpuType $gpuType

    $fileSizeMB = Get-FileSizeMB -filePath $tempFile
}

# Rename the temporary file to the final output file
if (Test-Path $tempFile) {
    Rename-Item -Path $tempFile -NewName $finalOutputFile
    Write-Host "Video re-encoded successfully and saved as $finalOutputFile"
} else {
    throw "Temporary file was not created. Encoding failed."
}
