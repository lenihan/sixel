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


$hereString = @'
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

$lines = $hereString -split '`n'
$lineLength = $null
foreach ($line in $lines) {
    if (!$lineLength) {$lineLength = $line.Length}
    elseif ($line.Length -ne $lineLength) {
        throw "Expecting line length of $lineLength but got $($line.Length) for this line: $line"
    }
}

`
