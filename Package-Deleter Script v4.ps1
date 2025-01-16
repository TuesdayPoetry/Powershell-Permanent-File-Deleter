# Filepath where you want things permanently deleted when this script is run
$folder = "F:\Packages\DELETE"

# Get the current date and time in a readable format
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Get the next log number by counting the existing logs
$logDir = "F:\Logs"
$logFiles = Get-ChildItem -Path $logDir -Filter "delete_log_*.txt"
$logNumber = $logFiles.Count + 1

# Generate the log file name with the date, time, and consecutive number
$logFile = "$logDir\SecureDelete_log_$logNumber" + "_$dateTime.txt"

# Clear the content of the log file if it exists (it shouldn't exist, but for safety)
Clear-Content -Path $logFile -ErrorAction SilentlyContinue

# Get the name of the current script
$scriptName = $MyInvocation.MyCommand.Name

# Get the current username
$userName = $env:USERNAME

# Check if the folder is empty
$folderContents = Get-ChildItem -Path $folder -Recurse
if ($folderContents.Count -eq 0) {
    Write-Host "Error: The folder '$folder' is empty. No files or folders to delete." -ForegroundColor Red
} else {
    # Ask for user confirmation before starting the deletion
    $confirmation = Read-Host -Prompt "Are you sure you want to PERMANENTLY DELETE ALL files and folders in: $folder (Type 'YES' to confirm)"
    
    if ($confirmation -ne "YES") {
        Write-Host "Aborting deletion process." -ForegroundColor Red
        return
    }

    # Start logging
    Add-Content -Path $logFile -Value "Log created by script: $scriptName"
    Add-Content -Path $logFile -Value "Log file name: $logFile"
    Add-Content -Path $logFile -Value "Executed by user: $userName"
    Add-Content -Path $logFile -Value "Starting file deletion at $(Get-Date)"
    Add-Content -Path $logFile -Value "Folder: $folder"

    # Print initial status
    Write-Host "Starting deletion process..." -ForegroundColor Green
    Write-Host "Logs will be saved to: $logFile" -ForegroundColor Cyan

    # Initialize counters
    $fileCount = 0
    $folderCount = 0

    # Get the total number of items for progress reporting
    $totalItems = $folderContents.Count
    $currentItem = 0

    # First, delete all files in the folder and log the file deletions
    $folderContents | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        $file = $_
        try {
            $currentItem++
            # Print progress to console
            Write-Host ("Processing file {0} of {1}: {2}" -f $currentItem, $totalItems, $file.FullName) -ForegroundColor Yellow
            # Log the file deletion
            Add-Content -Path $logFile -Value "Deleting file: $($file.FullName)"
            # Delete the file
            Remove-Item -Path $file.FullName -Force
            $fileCount++
            Add-Content -Path $logFile -Value "Deleted file: $($file.FullName)"
        } catch {
            # Log any errors
            Add-Content -Path $logFile -Value "Error deleting $($file.FullName): $_"
            Write-Host "Error deleting file: $($file.FullName)" -ForegroundColor Red
        }
    }

    # Then, delete all folders in the folder and log the folder deletions
    $folderContents | Where-Object { $_.PSIsContainer } | Sort-Object -Property FullName -Descending | ForEach-Object {
        $subfolder = $_  # Renamed to avoid conflict with the main $folder variable
        try {
            $currentItem++
            # Print progress to console
            Write-Host ("Processing folder {0} of {1}: {2}" -f $currentItem, $totalItems, $subfolder.FullName) -ForegroundColor Yellow
            # Log the folder deletion
            Add-Content -Path $logFile -Value "Deleting folder: $($subfolder.FullName)"
            # Delete the folder
            Remove-Item -Path $subfolder.FullName -Recurse -Force
            $folderCount++
            Add-Content -Path $logFile -Value "Deleted folder: $($subfolder.FullName)"
        } catch {
            # Log any errors
            Add-Content -Path $logFile -Value "Error deleting $($subfolder.FullName): $_"
            Write-Host "Error deleting folder: $($subfolder.FullName)" -ForegroundColor Red
        }
    }

    # Final summary of deletions
    Add-Content -Path $logFile -Value "File deletion completed at $(Get-Date)"
    Add-Content -Path $logFile -Value "Total files deleted: $fileCount"
    Add-Content -Path $logFile -Value "Total folders deleted: $folderCount"

    # Print final status
    Write-Host "Deletion process completed!" -ForegroundColor Green
    Write-Host "Total files deleted: $fileCount" -ForegroundColor Cyan
    Write-Host "Total folders deleted: $folderCount" -ForegroundColor Cyan
    Write-Host "Check the log file for details: $logFile" -ForegroundColor Cyan
}

Pause
