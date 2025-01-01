$black   = [System.Drawing.Color]::FromArgb(0, 0, 0)
$white   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$red     = [System.Drawing.Color]::FromArgb(255, 0, 0)
$green   = [System.Drawing.Color]::FromArgb(0, 255, 0)
$blue    = [System.Drawing.Color]::FromArgb(0, 0, 255)
$cyan    = [System.Drawing.Color]::FromArgb(0, 255, 255)
$yellow  = [System.Drawing.Color]::FromArgb(255, 255, 0)
$magenta = [System.Drawing.Color]::FromArgb(255, 0, 255)

$charToColorMap = @{
    ' ' = $black
    '*' = $white
    'R' = $red
    'G' = $green
    'B' = $blue
    'C' = $cyan
    'Y' = $yellow
    'M' = $magenta
}


$asciiImage = @'
     ***     
   *     *   
 *         * 
*   *   *   *
*           *
*  *     *  *
 *  *****  * 
   *     *   
     ***     
'@


function getColor($lines, $row, $col) {
  if ($row -ge $lines.Count) {return $null}
  if ($col -ge $lines[$row].Count) {return $null}
  return $lines[$row][$col]
}

function outputSixel($asciiImage, $charToColorMap) {
  $asciiImage = $asciiImage -replace "`r"
  
  # Get line length, verify all lines same length
  $lines = $asciiImage -split "`n"
  $lineLength = $null
  foreach ($line in $lines) {
      if (!$lineLength) {$lineLength = $line.Length}
      elseif ($line.Length -ne $lineLength) {
          throw "Expecting line length of $lineLength but got $($line.Length) for this line: $line"
      }
  }

  # Get all the colors used in $lines
  $colors = @{}
  foreach ($line in $lines) {
    foreach ($char in $line.ToCharArray()) {
      $colors["$char"] = $true
    }
  }
  
  # For each color, create sixel
  # End with "$": Next line overprints
  # End with "-": Next line is new line
  # "!<REPEATS><ASCII>"" for run length encoding
  $numSixelRows = [Math]::Ceiling($lines.count / 6)
  $lastSixelRow = $numSixelRows - 1
  $lastCol = $lineLength - 1
  foreach($sixelRow in 0..$lastSixelRow) {
    foreach($color in $colors.Keys) {
      foreach($col in 0..$lastCol) {
        $sixel = 0
        foreach($row in 0..5) {
          $offsetRow = $sixelRow * 6 + $row
          $c = getColor $lines $offsetRow $col
          "$offsetRow $col $c"
          if ($c -eq $color) {$sixel += [Math]::Pow(2, $row)}
        }
        $encodedSixel = [char]([int]$sixel + [char]"?")  # Reason for "?" offset explained here: https://en.wikipedia.org/wiki/Sixel#Description
        Write-Host "color $color`: $encodedSixel"
      }
    }
  }


  # combine all sixels into single image
  # Use $ to overwrite previous line
}



outputSixel $asciiImage $charToColorMap
