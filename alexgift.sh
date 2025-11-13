#!/bin/bash
# ============================================================
#  🧠 AI Auto Runner — Alex Hunter (Pro) (Auto-directory-run enabled)
#  Purpose: Smart auto-detect & execute files (and auto-run common scripts inside directories)
#  Version: 3.2
# ============================================================

# -------- COLORS (cyanhighlight banner like before) --------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
RESET='\033[0m'

# -------- Banner (restored style) --------
print_banner() {
  echo -e "${CYAN}"
  echo "┌────────────────────────────────────────────────────────┐"
  echo "│   •  AI AUTO RUNNER SYSTEM  •  Alex Hunter (Pro)       │"
  echo "│              Smart • Clean • Professional              │"
  echo "└────────────────────────────────────────────────────────┘"
  echo -e "${RESET}"
}

# -------- Known auto-run candidates (searched in-order) --------
AUTO_RUN_CANDIDATES=(
  "install.sh" "setup.sh" "run.sh" "start.sh" "xphisher.sh" "make-deb.sh"
  "main.sh" "deploy.sh" "install" "run" "start" "setup.py" "setup"
)

# -------- Utility: strip surrounding quotes --------
strip_quotes() {
  s="$1"
  s="${s%\"}"; s="${s#\"}"
  s="${s%\' }"; s="${s#\'}"
  printf '%s' "$s"
}

# -------- Smart runner --------
run_file() {
  local filename
  filename="$(strip_quotes "$1")"

  if [ ! -e "$filename" ]; then
    echo -e "${RED}❌ Not found:${RESET} '$filename'"
    return 1
  fi

  # If it's a directory -> try auto-run known scripts inside
  if [ -d "$filename" ]; then
    echo -e "${CYAN}📁 Detected directory:${RESET} '$filename'"
    echo -e "${BLUE}🔎 Inspecting contents...${RESET}"
    ls -la -- "$filename"
    echo

    # Search for candidate run scripts
    for candidate in "${AUTO_RUN_CANDIDATES[@]}"; do
      if [ -f "$filename/$candidate" ]; then
        echo -e "${GREEN}➡ Found runner:${RESET} '$candidate' inside '$filename'"
        # If executable run directly, else try interpreter detection
        if [ -x "$filename/$candidate" ]; then
          echo -e "${CYAN}🔹 Running: ./${candidate} (inside $filename)${RESET}"
          (cd "$filename" && ./"$candidate")
          return $?
        else
          echo -e "${CYAN}🔹 Attempting to run with smart detection...${RESET}"
          (cd "$filename" && run_file "./$candidate")
          return $?
        fi
      fi
    done

    echo -e "${YELLOW}💡 Hint:${RESET} cd '$filename' && ls  (look for install/run scripts). No known runner found automatically."
    return 2
  fi

  # If executable file -> run directly
  if [ -x "$filename" ]; then
    echo -e "${GREEN}🔹 Executable detected — running: ./'$filename'${RESET}"
    echo "--------------------------------------------------------"
    ./"$filename"
    echo "--------------------------------------------------------"
    return $?
  fi

  # Read first line (shebang) safely
  first_line=$(head -n 1 -- "$filename" 2>/dev/null || echo "")

  # Shebang checks
  if [[ "$first_line" == "#!"*"/bash"* || "$first_line" == "#!"*"/sh"* ]]; then
    echo -e "${CYAN}🤖 Shebang detected: Shell script${RESET}"
    echo "--------------------------------------------------------"
    bash -- "$filename"
    echo "--------------------------------------------------------"
    return $?
  fi

  if [[ "$first_line" == "#!"*"/python"* ]]; then
    echo -e "${CYAN}🤖 Shebang detected: Python script${RESET}"
    echo "--------------------------------------------------------"
    python -- "$filename"
    echo "--------------------------------------------------------"
    return $?
  fi

  if [[ "$first_line" == "#!"*"/php"* ]]; then
    echo -e "${CYAN}🤖 Shebang detected: PHP script${RESET}"
    echo "--------------------------------------------------------"
    php -- "$filename"
    echo "--------------------------------------------------------"
    return $?
  fi

  if [[ "$first_line" == "#!"*"/node"* || "$first_line" == "#!"*"/nodejs"* ]]; then
    echo -e "${CYAN}🤖 Shebang detected: Node.js script${RESET}"
    echo "--------------------------------------------------------"
    node -- "$filename"
    echo "--------------------------------------------------------"
    return $?
  fi

  # Try by extension
  ext="${filename##*.}"
  if [[ "$ext" == "py" ]]; then
    echo -e "${CYAN}🤖 Extension .py detected: Running with python${RESET}"
    python -- "$filename" && return 0
  elif [[ "$ext" == "sh" ]]; then
    echo -e "${CYAN}🤖 Extension .sh detected: Running with bash${RESET}"
    bash -- "$filename" && return 0
  elif [[ "$ext" == "php" ]]; then
    echo -e "${CYAN}🤖 Extension .php detected: Running with php${RESET}"
    php -- "$filename" && return 0
  elif [[ "$ext" == "js" ]]; then
    echo -e "${CYAN}🤖 Extension .js detected: Running with node${RESET}"
    node -- "$filename" && return 0
  elif [[ "$ext" == "html" || "$ext" == "htm" ]]; then
    echo -e "${CYAN}🌐 Extension .html detected: Opening${RESET}"
    if command -v termux-open >/dev/null 2>&1; then
      termux-open -- "$filename" && return 0
    else
      echo -e "${YELLOW}⚠ termux-open not found. Try opening the file manually.${RESET}"
    fi
  fi

  # Fallback: try common interpreters in safe order
  echo -e "${YELLOW}🔎 No shebang/exec. Trying common interpreters (bash → python → php → node) ...${RESET}"
  if command -v bash >/dev/null 2>&1; then
    echo -e "${BLUE}→ bash '$filename'${RESET}"
    bash -- "$filename" && return 0
  fi
  if command -v python >/dev/null 2>&1; then
    echo -e "${BLUE}→ python '$filename'${RESET}"
    python -- "$filename" && return 0
  fi
  if command -v php >/dev/null 2>&1; then
    echo -e "${BLUE}→ php '$filename'${RESET}"
    php -- "$filename" && return 0
  fi
  if command -v node >/dev/null 2>&1; then
    echo -e "${BLUE}→ node '$filename'${RESET}"
    node -- "$filename" && return 0
  fi

  echo -e "${RED}❗ Couldn't auto-run '${filename}'.${RESET}"
  echo -e "${YELLOW}Suggestions:${RESET}"
  echo "  1) Add a shebang line on top (e.g. #!/usr/bin/env python3 or #!/usr/bin/env bash)."
  echo "  2) Make executable: chmod +x '$filename' and run ./'${filename}'."
  echo "  3) Run manually: bash '$filename'  OR  python '$filename'  OR  php '$filename'."
  return 2
}

# -------- Main --------
print_banner

# If filename passed as argument -> auto mode
if [ -n "$1" ]; then
  target="$1"
  run_file "$target"
  exit $?
fi

# Interactive mode
echo -e "${BLUE}📂 Scanning directory...${RESET}"
ls --color=auto
echo "--------------------------------------------------------"
echo -ne "${CYAN}👉 Enter filename or directory to run (you can quote names with spaces): ${RESET}"
read -r filename
if [ -z "$filename" ]; then
  echo -e "${RED}❌ No filename entered. Exiting.${RESET}"
  exit 1
fi

run_file "$filename"
exit $?