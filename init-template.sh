#!/bin/bash

app_name="app"
src_name="src"

mkdir -p $app_name
mkdir -p "$app_name/$src_name"

# Créer le Dockerfile
cat <<EOF > Dockerfile
FROM XXXXXXX

WORKDIR /$app_name

COPY $app_name/ ./

RUN pip install --upgrade pip && pip install -r requirements.txt && pip install .
EOF

# Créer le .dockerignore
cat <<EOF > .dockerignore
$src_name.egg-info
setup.py
init.sh
venv
__pycache__
EOF

# Créer les fichiers requirements.txt et __init__.py main.py
touch "$app_name/requirements.txt"
touch "$app_name/$src_name/main.py"
touch "$app_name/$src_name/__init__.py"

# Créer le fichier setup.py
cat <<EOF > "$app_name/setup.py"
from setuptools import setup, find_packages

setup(
    name='$src_name',
    version='1.0.0',
    packages=find_packages(),
)
EOF

# Configurer l'environnement virtuel Python
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -e "$app_name"
