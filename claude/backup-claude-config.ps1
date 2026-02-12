# Backup de configuración de Claude Code (Windows PowerShell)
# Uso: powershell -ExecutionPolicy Bypass -File backup-claude-config.ps1

$ClaudeDir = "$env:USERPROFILE\.claude"
$BackupDir = "$PSScriptRoot\backup"

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

Write-Host "=== Backup de Claude Code config ===" -ForegroundColor Cyan

# settings.json
if (Test-Path "$ClaudeDir\settings.json") {
    Copy-Item "$ClaudeDir\settings.json" "$BackupDir\settings.json" -Force
    Write-Host "[OK] settings.json" -ForegroundColor Green
}

# installed_plugins.json
if (Test-Path "$ClaudeDir\plugins\installed_plugins.json") {
    Copy-Item "$ClaudeDir\plugins\installed_plugins.json" "$BackupDir\installed_plugins.json" -Force
    Write-Host "[OK] installed_plugins.json" -ForegroundColor Green
}

# Projects (per-project settings, memory)
if (Test-Path "$ClaudeDir\projects") {
    if (Test-Path "$BackupDir\projects") { Remove-Item "$BackupDir\projects" -Recurse -Force }
    Copy-Item "$ClaudeDir\projects" "$BackupDir\projects" -Recurse -Force
    Write-Host "[OK] projects\" -ForegroundColor Green
}

# MCP global
if (Test-Path "$env:USERPROFILE\.mcp.json") {
    Copy-Item "$env:USERPROFILE\.mcp.json" "$BackupDir\mcp.json" -Force
    Write-Host "[OK] .mcp.json (global MCP servers)" -ForegroundColor Green
}

# Keybindings
if (Test-Path "$ClaudeDir\keybindings.json") {
    Copy-Item "$ClaudeDir\keybindings.json" "$BackupDir\keybindings.json" -Force
    Write-Host "[OK] keybindings.json" -ForegroundColor Green
}

# Custom commands (slash commands legacy)
if (Test-Path "$ClaudeDir\commands") {
    if (Test-Path "$BackupDir\commands") { Remove-Item "$BackupDir\commands" -Recurse -Force }
    Copy-Item "$ClaudeDir\commands" "$BackupDir\commands" -Recurse -Force
    Write-Host "[OK] commands\" -ForegroundColor Green
}

# Skills (slash commands actual)
if (Test-Path "$ClaudeDir\skills") {
    if (Test-Path "$BackupDir\skills") { Remove-Item "$BackupDir\skills" -Recurse -Force }
    Copy-Item "$ClaudeDir\skills" "$BackupDir\skills" -Recurse -Force
    Write-Host "[OK] skills\" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Backup completado en $BackupDir ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para restaurar despues de reinstalar:"
Write-Host "  1. Instalar Claude Code"
Write-Host "  2. Copy-Item $BackupDir\settings.json $ClaudeDir\"
Write-Host "  3. New-Item -ItemType Directory -Force $ClaudeDir\plugins; Copy-Item $BackupDir\installed_plugins.json $ClaudeDir\plugins\"
Write-Host "  4. Copy-Item $BackupDir\projects $ClaudeDir\projects -Recurse"
Write-Host "  5. Copy-Item $BackupDir\commands $ClaudeDir\commands -Recurse"
Write-Host "  6. Copy-Item $BackupDir\skills $ClaudeDir\skills -Recurse"
Write-Host "  7. Reiniciar Claude Code (los plugins se re-descargan solos)"
