#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_SRC="$PROJECT_DIR/skills/research-skill"
SKILL_DST="$HOME/.hermes/skills/note-taking/research-skill"

echo ""
echo "============================================"
echo "  Research Skill - macOS Setup (dev only)"
echo "============================================"
echo ""

# ── 1. Check prerequisites ──
echo "[1/4] Checking prerequisites..."

if command -v hermes &>/dev/null; then
    echo "  [ OK ] Hermes Agent"
else
    echo "  [WARN] Hermes Agent not found (needed for cron registration)"
fi

echo "  [INFO] agent-browser is required on the Windows target machine"
echo ""

# ── 2. Create directories ──
echo "[2/4] Creating directories..."
mkdir -p "$PROJECT_DIR/reports"
echo "  [ OK ] reports/"
echo ""

# ── 3. Install skill ──
echo "[3/4] Installing skill to Hermes Agent..."
rm -rf "$SKILL_DST"
mkdir -p "$SKILL_DST"
cp -r "$SKILL_SRC/"* "$SKILL_DST/"
sed -i '' "s|{PROJECT_DIR}|$PROJECT_DIR|g" "$SKILL_DST/SKILL.md"
echo "  [ OK ] Installed to $SKILL_DST"
echo ""

# ── 4. Summary ──
echo "[4/4] Done."
echo ""
echo "============================================"
echo "  Note: This skill deploys to Windows."
echo "  Mac setup is for development review only."
echo "============================================"
echo ""
