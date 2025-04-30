#!/bin/bash

# -------------------------------------------------------
#                  INIT-PROJECT TEMPLATE
# Bootstrap a Python project with optional Docker files,
# structure (src/tests), virtual environment, Git setup.
# -------------------------------------------------------

cd "$(dirname "$0")"

# --------------------[ CONFIGURATION ]--------------------

# Default flags
auto=false
verbose=false
help=false

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --auto) auto=true ;;
        --verbose) verbose=true ;;
        -h|--help) help=true ;;
    esac
done

# Help message
if [[ "$help" == true ]]; then
    echo -e "
Usage: ./init-template.sh [options]

Options:
  --auto        : Auto-accept all prompts with default values
  --verbose     : Show detailed pip installation outputs
  -h, --help    : Show this help message
"
    exit 0
fi

# --------------------[ STYLES ]--------------------

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
ORANGE='\e[38;5;208m'
BOLD="\033[1m"
RESET="\033[0m"

# Color formatting helpers
to_blue()   { echo -e "${BLUE}$1${RESET}"; }
to_green()  { echo -e "${GREEN}$1${RESET}"; }
to_red()    { echo -e "${RED}$1${RESET}"; }
to_orange() { echo -e "${ORANGE}$1${RESET}"; }
to_bold()   { echo -e "${BOLD}$1${RESET}"; }

# --------------------[ UTILITY FUNCTIONS ]--------------------

ask_yes_no() {
    local prompt="➔ $1"
    local default="$2"
    local response

    if [[ "$auto" == true ]]; then
        echo -e "$prompt $(to_green Y) $(to_orange \(auto\))"
        return 0
    fi

    while true; do
        read -rp "$prompt " response
        response="${response:-$default}"
        case "$response" in
            [Yy])
                printf "\033[1A\033[2K"
                echo -e "$prompt $(to_green Y)"
                return 0
                ;;
            [Nn])
                printf "\033[1A\033[2K"
                echo -e "$prompt $(to_red N)"
                return 1
                ;;
            *)
                printf "\033[1A\033[2K" ;;
        esac
    done
}

validate_step() {
    echo -e "✅ $1"
}

