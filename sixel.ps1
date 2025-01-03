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
  if ($row -ge $lines.Count) {throw "Expecting row ($row) to be less than number of lines ($($lines.Count))"}
  if ($col -ge $lines[$row].Length) {throw "Expecting col ($col) to be less than number of col ($($lines[$row].Length))"}
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
      if (!$colors.Contains("$char")) {$colors["$char"] = $colors.Count}
    }
  }

  # Create color register setup string
  $colorRegisters = New-Object System.Collections.ArrayList
  $m = "2" # RGB Mode
  foreach ($color in $colors.Keys) {
    $c = $colors[$color] # color register
    $rgb = $charToColorMap[$color]
    $r = $rgb.R
    $g = $rgb.G
    $b = $rgb.B
    $null = $colorRegisters.Add("#$c;$m;$r;$g;$b")
  }
  $colorRegisterSetup = $colorRegisters -join ";"
  $colorRegisterSetup
  
  # For each color, create sixel
  # End with "$": Next line overprints
  # End with "-": Next line is new line
  # Compress: "!123?" Will make 123 ?'s. Only saving space for 4+ repeats
  # "!<REPEATS><ASCII>"" for run length encoding
  $numSixelRows = [Math]::Ceiling($lines.count / 6)
  $lastSixelRow = $numSixelRows - 1
  $lastCol = $lineLength - 1
  $lastColor = $colors.Keys | Select-Object -Last 1
  foreach($sixelRow in 0..$lastSixelRow) {
    foreach($color in $colors.Keys) {
      $sixelCodes = $null
      foreach($col in 0..$lastCol) {
        $sixel = 0
        foreach($row in 0..5) {
          $offsetRow = $sixelRow * 6 + $row
          if ($offsetRow -ge $lines.Count) {continue}
          $c = getColor $lines $offsetRow $col
          if ($c -eq $color) {$sixel += [Math]::Pow(2, $row)}
        }
        $encodedSixel = [char]([int]$sixel + [char]"?")  # Reason for "?" offset explained here: https://en.wikipedia.org/wiki/Sixel#Description
        $sixelCodes += $encodedSixel
      }
      # TODO $sixelCodes = compressSixel $sixelCodes
      $colorRegister = $colors[$color]                 # color register
      $endLine = $color -eq $lastColor ? "-" : "$"     # add last char for new line (-) or overwrite ($)
      $final = "#$colorRegister$sixelCodes$endLine"             
      Write-Host "SixelCodes = $final"
    }
  }


  # combine all sixels into single image
  # Use $ to overwrite previous line
}



outputSixel $asciiImage $charToColorMap
