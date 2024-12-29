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

function outputSixel($asciiImage, $charToColorMap) {
  
  # Get line length, verify all lines same length
  $lines = $asciiImage -split "`r`n"
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
  foreach($row in 0.. $lastSixelRow) {
    $rowOffset = $row * 6
    $lines[0 + $rowOffset][0]
    $lines[1 + $rowOffset][0]
    $lines[2 + $rowOffset][0]
    $lines[3 + $rowOffset][0]
    $lines[4 + $rowOffset][0]
    $lines[5 + $rowOffset][0]
  }


  # foreach ($color in $colors) {

  # }
  


  # combine all sixels into single image
  # Use $ to overwrite previous line

}



outputSixel $asciiImage $charToColorMap
