1|#!/bin/bash
2|set -e
3|
4|PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
5|SKILL_SRC="$PROJECT_DIR/skills/research-report"
6|SKILL_DST="$HOME/.hermes/skills/note-taking/research-report"
7|
8|echo ""
9|echo "============================================"
10|echo "  Research Skill - macOS Setup (dev only)"
11|echo "============================================"
12|echo ""
13|
14|# ── 1. Check prerequisites ──
15|echo "[1/4] Checking prerequisites..."
16|
17|if command -v hermes &>/dev/null; then
18|    echo "  [ OK ] Hermes Agent"
19|else
20|    echo "  [WARN] Hermes Agent not found (needed for cron registration)"
21|fi
22|
23|echo "  [INFO] agent-browser is required on the Windows target machine"
24|echo ""
25|
26|# ── 2. Create directories ──
27|echo "[2/4] Creating directories..."
28|mkdir -p "$PROJECT_DIR/reports"
29|echo "  [ OK ] reports/"
30|echo ""
31|
32|# ── 3. Install skill ──
33|echo "[3/4] Installing skill to Hermes Agent..."
34|rm -rf "$SKILL_DST"
35|mkdir -p "$SKILL_DST"
36|cp -r "$SKILL_SRC/"* "$SKILL_DST/"
37|sed -i '' "s|{PROJECT_DIR}|$PROJECT_DIR|g" "$SKILL_DST/SKILL.md"
38|echo "  [ OK ] Installed to $SKILL_DST"
39|echo ""
40|
41|# ── 4. Summary ──
42|echo "[4/4] Done."
43|echo ""
44|echo "============================================"
45|echo "  Note: This skill deploys to Windows."
46|echo "  Mac setup is for development review only."
47|echo "============================================"
48|echo ""
49|