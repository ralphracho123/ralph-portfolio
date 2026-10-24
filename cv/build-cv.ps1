# =============================================================================
#  Builds assets/ralph-racho-cv.pdf — a one-page A4 CV, written directly as
#  PDF rather than printed from a browser (headless printing is blocked here).
#
#  Run it from anywhere:   powershell -File cv\build-cv.ps1
#  Edit the CONTENT block below to change what the CV says.
# =============================================================================

$ErrorActionPreference = 'Stop'

$outPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\ralph-racho-cv.pdf'

# ---------------------------------------------------------------- page setup
$PW = 595.28; $PH = 841.89      # A4 in points
$ML = 44; $MR = 44; $MT = 46
$MAIN_X = $ML;  $MAIN_W = 330
$SIDE_X = 398;  $SIDE_W = $PW - $MR - 398

# colours (r g b, 0..1)
$INK   = '0 0 0'
$CORAL = '0.788 0.267 0.110'
$SOFT  = '0 0 0'
$FAINT = '0 0 0'
$RULE  = '0.855 0.835 0.790'

# ------------------------------------------------------------------- portrait
# The site portrait, cropped to 4:5 and re-encoded as JPEG so it can go into the
# PDF as a /DCTDecode image. System.Drawing ships with Windows, so this still
# needs nothing installed.
Add-Type -AssemblyName System.Drawing
$photoSrc = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\ralph.png'
$jpeg = $null; $jpegW = 0; $jpegH = 0

if (Test-Path $photoSrc) {
  $src = [System.Drawing.Image]::FromFile($photoSrc)
  try {
    $ratio = 4.0 / 5.0
    $cw = $src.Width; $ch = [int]($src.Width / $ratio)
    if ($ch -gt $src.Height) { $ch = $src.Height; $cw = [int]($src.Height * $ratio) }
    $cropX = [int](($src.Width  - $cw) / 2)
    $cropY = [int](($src.Height - $ch) * 0.10)   # bias upward, as on the website

    $jpegW = 540; $jpegH = [int]($jpegW / $ratio)
    $bmp = New-Object System.Drawing.Bitmap $jpegW, $jpegH
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.InterpolationMode = 'HighQualityBicubic'
    $gfx.Clear([System.Drawing.Color]::White)         # flatten any transparency
    $gfx.DrawImage($src,
      (New-Object System.Drawing.Rectangle 0, 0, $jpegW, $jpegH),
      (New-Object System.Drawing.Rectangle $cropX, $cropY, $cw, $ch),
      [System.Drawing.GraphicsUnit]::Pixel)
    $gfx.Dispose()

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }
    $prm = New-Object System.Drawing.Imaging.EncoderParameters 1
    $prm.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
      [System.Drawing.Imaging.Encoder]::Quality, 88)
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, $codec, $prm)
    $jpeg = $ms.ToArray()
    $ms.Dispose(); $bmp.Dispose()
  } finally { $src.Dispose() }
} else {
  Write-Warning "No portrait at $photoSrc - building the CV without a photo."
}
# ------------------------------------------------------- Helvetica metrics
# AFM widths (per 1000 units) for the characters we actually use. Only the
# wrapped body text needs measuring; headings are single lines.
$hvChars = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
$hvReg = @(278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,
           556,556,556,556,556,556,556,556,556,556,
           278,278,584,584,584,556,1015,
           667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,667,778,722,667,611,722,667,944,667,667,611,
           278,278,278,469,556,333,
           556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,556,556,333,500,278,556,500,722,500,500,500,
           334,260,334,584)
$hvBold = @(278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,
            556,556,556,556,556,556,556,556,556,556,
            333,333,584,584,584,611,975,
            722,722,722,722,667,611,778,722,278,556,722,611,833,722,778,667,778,722,667,611,722,667,944,667,667,611,
            333,278,333,584,556,333,
            556,611,556,611,556,333,611,611,278,278,556,278,889,611,611,611,611,389,556,333,611,556,778,556,556,500,
            389,280,389,584)

$WREG = @{}; $WBOLD = @{}
for ($i = 0; $i -lt $hvChars.Length; $i++) {
  $WREG[$hvChars[$i]]  = $hvReg[$i]
  $WBOLD[$hvChars[$i]] = $hvBold[$i]
}

function Get-TextWidth {
  param([string]$Text, [double]$Size, [bool]$Bold = $false, [double]$Tracking = 0)
  $table = if ($Bold) { $WBOLD } else { $WREG }
  $total = 0
  foreach ($c in $Text.ToCharArray()) {
    $w = $table[$c]
    if ($null -eq $w) { $w = 556 }     # dashes, bullets and the like
    $total += $w
  }
  return ($total * $Size / 1000.0) + ($Text.Length * $Tracking)
}

