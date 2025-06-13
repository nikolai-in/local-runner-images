<#
.SYNOPSIS
    Initializes, formats and mounts the secondary disk as D: drive for temporary storage.
.DESCRIPTION
    This script finds the raw disk added to the VM, initializes it, creates a partition, 
    formats it with NTFS, and assigns the D: drive letter for use as temp storage.
#>

Write-Host "Initializing secondary disk for temp directory..."

try {
    # Get the raw/uninitialized disk (should be disk 1, as disk 0 is the system disk)
    $disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Select-Object -First 1

    if (-not $disk) {
        throw "No uninitialized disk found"
    }

    Write-Host "Found uninitialized disk: Disk $($disk.Number), Size: $($disk.Size / 1GB) GB"

    # Initialize the disk with GPT partition style
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -ErrorAction Stop
    Write-Host "Disk initialized successfully"

    # Create a new partition using the maximum size
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -ErrorAction Stop
    Write-Host "Partition created successfully"

    # Format the volume with NTFS
    $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "TempDisk" -Confirm:$false -ErrorAction Stop
    Write-Host "Volume formatted successfully: $($volume.FileSystemLabel)"

    # Assign drive letter D:
    Set-Partition -DiskNumber $disk.Number -PartitionNumber $partition.PartitionNumber -NewDriveLetter 'D' -ErrorAction Stop
    Write-Host "Drive letter D: assigned successfully"

    # Verify the drive is accessible
    if (Test-Path -Path "D:\") {
        Write-Host "Drive D: is accessible and ready to use"
    } else {
        throw "Drive D: was not properly mounted"
    }
} catch {
    Write-Host "Error initializing disk: $_"
    throw $_
}
