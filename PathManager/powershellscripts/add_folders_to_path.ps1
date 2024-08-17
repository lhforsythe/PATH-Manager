
# Allow easy customization of colors
function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -ForegroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}

$folders = Get-ChildItem -Path . -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
$oldPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User');
$escapedPath = [RegEx]::Escape($oldPath)
Write-Host ""
Write-Host "==================================================================================================================================="
Write-Host "The following folders are currently in your PATH";
Write-Host "==================================================================================================================================="
$oldPath
Write-Host ""
Write-Host "==================================================================================================================================="
Write-Host "The following folders were found in the working directory and will be added to your PATH: ";
Write-Host "==================================================================================================================================="

$outputTable = @()
$alreadyExistsString = "Already exists and will NOT be added to PATH."
$willBeAddedString = "Will be added to PATH."
Foreach($folder in $folders){
  if($oldPath -Match [RegEx]::Escape($folder.FullName)){
    $entry = [PSCustomObject]@{
      Path = $folder.FullName
      Status = $alreadyExistsString
    }
    $outputTable += $entry
  } 
  else {
    $entry = [PSCustomObject]@{
      Path = $folder.FullName
      Status = $willBeAddedString
    }
    $outputTable += $entry
  }
}

$outputTable | Format-Table -AutoSize | Format-Color @{$willBeAddedString = 'Green'; $alreadyExistsString = 'Red'}

# Ask for confirmation before adding specified files within folder to path

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$result = [System.Windows.Forms.MessageBox]::Show(
    "Are you sure you want to add the listed folder(s) to your PATH?",
    "Add items to PATH",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning
)

if ($result -eq "Yes") {

  $addedOutputTable = @()
  $successString = "Successfully added to PATH."
  $updatedPath = $oldPath
    Foreach($folder in $folders){
      if(!($oldPath -Match [RegEx]::Escape($folder.FullName))){
      $updatedPath += ";$($folder.FullName)"
      $entry = [PSCustomObject]@{
      Path = $folder.FullName
      Status = $successString
      }
     $addedOutputTable += $entry
    } 
}

Write-Host "==================================================================================================================================="
  Write-Host "The following folders were added to your PATH:";
  Write-Host "==================================================================================================================================="
  $addedOutputTable | Format-Table -AutoSize | Format-Color @{$successString = 'Green'}

  [Environment]::SetEnvironmentVariable("PATH", $updatedPath, [EnvironmentVariableTarget]::User)
  $newPath = [Environment]::GetEnvironmentVariable('PATH', 'User');
  Write-Host "===================================================================================================================================" -ForegroundColor Cyan
  Write-Host "Your PATH has been updated to: " -ForegroundColor Cyan
  Write-Host "===================================================================================================================================" -ForegroundColor Cyan
  $newPath

  Write-Host ""
  Write-Host "===================================================================================================================================" -ForegroundColor Yellow
  Write-Host "Your previous PATH was written to 'old_path.txt' as a precaution. Delete this file if it is not needed for a restoration." -ForegroundColor Yellow
  Write-Host "===================================================================================================================================" -ForegroundColor Yellow
  $oldPath | Out-File .\old_path.txt

  Write-Host "================================================================================="
  Write-Host "PATH updated successfully! This window will close automatically in 5 seconds" -ForegroundColor Green
  Write-Host "================================================================================="
Start-Sleep -Seconds 5
}

else {
  Write-Host "================================================================================="
  Write-Host "Nothing was added to your PATH. This window will close automatically in 5 seconds" -ForegroundColor Red
  Write-Host "================================================================================="
  
  Start-Sleep -Seconds 5
}