function Split-Lines {
  param([string]$Text, [double]$Width, [double]$Size, [bool]$Bold = $false)
  $words = $Text -split '\s+'
  $lines = @(); $line = ''
  foreach ($w in $words) {
    $try = if ($line -eq '') { $w } else { "$line $w" }
    if ((Get-TextWidth $try $Size $Bold) -le $Width) { $line = $try }
    else { if ($line -ne '') { $lines += $line }; $line = $w }
  }
  if ($line -ne '') { $lines += $line }
  return $lines
}

# -------------------------------------------------------------- PDF writing
$ops = New-Object System.Text.StringBuilder

function Esc {
  param([string]$s)
  # WinAnsi for the few non-ASCII characters this CV uses
  $s = $s -replace [char]0x2014, [char]0x97    # em dash
  $s = $s -replace [char]0x2013, [char]0x96    # en dash
  $s = $s -replace [char]0x00B7, [char]0xB7    # middle dot
  $s = $s -replace [char]0x2019, [char]0x92    # right quote
  $s = $s -replace [char]0x201C, [char]0x93
  $s = $s -replace [char]0x201D, [char]0x94
  $s = $s -replace '\\', '\\\\'
  $s = $s -replace '\(', '\('
  $s = $s -replace '\)', '\)'
  return $s
}

function Add-Text {
  param([string]$Text, [double]$X, [double]$Y, [string]$Font, [double]$Size,
        [string]$Color, [double]$Tracking = 0)
  $null = $ops.AppendLine("BT $Color rg /$Font $Size Tf $Tracking Tc 1 0 0 1 $([math]::Round($X,2)) $([math]::Round($PH - $Y,2)) Tm ($(Esc $Text)) Tj 0 Tc ET")
}

function Add-Rect {
  param([double]$X, [double]$Y, [double]$W, [double]$H, [string]$Color)
  $null = $ops.AppendLine("$Color rg $([math]::Round($X,2)) $([math]::Round($PH - $Y - $H,2)) $([math]::Round($W,2)) $([math]::Round($H,2)) re f")
}

function Add-Frame {
  param([double]$X, [double]$Y, [double]$W, [double]$H, [string]$Color, [double]$LW = 0.8)
  $null = $ops.AppendLine("$Color RG $LW w $([math]::Round($X,2)) $([math]::Round($PH - $Y - $H,2)) $([math]::Round($W,2)) $([math]::Round($H,2)) re S")
}

function Add-Image {
  param([double]$X, [double]$Y, [double]$W, [double]$H)
  $null = $ops.AppendLine("q $([math]::Round($W,2)) 0 0 $([math]::Round($H,2)) $([math]::Round($X,2)) $([math]::Round($PH - $Y - $H,2)) cm /Im1 Do Q")
}
# =============================================================== CONTENT ====

# ---- header
$y = $MT + 18
Add-Text 'Ralph Lorence Racho' $ML $y 'F3' 24 $INK
$y += 13
Add-Text 'PROJECT MANAGER  /  UI/UX DESIGNER  /  QA TESTER' $ML $y 'F2' 7.6 $INK 1.05

# contact, right aligned
$contact = @('ralphracho123@gmail.com',
             'github.com/ralphracho123',
             'facebook.com/ralph.racho.7',
             'Cebu, Philippines')
$cy = $MT + 2
foreach ($line in $contact) {
  $w = Get-TextWidth $line 8.2 $false
  Add-Text $line ($PW - $MR - $w) $cy 'F1' 8.2 $SOFT
  $cy += 10.4
}

$y += 9
Add-Rect $ML $y ($PW - $ML - $MR) 1.6 $INK
$y += 16

$mainY = $y
$sideY = $y

# ---- helpers that lay out a column -----------------------------------------
function Add-Heading {
  param([string]$Text, [double]$X, [double]$W, [ref]$Y)
  Add-Text $Text.ToUpper() $X ($Y.Value) 'F2' 7.8 $INK 1.3
  $Y.Value += 4.5
  Add-Rect $X ($Y.Value) $W 0.6 $RULE
  $Y.Value += 10
}

function Add-Body {
  param([string]$Text, [double]$X, [double]$W, [ref]$Y,
        [double]$Size = 8.4, [string]$Color = $SOFT, [double]$Lead = 10.4)
  foreach ($line in (Split-Lines $Text $W $Size $false)) {
    Add-Text $line $X ($Y.Value) 'F1' $Size $Color
    $Y.Value += $Lead
  }
}

