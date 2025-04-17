#!/bin/bash

# Navigate to the directory where the script is located
cd "$(dirname "$0")"

# Prompt the user to enter a name for the source directory
# Default to "src" if no input is provided
echo ""
read -rp "Enter a name for the source directory (empty for 'src') : " input_src_name
if [[ -z "$input_src_name" ]]; then
    src_name="src"
elif [[ "$input_src_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    src_name="$input_src_name"
else
    echo -e "\n\033[1;31mInvalid name. Installation canceled.\033[0m\n"
    exit 1
fi

# Display the directory where the files will be installed
echo -e "\nThe files will be installed in the directory: \033[1;32m$(pwd)\033[0m\n"

# Ask the user for confirmation to proceed
while true; do
    read -rp "Do you want to continue? (Y/n): " response
    case "$response" in
        [YyNn]) break ;; # Accept only 'Y', 'y', 'N', or 'n'
        *)
            # Move the cursor up one line and clear the line
            printf "\033[1A"  # Move up one line
            printf "\033[2K"  # Clear the entire line
            ;;
    esac
done

# Handle the user's response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    echo -e ""
elif [[ "$response" == "n" || "$response" == "N" ]]; then
    echo -e "\n\033[1;31mInstallation canceled.\033[0m\n"
    exit 1
fi

# Create the source directory
mkdir -p "$src_name"

# Generate a Dockerfile with the necessary configuration
cat <<EOF > Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip && pip install -r requirements.txt && pip install .
EOF

# Generate a .dockerignore file to exclude unnecessary files from the Docker build context
cat <<EOF > .dockerignore
# Python cache files
**/__pycache__/
**/*.py[cod]
**/*.class

# Local virtual environments
**/venv/
**/.env/
**/.venv/

# Packaging metadata
**/*.egg-info/
**/*.egg
**/dist/
**/build/

# Optional: log or temporary files
**/*.log
**/*.tmp
**/*.swp

Dockerfile
init-template.sh
EOF

# Create empty files for requirements.txt, main.py, and __init__.py
touch "requirements.txt"
touch "$src_name/main.py"
touch "$src_name/__init__.py"

# Generate a setup.py file for the Python project
cat <<EOF > "setup.py"
from setuptools import setup, find_packages

setup(
    name='$src_name',
    version='1.0.0',
    packages=find_packages(where="$src_name"),
    package_dir={"": "$src_name"},
)
EOF

# Set up a Python virtual environment and install dependencies
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -e .

# Notify the user that the project setup is complete
echo -e "\nProject ready, you can activate the environment with : \033[1;32msource $(pwd)/venv/bin/activate\033[0m\n"
