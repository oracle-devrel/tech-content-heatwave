#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

set -e  # Exit script if any command fails

REPO_URL="${REPO_URL}"
REPO_SUBFOLDER="${REPO_SUBFOLDER}"
REPO_BRANCH="${REPO_MAIN}"

# Set path constants
INSTALL_LOGS="/tmp/askme_install.out"
REPO_HOME_FOLDER="/home/opc/demos"
MAIN_SERVICE_NAME="askme.service"
SETUP_SERVICE_NAME="setup.service"
ASKME_FOLDER="$REPO_HOME_FOLDER/$REPO_SUBFOLDER"
ASKME_ENV_PATH="$ASKME_FOLDER/venv"
REQUIREMENTS_FILEPATH="$ASKME_FOLDER/requirements.txt"
MAIN_SERVICE_FILEPATH="$ASKME_FOLDER/$MAIN_SERVICE_NAME"
SETUP_SERVICE_FILEPATH="$ASKME_FOLDER/$SETUP_SERVICE_NAME"
MAIN_FILEPATH="$ASKME_FOLDER/askme.py"
SETUP_FILEPATH="$ASKME_FOLDER/setup.py"

# Install libraries
sudo dnf --disablerepo="*" -y install https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-9.2.0-1.el9.x86_64.rpm >> $INSTALL_LOGS 2>&1
sudo dnf --refresh --disablerepo="*" --enablerepo="ol9_appstream" -y install git >> $INSTALL_LOGS 2>&1
sudo dnf --refresh --disablerepo="*" --enablerepo="ol9_appstream" -y install python3.9 >> $INSTALL_LOGS 2>&1
python3 -m ensurepip >> $INSTALL_LOGS 2>&1
python3 -m pip install --user oci-cli >> $INSTALL_LOGS 2>&1

# Fetch repository content
git init $REPO_HOME_FOLDER >> $INSTALL_LOGS 2>&1
git -C $REPO_HOME_FOLDER remote add -f origin $REPO_URL >> $INSTALL_LOGS 2>&1
git -C $REPO_HOME_FOLDER config core.sparseCheckout true >> $INSTALL_LOGS 2>&1
git -C $REPO_HOME_FOLDER sparse-checkout set $REPO_SUBFOLDER >> $INSTALL_LOGS 2>&1
git -C $REPO_HOME_FOLDER pull origin $REPO_BRANCH >> $INSTALL_LOGS 2>&1

# Install python environment and dependencies
python3 -m venv $ASKME_ENV_PATH >> $INSTALL_LOGS 2>&1
$ASKME_ENV_PATH/bin/pip install -r $REQUIREMENTS_FILEPATH >> $INSTALL_LOGS 2>&1

# Create the services
: > $MAIN_SERVICE_FILEPATH
echo "[Unit]" >> $MAIN_SERVICE_FILEPATH
echo "Description=AskME streamlit application" >> $MAIN_SERVICE_FILEPATH
echo "After=network.target" >> $MAIN_SERVICE_FILEPATH
echo "" >> $MAIN_SERVICE_FILEPATH
echo "[Service]" >> $MAIN_SERVICE_FILEPATH
echo 'Environment="OCI_COMPARTMENT_ID=${OCI_COMPARTMENT_ID}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="OCI_REGION=${OCI_REGION}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="BUCKET_NAME=${BUCKET_NAME}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="VAULT_ID=${VAULT_ID}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="IS_GENAI_REGION=${IS_GENAI_REGION}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="MYSQL_USERNAME_VAULT_SECRET_NAME=${MYSQL_USERNAME_VAULT_SECRET_NAME}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="MYSQL_PASSWORD_VAULT_SECRET_NAME=${MYSQL_PASSWORD_VAULT_SECRET_NAME}"' >> $MAIN_SERVICE_FILEPATH
echo 'Environment="MYSQL_HOST_IP_VAULT_SECRET_NAME=${MYSQL_HOST_IP_VAULT_SECRET_NAME}"' >> $MAIN_SERVICE_FILEPATH
echo "Restart=always" >> $MAIN_SERVICE_FILEPATH
echo "RestartSec=30" >> $MAIN_SERVICE_FILEPATH
echo "WorkingDirectory=$ASKME_FOLDER" >> $MAIN_SERVICE_FILEPATH
echo "ExecStart=$ASKME_ENV_PATH/bin/python -m streamlit run $MAIN_FILEPATH --server.port 8501 --server.address=127.0.0.1" >> $MAIN_SERVICE_FILEPATH
echo "" >> $MAIN_SERVICE_FILEPATH
echo "[Install]" >> $MAIN_SERVICE_FILEPATH
echo "WantedBy=default.target" >> $MAIN_SERVICE_FILEPATH

