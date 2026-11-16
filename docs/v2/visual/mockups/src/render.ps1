# Renders each screen in screens.html to docs/v2/visual/mockups/<id>.png with headless Edge.
# Portrait screens: 360x640 CSS at 3x (1080x1920). Landscape: 844x390 CSS at 2x (1688x780).
$ErrorActionPreference = "Continue" # Edge writes harmless warnings to stderr
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
	Where-Object { Test-Path $_ } | Select-Object -First 1
$src = (Resolve-Path "$PSScriptRoot\screens.html").Path -replace '\\', '/'
$out = (Resolve-Path "$PSScriptRoot\..").Path
$screens = @{
	"phone-home" = @(360, 640, 3); "phone-kebun" = @(360, 640, 3); "phone-kebun-alat" = @(360, 640, 3); "phone-pinjol" = @(360, 640, 3)
	"phone-tugas" = @(360, 640, 3); "phone-curang" = @(360, 640, 3); "phone-dekor" = @(360, 640, 3); "phone-lapor" = @(360, 640, 3)
	"hud" = @(844, 390, 2); "hud-penuh" = @(844, 390, 2); "toko-bibit" = @(844, 390, 2); "papan" = @(844, 390, 2)
	"minigame" = @(844, 390, 2); "razia" = @(844, 390, 2); "razia-hasil" = @(844, 390, 2)
}
foreach ($id in $screens.Keys) {
	$w, $h, $s = $screens[$id]
	& $edge --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=4000 "--force-device-scale-factor=$s" "--window-size=$w,$h" "--screenshot=$out\$id.png" "file:///$src#$id" 2>&1 | Out-Null
	Write-Output "$id -> $out\$id.png"
}
