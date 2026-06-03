# add_copyright.ps1
# Agrega el header de copyright a todos los archivos .dart del proyecto
# Ejecutar desde la raiz del proyecto: .\add_copyright.ps1

$header = "// Copyright (c) 2026 Gianfranco Mongiello. MIT License.`n// https://github.com/GianfrancoMongiell0/FinVE`n"

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if (-not $content.StartsWith("// Copyright")) {
        $newContent = $header + "`n" + $content
        Set-Content $file.FullName $newContent -NoNewline
        Write-Host "✓ $($file.FullName)"
        $count++
    } else {
        Write-Host "- $($file.FullName) (ya tiene header)"
    }
}

Write-Host ""
Write-Host "Listo. $count archivos actualizados."