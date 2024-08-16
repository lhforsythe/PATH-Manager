Param( 
[string] $InputFilePath  
)

$fileName = Split-Path $InputFilePath -Leaf

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


$oldPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User');
$escapedPath = [RegEx]::Escape($oldPath)
Write-Host ""
Write-Host "==================================================================================================================================="
Write-Host "The following folders are currently in your PATH";
Write-Host "==================================================================================================================================="
$oldPath
Write-Host ""
Write-Host "==================================================================================================================================="
Write-Host "The following file was found in the working directory. This will be added to your PATH by first creating a directory to contain the file, and then by adding this directory to your PATH." -ForegroundColor Yellow;
Write-Host "==================================================================================================================================="

Write-Output $InputFilePath

$outputTable = @()
$alreadyExistsString = "Already exists and will NOT be added to PATH."
$willBeAddedString = "Will be added to PATH."
Foreach($folder in $folders){
  if($oldPath -Match [RegEx]::Escape($PATHtoFileFolder)){
    $entry = [PSCustomObject]@{
      Path = $PATHtoFileFolder
      Status = $alreadyExistsString
    }
    $outputTable += $entry
  } 
  else {
    $entry = [PSCustomObject]@{
      Path = $PATHtoFileFolder
      Status = $willBeAddedString
    }
    $outputTable += $entry
  }
}

$outputTable | Format-Table -AutoSize | Format-Color @{$willBeAddedString = 'Green'; $alreadyExistsString = 'Red'}

# Ask for confirmation before adding specified files within folder to path

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$result = [System.Windows.Forms.MessageBox]::Show(
    "Are you sure you want to add the listed file(s) to your PATH?",
    "Add items to PATH",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning
)

if ($result -eq "Yes") {
# Create folder to contain specified file and copy file over to this directory...
  
  md -Force ~\Documents\PATH-Manager\$fileName
  $PATHtoFileFolder = "~\Documents\PATH-Manager\$fileName"
  New-Item -Path "~\Documents\PATH-Manager\$fileName" -Name $fileName -ItemType HardLink -Value $InputFilePath

  $addedOutputTable = @()
  $successString = "Successfully added to PATH."
  $updatedPath = $oldPath

      if(!($oldPath -Match [RegEx]::Escape($PATHtoFileFolder))){
      $updatedPath += ";$($PATHtoFileFolder)"
      $entry = [PSCustomObject]@{
      Path = $PATHtoFileFolder
      Status = $successString
      }
     $addedOutputTable += $entry
    } 

Write-Host "==================================================================================================================================="
  Write-Host "The following files were added to your PATH:";
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