: > $SETUP_SERVICE_FILEPATH
echo "[Unit]" >> $SETUP_SERVICE_FILEPATH
echo "Description=AskME setup" >> $SETUP_SERVICE_FILEPATH
echo "After=network.target" >> $SETUP_SERVICE_FILEPATH
echo "" >> $SETUP_SERVICE_FILEPATH
echo "[Service]" >> $SETUP_SERVICE_FILEPATH
echo 'Environment="OCI_COMPARTMENT_ID=${OCI_COMPARTMENT_ID}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="OCI_REGION=${OCI_REGION}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="BUCKET_NAME=${BUCKET_NAME}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="VAULT_ID=${VAULT_ID}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="IS_GENAI_REGION=${IS_GENAI_REGION}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="MYSQL_USERNAME_VAULT_SECRET_NAME=${MYSQL_USERNAME_VAULT_SECRET_NAME}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="MYSQL_PASSWORD_VAULT_SECRET_NAME=${MYSQL_PASSWORD_VAULT_SECRET_NAME}"' >> $SETUP_SERVICE_FILEPATH
echo 'Environment="MYSQL_HOST_IP_VAULT_SECRET_NAME=${MYSQL_HOST_IP_VAULT_SECRET_NAME}"' >> $SETUP_SERVICE_FILEPATH
echo "Type=oneshot" >> $SETUP_SERVICE_FILEPATH
echo "RemainAfterExit=yes" >> $SETUP_SERVICE_FILEPATH
echo "Restart=on-failure" >> $SETUP_SERVICE_FILEPATH
echo "RestartSec=30" >> $SETUP_SERVICE_FILEPATH
echo "WorkingDirectory=$ASKME_FOLDER" >> $SETUP_SERVICE_FILEPATH
echo "ExecStart=$ASKME_ENV_PATH/bin/python $SETUP_FILEPATH" >> $SETUP_SERVICE_FILEPATH
echo "" >> $SETUP_SERVICE_FILEPATH
echo "[Install]" >> $SETUP_SERVICE_FILEPATH
echo "WantedBy=default.target" >> $SETUP_SERVICE_FILEPATH

# Set repo file permission
chown -R opc:opc $REPO_HOME_FOLDER >> $INSTALL_LOGS 2>&1

# Start the service from user opc
/usr/bin/su - opc -c '
    echo "export OCI_COMPARTMENT_ID=${OCI_COMPARTMENT_ID}" >> ~/.bash_profile
    echo "export OCI_REGION=${OCI_REGION}" >> ~/.bash_profile
    echo "export BUCKET_NAME=${BUCKET_NAME}" >> ~/.bash_profile
    echo "export VAULT_ID=${VAULT_ID}" >> ~/.bash_profile
    echo "export IS_GENAI_REGION=${IS_GENAI_REGION}" >> ~/.bash_profile
    echo "export MYSQL_USERNAME_VAULT_SECRET_NAME=${MYSQL_USERNAME_VAULT_SECRET_NAME}" >> ~/.bash_profile
    echo "export MYSQL_PASSWORD_VAULT_SECRET_NAME=${MYSQL_PASSWORD_VAULT_SECRET_NAME}" >> ~/.bash_profile
    echo "export MYSQL_HOST_IP_VAULT_SECRET_NAME=${MYSQL_HOST_IP_VAULT_SECRET_NAME}" >> ~/.bash_profile
    source ~/.bash_profile
    # Session bus required for systemctl
    if [ -z "$XDG_RUNTIME_DIR" ]
    then
        export XDG_RUNTIME_DIR="/run/user/$UID"
    fi
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]
    then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi
    loginctl enable-linger "$(whoami)"
    systemctl --user disable --now '"$MAIN_SERVICE_NAME"' >/dev/null 2>&1
    systemctl --user daemon-reload
    systemctl --user enable --now '"$MAIN_SERVICE_FILEPATH"'
    systemctl --user start '"$MAIN_SERVICE_NAME"'
    systemctl --user disable --now '"$SETUP_SERVICE_NAME"' >/dev/null 2>&1
    systemctl --user daemon-reload
    systemctl --user enable --now '"$SETUP_SERVICE_FILEPATH"'
    systemctl --user start '"$SETUP_SERVICE_NAME"'
' >> $INSTALL_LOGS 2>&1