function Add-Bullet {
  param([string]$Text, [double]$X, [double]$W, [ref]$Y)
  $indent = 9
  $lines = Split-Lines $Text ($W - $indent) 8.4 $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq 0) { Add-Rect $X ($Y.Value - 3) 2.6 2.6 $CORAL }
    Add-Text $lines[$i] ($X + $indent) ($Y.Value) 'F1' 8.4 $SOFT
    $Y.Value += 10.3
  }
}

function Add-Entry {
  param([string]$Title, [string]$When, [string]$Role, [string[]]$Bullets,
        [string]$Meta, [double]$X, [double]$W, [ref]$Y)
  Add-Text $Title $X ($Y.Value) 'F3' 11.5 $INK
  if ($When) {
    # NB: not $w — PowerShell variable names are case-insensitive, so that
    # would overwrite the column width $W a few lines down.
    $whenW = Get-TextWidth $When 7.4 $true 0.6
    Add-Text $When ($X + $W - $whenW) ($Y.Value - 1) 'F2' 7.4 $FAINT 0.6
  }
  $Y.Value += 10.5
  if ($Role) { Add-Text $Role $X ($Y.Value) 'F2' 8.4 $INK; $Y.Value += 11 }
  foreach ($b in $Bullets) { Add-Bullet $b $X $W $Y }
  if ($Meta) {
    $Y.Value += 1.5
    Add-Body $Meta $X $W $Y 7.6 $FAINT 9.2
  }
  $Y.Value += 8
}

# ---- main column ------------------------------------------------------------
$ref = [ref]$mainY

Add-Heading 'Profile' $MAIN_X $MAIN_W $ref
Add-Body ('Information Technology student who works at the point where a project holds ' +
          'together: the schedule, the screens and the defects. Three team builds, three ' +
          'seats - running the project on a browser game, designing the interface on an ' +
          'evaluation platform, and owning quality assurance on a lost-and-found service.') $MAIN_X $MAIN_W $ref
$mainY += 8

Add-Heading 'Project Experience' $MAIN_X $MAIN_W $ref

Add-Entry 'Emberfall' '2026' 'Project Manager' @(
  'Led a student team through a full turn-based RPG build, from concept and scope to a playable public release.',
  'Divided the work across the team, tracked progress against the deadline, and decided what shipped and what was cut.',
  'Held the requirement that the game run properly on phones and tablets - touch layout, landscape and fullscreen - not only on desktop.'
) 'emberfall-rho.vercel.app  |  JavaScript, HTML5, CSS3, Web Audio API, SVG' $MAIN_X $MAIN_W $ref

Add-Entry 'Evaluate CEC' '2026' 'UI/UX Designer' @(
  'One of the designers on a web platform replacing the paper teacher-evaluation process at Cebu Eastern College.',
  'Designed the evaluation flow end to end: registration by program, year level and section, through star ratings and optional anonymous comments to submission.',
  'Paced a long form so it stays completable, and contributed to the administrator dashboard covering ratings, program averages and sentiment.'
) 'evaluate-cec.vercel.app  |  UI design, user flows, forms, Figma' $MAIN_X $MAIN_W $ref

Add-Entry 'FindIt' '2026' 'Tester / Quality Assurance' @(
  'Owned QA for a community lost-and-found platform covering Cebu, Manila, Davao and twenty more cities.',
  'Wrote and ran test cases across thirteen item categories, the search and the report flow.',
  'Concentrated on the claim path - proof submission, owner verification, and the ways a wrong claim could pass - then verified fixes and ran regression on desktop and mobile.'
) 'findit-ph.vercel.app  |  Test planning, bug reporting, regression, cross-device' $MAIN_X $MAIN_W $ref

Add-Heading 'Education' $MAIN_X $MAIN_W $ref
Add-Entry 'BS Information Technology' 'Ongoing' '' @(
  'Coursework in software development, systems analysis and design, and collaborative project work.'
) 'Cebu Eastern College - Cebu City, Philippines' $MAIN_X $MAIN_W $ref

# ---- side column ------------------------------------------------------------
# The portrait heads the narrow column; the main column keeps its full height.
if ($jpeg) {
  $phW = $SIDE_W
  $phH = $phW * 5.0 / 4.0
  Add-Image $SIDE_X $sideY $phW $phH
  Add-Frame $SIDE_X $sideY $phW $phH $INK 0.8
  $sideY += $phH + 18
}

$sref = [ref]$sideY

