#!/bin/bash
# Backup de configuración de Claude Code
# Uso: bash backup-claude-config.sh

BACKUP_DIR="/home/denis/Documentos/personal/System-Prompt-Collection/claude"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Backup de Claude Code config ==="

# Archivos principales de configuración
cp ~/.claude/settings.json "$BACKUP_DIR/settings.json" 2>/dev/null && echo "[OK] settings.json"
cp ~/.claude/plugins/installed_plugins.json "$BACKUP_DIR/installed_plugins.json" 2>/dev/null && echo "[OK] installed_plugins.json"

# Settings por proyecto (memory, permisos)
if [ -d ~/.claude/projects ]; then
    rsync -a --delete ~/.claude/projects/ "$BACKUP_DIR/projects/" 2>/dev/null && echo "[OK] projects/"
fi

# MCP global (si existe)
if [ -f ~/.mcp.json ]; then
    cp ~/.mcp.json "$BACKUP_DIR/mcp.json" && echo "[OK] .mcp.json (global MCP servers)"
fi

# Keybindings (si existe)
if [ -f ~/.claude/keybindings.json ]; then
    cp ~/.claude/keybindings.json "$BACKUP_DIR/keybindings.json" && echo "[OK] keybindings.json"
fi

echo ""
echo "=== Backup completado en $BACKUP_DIR ==="
echo ""
echo "Para restaurar después de reinstalar:"
echo "  1. Instalar Claude Code"
echo "  2. cp $BACKUP_DIR/settings.json ~/.claude/"
echo "  3. cp $BACKUP_DIR/installed_plugins.json ~/.claude/plugins/"
echo "  4. rsync -a $BACKUP_DIR/projects/ ~/.claude/projects/"
echo "  5. [Opcional] cp $BACKUP_DIR/mcp.json ~/.mcp.json"
echo "  6. Reiniciar Claude Code (los plugins se re-descargan solos)"
