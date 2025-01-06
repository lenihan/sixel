$black   = [System.Drawing.Color]::FromArgb(0, 0, 0)
$white   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$red     = [System.Drawing.Color]::FromArgb(255, 0, 0)
$green   = [System.Drawing.Color]::FromArgb(0, 255, 0)
$blue    = [System.Drawing.Color]::FromArgb(0, 0, 255)
$cyan    = [System.Drawing.Color]::FromArgb(0, 255, 255)
$yellow  = [System.Drawing.Color]::FromArgb(255, 255, 0)
$magenta = [System.Drawing.Color]::FromArgb(255, 0, 255)

$colorCharToColor = @{
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


function getColorChar($lines, $row, $col) {
  if ($row -ge $lines.Count) {throw "Expecting row ($row) to be less than number of lines ($($lines.Count))"}
  if ($col -ge $lines[$row].Length) {throw "Expecting col ($col) to be less than number of col ($($lines[$row].Length))"}
  return $lines[$row][$col]
}

function outputSixel($asciiImage, $colorCharToColor) {
  # Sixel references
  #   https://www.digiater.nl/openvms/decus/vax90b1/krypton-nasa/all-about-sixels.text
  #   https://en.wikipedia.org/wiki/Sixel

  # Expecting only `n for line endings
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

  # Get all colors used
  $colorCharToRegisterNumber = @{}
  $lastRow = $lines.Count - 1
  $lastCol = $lineLength - 1
  foreach($col in 0..$lastCol) {
    foreach($row in 0..$lastRow) {
      $c = getColorChar $lines $row $col
      if (!$colorCharToRegisterNumber.Contains("$c")) {
        $colorCharToRegisterNumber["$c"] = $colorCharToRegisterNumber.Count
      }        
    }
  }

  # Calculate color map registers
  $colorMapRegisters = ""
  $m = "1" # HLS - using instead of RGB ("2") because it has more total colors by almost 4x
           #       HLS = 360 * 100 * 100 = 3,600,000          
           #       RGB = 100 * 100 * 100 = 1,000,000
  foreach($colorChar in $colorCharToRegisterNumber.Keys) {
    $r = $colorCharToRegisterNumber[$colorChar]
    $color = $colorCharToColor[$colorChar]

    # Extract HLS
    $h = $color.GetHue() 
    $l = $color.GetBrightness() * 100
    $s = $color.GetSaturation() * 100

    # Setup color map register
    $colorMapRegisters += "#$r;$m;$h;$l;$s;"
  }
  
  # Output sixel string per sixel row
  $numSixelRows = [Math]::Ceiling($lines.count / 6)
  $lastSixelRow = $numSixelRows - 1
  $sixelData = ""
  foreach($sixelRow in 0..$lastSixelRow) {
    # Calculate sixel data in this sixel row
    $lastColor = $colorCharToRegisterNumber.Keys | Select-Object -Last 1
    foreach($colorChar in $colorCharToRegisterNumber.Keys) {
      $r = $colorCharToRegisterNumber[$colorChar]
      
      # Start sixel data with # and color register
      $sixelData += "#$r"
      
      foreach($col in 0..$lastCol) {
        $sixel = 0
        foreach($subRow in 0..5) {
          $imageRow = $sixelRow * 6 + $subRow
          if ($imageRow -ge $lines.Count) {continue}
          $c = getColorChar $lines $imageRow $col
          if ($c -eq $colorChar) {$sixel += [Math]::Pow(2, $subRow)}
        }
        $charSixel = [char]([int]$sixel + [char]"?")
        $sixelData += $charSixel
      }
      $lineControl = $colorChar -eq $lastColor ? "-" : "$"     # new line (-) or overwrite ($)
      $sixelData += $lineControl
    }
  }

  # Put it all together
  $enterSixelMode = "`ePq"
  $exitSixelMode = "`e\"
  "$enterSixelMode$colorMapRegisters$sixelData$exitSixelMode" 
}



outputSixel $asciiImage $colorCharToColor