Add-Heading 'Core Skills' $SIDE_X $SIDE_W $sref
$groups = @(
  @{ t = 'Project Management'; d = 'Scoping, task breakdown, scheduling, delegation, documentation, stand-ups' },
  @{ t = 'UI / UX Design';     d = 'Wireframing, user flows, prototyping, design systems, usability' },
  @{ t = 'Quality Assurance';  d = 'Test planning, test cases, bug reporting, regression, edge cases' }
)
foreach ($g in $groups) {
  Add-Text $g.t $SIDE_X ($sref.Value) 'F2' 8.5 $INK
  $sref.Value += 10
  Add-Body $g.d $SIDE_X $SIDE_W $sref 8.1 $SOFT 9.8
  $sref.Value += 6
}
$sref.Value += 2

function Add-List {
  param([string]$Title, [string[]]$Items, [ref]$Y)
  Add-Heading $Title $SIDE_X $SIDE_W $Y
  foreach ($it in $Items) {
    foreach ($line in (Split-Lines $it $SIDE_W 8.1 $false)) {
      Add-Text $line $SIDE_X ($Y.Value) 'F1' 8.1 $SOFT
      $Y.Value += 9.8
    }
    Add-Rect $SIDE_X ($Y.Value - 5) $SIDE_W 0.4 $RULE
    $Y.Value += 4
  }
  $Y.Value += 6
}

Add-List 'Tools' @('Figma', 'Git & GitHub', 'HTML, CSS, JavaScript', 'Vercel', 'Google Workspace') $sref
Add-List 'Strengths' @('Keeping a peer team aligned', 'Turning dense workflows into usable screens', 'Clear, reproducible defect reports', 'Mobile-first thinking', 'Finishing to a deadline') $sref
Add-List 'Languages' @('English', 'Filipino', 'Cebuano') $sref

# ---- footer rule
$footY = $PH - 40
Add-Rect $ML $footY ($PW - $ML - $MR) 0.6 $RULE
Add-Text 'Ralph Lorence Racho - Curriculum Vitae' $ML ($footY + 11) 'F1' 7.4 $FAINT
$fw = Get-TextWidth 'ralphracho123@gmail.com' 7.4 $false
Add-Text 'ralphracho123@gmail.com' ($PW - $MR - $fw) ($footY + 11) 'F1' 7.4 $FAINT

Write-Host ("main column ends at y=" + [math]::Round($mainY,1) + " / side at y=" + [math]::Round($sideY,1) + " (page is " + [math]::Round($PH,1) + ", footer at " + [math]::Round($footY,1) + ")")

# ============================================================ assemble PDF ===
$content = $ops.ToString()
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

$objects = @()
$objects += "<< /Type /Catalog /Pages 2 0 R >>"
$objects += "<< /Type /Pages /Kids [3 0 R] /Count 1 >>"
$xobj = if ($jpeg) { ' /XObject << /Im1 8 0 R >>' } else { '' }
$objects += "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $PW $PH] /Resources << /Font << /F1 5 0 R /F2 6 0 R /F3 7 0 R >>$xobj >> /Contents 4 0 R >>"
$objects += "<< /Length $($latin1.GetByteCount($content)) >>`nstream`n$content`nendstream"
$objects += "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
$objects += "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"
$objects += "<< /Type /Font /Subtype /Type1 /BaseFont /Times-Bold /Encoding /WinAnsiEncoding >>"

# Latin-1 is a straight byte<->char map, so the JPEG survives the round trip
# through the string builder untouched.
if ($jpeg) {
  $objects += "<< /Type /XObject /Subtype /Image /Width $jpegW /Height $jpegH /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length $($jpeg.Length) >>`nstream`n$($latin1.GetString($jpeg))`nendstream"
}

$pdf = New-Object System.Text.StringBuilder
$null = $pdf.Append("%PDF-1.4`n%" + [char]0xE2 + [char]0xE3 + [char]0xCF + [char]0xD3 + "`n")

$offsets = @(0)
for ($i = 0; $i -lt $objects.Count; $i++) {
  $offsets += $latin1.GetByteCount($pdf.ToString())
  $null = $pdf.Append("$($i + 1) 0 obj`n$($objects[$i])`nendobj`n")
}

$xrefPos = $latin1.GetByteCount($pdf.ToString())
$null = $pdf.Append("xref`n0 $($objects.Count + 1)`n")
$null = $pdf.Append("0000000000 65535 f `n")
for ($i = 1; $i -le $objects.Count; $i++) {
  $null = $pdf.Append(("{0:D10} 00000 n `n" -f $offsets[$i]))
}
$null = $pdf.Append("trailer`n<< /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xrefPos`n%%EOF")

[System.IO.File]::WriteAllBytes($outPath, $latin1.GetBytes($pdf.ToString()))
Write-Host "Wrote $outPath ($([math]::Round((Get-Item $outPath).Length/1KB,1)) KB)"
