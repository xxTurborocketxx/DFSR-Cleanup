# Benutzer nach dem ConflictAndDeleted-Pfad fragen
$inputPath = Read-Host "Bitte den Pfad zum ConflictAndDeleted-Ordner eingeben"

# Prüfen, ob der Pfad existiert
if (-Not (Test-Path $inputPath)) {
    Write-Error "Der angegebene Pfad existiert nicht. Skript wird beendet."
    exit
} else {
	Write-Host "Der angegebene Pfad existiert. Bitte warten..."
}

# Pfad für langpfad-Kompatibilität anpassen
# Wenn der Pfad nicht schon \\?\ beginnt, hinzufügen
if ($inputPath -notmatch '^\\\\\?\\') {
    $ConflictPath = "\\?\$inputPath"
} else {
    $ConflictPath = $inputPath
}

# Sicherstellen, dass der Pfad mit \* endet, damit nur Inhalt gelöscht wird
if ($ConflictPath -notmatch '\\\*$') {
    if ($ConflictPath[-1] -ne '\') { $ConflictPath += '\' }
    $ConflictPath += '*'
}

# Vorschau: Dateien zählen und Gesamtgröße berechnen
$items = Get-ChildItem -Path $ConflictPath -Recurse -Force -ErrorAction SilentlyContinue
$totalFiles = ($items | Where-Object { -not $_.PSIsContainer }).Count
$totalFolders = ($items | Where-Object { $_.PSIsContainer }).Count
$totalSizeMB = [math]::Round(($items | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

Write-Host "`nVorschau:"
Write-Host "Dateien: $totalFiles"
Write-Host "Ordner: $totalFolders"
Write-Host "Gesamtgroesse: $totalSizeMB MB"

# Bestätigung vor dem Löschen
$confirm = Read-Host "`nMoechten Sie diese Dateien wirklich loeschen? (J/N)"
if ($confirm -notmatch '^[Jj]$') {
    Write-Host "Loeschvorgang abgebrochen."
    exit
}

Write-Host "Bereinige ConflictAndDeleted-Ordner: $ConflictPath"

# Stoppe DFSR-Dienst (nur lokale Bereinigung)
Stop-Service DFSR -Force

# Alle Dateien/Ordner rekursiv auflisten
$items = Get-ChildItem -Path $ConflictPath -Recurse -Force

foreach ($item in $items) {
    try {
        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
        Write-Host "Geloescht: $($item.FullName)"
    } catch {
        Write-Warning "Nicht geloescht (Zugriff verweigert oder gesperrt): $($item.FullName)"
    }
}

# DFSR-Dienst wieder starten
Start-Service DFSR

Write-Host "Bereinigung abgeschlossen. Dateien mit Zugriff verweigert wurden übersprungen."

#Vibecoded with love by Tim Geywitz + ChatGPT lol