ask_package_name() {
    local prompt="➔  Source directory (empty for 'src') : "
    local input

    if [[ "$auto" == true ]]; then
        src_name="src"
        echo -e "$prompt$(to_blue "$src_name") $(to_orange \(auto\))"
        return
    fi

    read -rp "$prompt" input
    input="${input:-src}"

    if [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        printf "\033[1A\033[2K"
        echo -e "$prompt$(to_blue "$input")"
        src_name="$input"
    else
        echo -e "\n$(to_red "Invalid name. Installation canceled.")\n"
        exit 1
    fi
}

# --------------------[ GIT SETUP ]--------------------

init_git() {
    git init > /dev/null 2>&1
    validate_step "Initialized Git repository"

    git config user.name &> /dev/null || git config user.name "Your Name"
    git config user.email &> /dev/null || git config user.email "you@example.com"
    validate_step "Configured Git user (if missing)"

    cat <<EOF > .gitignore
# Python
__pycache__/
*.py[cod]

# Virtual env
venv/
.env/
.venv/

# Build
*.egg-info/
build/
dist/

# Logs, IDEs
*.log
*.swp
*.tmp
.idea/
.vscode/
EOF
    validate_step "Created .gitignore"

    git add . > /dev/null
    git commit -m "Initial commit" > /dev/null
    git branch -M main
    validate_step "First commit created on 'main' branch"
}

# --------------------[ PYTHON BINARY SELECTION ]--------------------

detect_python_binaries() {
    mapfile -t python_bins < <(
        compgen -c python | sort -u | grep -E '^python[0-9.]*$' | while read -r bin; do
            path=$(command -v "$bin" 2>/dev/null)
            if [[ -x "$path" ]]; then
                version=$("$path" --version 2>&1)
                echo "$path|$version"
            fi
        done
    )
}

select_python_binary() {
    default_path=$(command -v python3)
    default_version=$($default_path --version 2>&1)
    echo -e "➔  Detected default python interpreter : $(to_bold "$default_version") -> $(to_blue "$default_path")  "

    if [[ "$auto" == true ]]; then
        python_binary="$default_path"
        python_version="$default_version"
        echo -e "Using $(to_blue "$python_binary") $(to_orange \(auto\))"
        return
    fi

    if ask_yes_no " Use this Python interpreter? [Y/n] :" "Y"; then
        python_binary="$default_path"
        python_version="$default_version"
        return
    fi

    detect_python_binaries

    echo -e "\n$(to_bold "Available Python binaries:")"
    for i in "${!python_bins[@]}"; do
        path="${python_bins[$i]%%|*}"
        version="${python_bins[$i]##*|}"
        echo "  [$((i+1))] $(to_bold "$version") -> $(to_blue "$path")"
    done
    echo "  $(to_green "[M] Enter manually")"

    while true; do
        read -rp $'\n➔  Choose a Python interpreter [number/M] : ' choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#python_bins[@]} )); then
            python_binary="${python_bins[$((choice-1))]%%|*}"
            python_version="${python_bins[$((choice-1))]##*|}"
            break
        elif [[ "$choice" =~ ^[Mm]$ ]]; then
            read -rp "Enter full path to the Python binary: " manual_path
            if [[ -x "$manual_path" ]]; then
                python_binary="$manual_path"
                python_version=$("$manual_path" --version 2>&1)
                break
            else
                echo -e "$(to_red "Invalid path or not executable.")"
            fi
        else
            echo -e "$(to_red "Invalid choice. Try again.")"
        fi
    done

    echo -e "Selected: $(to_blue "$python_binary") ($python_version)"
}

# --------------------[ SCRIPT EXECUTION ]--------------------

echo ""
[ "$auto" = true ] && echo -e "$(to_orange "Automatic install")\n"

select_python_binary
ask_package_name

generate_dockerfiles=false
if ask_yes_no " Generate Dockerfile and .dockerignore? [Y/n] :" "Y"; then
    generate_dockerfiles=true
fi

setup_git=false
if ask_yes_no " Initialize Git repository? [Y/n] :" "Y"; then
    setup_git=true
fi

install_path="$(pwd)"
echo -e "\n--- 🛠️  $(to_bold "Configuration Summary") ---"
echo -e "🐍 Python version      : $(to_bold "$python_version")"
echo -e "📄 Python base binary  : $(to_blue "$python_binary")"
echo -e "📁 Installation path   : $(to_blue "$install_path")"
echo -e "📦 Package name        : $(to_blue "$src_name")"
echo -e "🐳 Docker config files : $([[ "$generate_dockerfiles" == true ]] && to_green "Yes" || to_red "No")"
echo -e "🐙 Git initialized     : $([[ "$setup_git" == true ]] && to_green "Yes" || to_red "No")"
echo ""

if ! ask_yes_no " Continue ? [Y/n] :" "Y"; then
    echo -e "\n$(to_red "Installation canceled.")\n"
    exit 1
fi

echo -e "\n--- 📁 PROJECT ----------------"
mkdir -p "$src_name"
touch "$src_name/__init__.py"
touch "$src_name/main.py"

mkdir -p "$src_name/tests"
touch "$src_name/tests/test_main.py"

validate_step "Created $src_name package tree"

if [[ "$generate_dockerfiles" == true ]]; then
    cat <<EOF > Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip && pip install -r requirements.txt && pip install .
EOF

    cat <<EOF > .dockerignore
**/__pycache__/
**/*.py[cod]
**/*.class
**/venv/
**/.env/
**/.venv/
**/*.egg-info/
**/*.egg
**/dist/
**/build/
**/*.log
**/*.tmp
**/*.swp
Dockerfile
init-template.sh
EOF
    echo -e "\n--- 🐳 DOCKER -----------------"
    validate_step "Created Dockerfile and .dockerignore"
fi

cat <<EOF > "requirements.txt"
pytest
loguru
icecream
EOF

cat <<EOF > "setup.py"
from setuptools import setup, find_packages

setup(
    name='$src_name',
    version='1.0.0',
    packages=find_packages(),
)
EOF
echo -e "\n--- 🐍 PYTHON -----------------"
validate_step "Created setup.py and requirements.txt"

"$python_binary" -m venv venv
validate_step "Virtual environment created"

source venv/bin/activate

if [[ "$verbose" == true ]]; then
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install -e .
else
    pip install --upgrade pip > /dev/null 2>&1
    pip install -r requirements.txt > /dev/null 2>&1
    pip install -e . > /dev/null 2>&1
fi
validate_step "Dependencies installed"

if [[ "$setup_git" == true || "$auto" == true ]]; then
    echo -e "\n--- 🐙 GIT --------------------"
    init_git
fi

echo -e "\n✅ $(to_green "Project ready ")"
echo -e "\nActivate venv : $(to_green "source $(pwd)/venv/bin/activate")\n"
