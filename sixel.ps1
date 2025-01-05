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

  # Output sixel string per sixel row
  $numSixelRows = [Math]::Ceiling($lines.count / 6)
  $lastSixelRow = $numSixelRows - 1
  foreach($sixelRow in 0..$lastSixelRow) {
    
    # Get colors used in this sixel row
    $colorCharToRegister = @{}
    $lastCol = $lineLength - 1
    foreach($col in 0..$lastCol) {
      foreach($subRow in 0..5) {
        $imageRow = $sixelRow * 6 + $subRow
        if ($imageRow -ge $lines.Count) {continue}
        $c = getColorChar $lines $imageRow $col
        if (!$colorCharToRegister.Contains("$c")) {$colorCharToRegister["$c"] = $colorCharToRegister.Count}        
      }
    }

    # Calculate color map registers
    $colorMapRegistersArrayList = New-Object System.Collections.ArrayList
    $m = "1" # HLS - using instead of RGB ("2") because it has more total colors by almost 4x
             #       HLS = 360 * 100 * 100 = 3,600,000          
             #       RGB = 100 * 100 * 100 = 1,000,000
    foreach($colorChar in $colorCharToRegister.Keys) {
      $r = $colorCharToRegisterNumber[$colorChar]
      $color = $colorCharToColor[$colorChar]

      # Extract HLS
      $h = $color.GetHue() 
      $l = $color.GetBrightness() * 100
      $s = $color.GetSaturation() * 100

      # Setup color map register
      $null = $colorMapRegistersArrayList.Add("#$r;$m;$h;$l;$s")
    }
    $colorMapRegisters = $colorMapRegistersArrayList -join ";"

    # Calculate sixel data in this sixel row
    $sixelData = ""
    $lastColor = $colorCharToRegister.Keys | Select-Object -Last 1
    foreach($colorChar in $colorCharToRegister.Keys) {
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

    # Output sixel string
     
  }

<#

# Get all the colors used in $lines
$colors = @{}
foreach ($line in $lines) {
    foreach ($char in $line.ToCharArray()) {
      if (!$colors.Contains("$char")) {$colors["$char"] = $colors.Count}
    }
  }
  
  # Create color register setup string
  $colorRegisters = New-Object System.Collections.ArrayList
  # $m = "1" # HSL Mode
  $m = "2" # RGB Mode
  foreach ($color in $colors.Keys) {
    $c = $colors[$color] # color register
    $rgb = $colorCharToColor[$color]
    # Convert from 0-255 to 0-100
    $r = $rgb.R/255 * 100
    $g = $rgb.G/255 * 100
    $b = $rgb.B/255 * 100
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
#>  
}



outputSixel $asciiImage $colorCharToColor
