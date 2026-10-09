param(
    [string]$Godot = 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe',
    [string[]]$Tests = @('smoke_audio_pack', 'smoke_game_audio', 'smoke_clue_visibility', 'smoke_computer_clue_click'),
    [switch]$VerboseEngine
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testId = [guid]::NewGuid().ToString('N')
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('scene-calibration-audio-' + $testId)
New-Item -ItemType Directory -Path $testRoot | Out-Null
$configuration = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'project.godot'))
$configuration = $configuration -replace 'config/custom_user_dir_name="[^"]*"', ('config/custom_user_dir_name="scene-calibration-audio-test-' + $testId + '"')
[System.IO.File]::WriteAllText((Join-Path $testRoot 'project.godot'), $configuration, [System.Text.UTF8Encoding]::new($false))
# Resolve the existing assets without copying or importing them again. Each run
# gets its own project cache and user:// directory, including options and saves.
foreach ($folder in @('assets', 'data', 'scenes', 'scripts', 'tests', 'addons', 'shaders', 'materials')) {
    $source = Join-Path $projectRoot $folder
    if (Test-Path -LiteralPath $source) {
        New-Item -ItemType Junction -Path (Join-Path $testRoot $folder) -Target $source | Out-Null
    }
}
$testCache = Join-Path $testRoot '.godot'
New-Item -ItemType Directory -Path $testCache | Out-Null
New-Item -ItemType Junction -Path (Join-Path $testCache 'imported') -Target (Join-Path $projectRoot '.godot\imported') | Out-Null
foreach ($name in @('global_script_class_cache.cfg', 'uid_cache.bin', 'scene_groups_cache.cfg')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('.godot\' + $name)) -Destination (Join-Path $testCache $name)
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'icon.svg') -Destination $testRoot
Write-Output ('Isolated test project and logs: ' + $testRoot)
$failed = $false
foreach ($test in $Tests) {
    if ($test -notmatch '^smoke_[a-z_]+$') { throw 'Invalid smoke test name' }
    $stdout = Join-Path $testRoot ($test + '.stdout.log')
    $stderr = Join-Path $testRoot ($test + '.stderr.log')
    $arguments = @('--headless', '--path', ('"' + $testRoot + '"'), '--script', ('res://tests/' + $test + '.gd'))
    if ($test -in @('smoke_clue_visibility', 'smoke_the_scene_menu', 'smoke_start_menu_office', 'smoke_menu_hover', 'smoke_language_settings', 'smoke_terminal_mail', 'smoke_terminal_apps', 'smoke_terminal_desktop', 'smoke_ui_text_fit')) {
        # Rendered mesh occlusion cannot be checked by Godot's headless dummy
        # renderer. Render offscreen with the real Windows/OpenGL driver.
        $arguments = @('--path', ('"' + $testRoot + '"'), '--script', ('res://tests/' + $test + '.gd'), '--audio-driver', 'Dummy', '--rendering-method', 'gl_compatibility', '--resolution', '1280x800', '--position', '-10000,-10000')
    }
    if ($VerboseEngine) { $arguments += '--verbose' }
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    if (-not $process.WaitForExit(60000)) {
        $process.Kill()
        $null = $process.WaitForExit(3000)
        $failed = $true
        Write-Output ($test + ': timed out')
    } else {
        $process.Refresh()
        Write-Output ($test + ': exit ' + $process.ExitCode)
        if ($process.ExitCode -ne 0) { $failed = $true }
    }
    Get-Content -LiteralPath $stdout | Select-Object -Last 15
    $errorText = (Get-Content -LiteralPath $stderr) -join "`n"
    if ($errorText.Length -gt 0) {
        Write-Output (($errorText -split "`n" | Select-Object -First 45) -join "`n")
        if ($errorText -match 'SCRIPT ERROR|ERROR:') { $failed = $true }
    }
}
if ($failed) { exit 1 }
