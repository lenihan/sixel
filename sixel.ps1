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
  $lines = $asciiImage -split '`n'
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
    foreach ($character in $line.ToCharArray()) {
      $colors["$character"] = $true
    }
  }
  
  $colors.Keys.count
  # Create color header

  # For each color, create sixel
  # Use - to move to next line
  # Use !<REPEATS><ASCII> for run length encoding


  # combine all sixels into single image
  # Use $ to overwrite previous line

}



outputSixel $asciiImage $charToColorMap
