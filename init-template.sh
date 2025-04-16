#!/bin/bash

app_name="app"
src_name="src"

# mkdir -p $app_name
mkdir -p $src_name

# Créer le Dockerfile
cat <<EOF > Dockerfile
FROM python:3.11-slim

WORKDIR /$app_name

COPY . .

RUN pip install --upgrade pip && pip install -r requirements.txt && pip install .
EOF

# Créer le .dockerignore
cat <<EOF > .dockerignore
# Cache files python
**/__pycache__/
**/*.py[cod]
**/*.class

# local virtual env
**/venv/
**/.env/
**/.venv/

# Metadata packaging
**/*.egg-info/
**/*.egg
**/dist/
**/build/

# Optional :log or temp files
**/*.log
**/*.tmp
**/*.swp

Dockerfile
init-template.sh
EOF

# Créer les fichiers requirements.txt et __init__.py main.py
touch "requirements.txt"
touch "$src_name/main.py"
touch "$src_name/__init__.py"

# Créer le fichier setup.py
cat <<EOF > "setup.py"
from setuptools import setup, find_packages

setup(
    name='$src_name',
    version='1.0.0',
    packages=find_packages(where="$src_name"),
    package_dir={"": "$src_name"},
)
EOF

# Configurer l'environnement virtuel Python
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -e .

echo 'Project ready, activate the env with : source venv/bin/activate '
