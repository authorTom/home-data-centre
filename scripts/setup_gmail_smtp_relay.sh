#!/bin/bash

# ====================================================================================
# Script: setup_gmail_smtp_relay.sh
# Description: Automates the configuration of a Postfix SMTP relay on Ubuntu
#              using a Gmail account.
# ====================================================================================

# --- Configuration ---
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
POSTFIX_CONFIG_FILE="/etc/postfix/main.cf"
SASL_PASSWD_FILE="/etc/postfix/sasl_passwd"

# --- Functions ---

# Function to display messages
msg() {
    echo -e "\n--- $1 ---"
}

# Function to handle errors and exit
error_exit() {
    echo -e "\nERROR: $1" >&2
    exit 1
}

# --- Script Start ---

# 1. Check for Root Privileges
msg "Checking for root privileges"
if [[ "$(id -u)" -ne 0 ]]; then
    error_exit "This script must be run as root. Please use sudo."
fi
echo "Root check passed."

# 2. Get User Credentials
msg "Enter your Gmail credentials"
read -p "Enter your Gmail address: " GMAIL_USER
read -s -p "Enter your 16-character Google App Password: " GMAIL_APP_PASSWORD
echo # Newline after password input

if [[ -z "$GMAIL_USER" || -z "$GMAIL_APP_PASSWORD" ]]; then
    error_exit "Email address and App Password cannot be empty."
fi

# 3. Install Packages
msg "Updating package list and installing required packages"
apt update && apt install -y libsasl2-modules mailutils
if [[ $? -ne 0 ]]; then
    error_exit "Failed to install required packages. Please check your connection and repositories."
fi
echo "Packages installed successfully."

# 4. Create and Secure Credential File
msg "Creating and securing the SASL password file"
(
cat <<EOF
[${SMTP_SERVER}]:${SMTP_PORT} ${GMAIL_USER}:${GMAIL_APP_PASSWORD}
EOF
) > "$SASL_PASSWD_FILE" || error_exit "Failed to create SASL password file."

chmod 600 "$SASL_PASSWD_FILE"
postmap hash:"$SASL_PASSWD_FILE"
echo "SASL password file created and secured."

# 5. Configure Postfix
msg "Configuring Postfix (main.cf)"

# Remove existing relayhost and SASL settings to prevent duplicates
sed -i '/^relayhost =/d' "$POSTFIX_CONFIG_FILE"
sed -i '/^smtp_sasl_auth_enable =/d' "$POSTFIX_CONFIG_FILE"
sed -i '/^smtp_sasl_password_maps =/d' "$POSTFIX_CONFIG_FILE"
sed -i '/^smtp_sasl_security_options =/d' "$POSTFIX_CONFIG_FILE"
sed -i '/^smtp_use_tls =/d' "$POSTFIX_CONFIG_FILE"
sed -i '/^smtp_tls_CAfile =/d' "$POSTFIX_CONFIG_FILE"

# Append new configuration to the end of the file
(
cat <<EOF

# SMTP Relay Configuration (added by script)
relayhost = [${SMTP_SERVER}]:${SMTP_PORT}
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:${SASL_PASSWD_FILE}
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF
) >> "$POSTFIX_CONFIG_FILE" || error_exit "Failed to write to Postfix configuration file."

echo "Postfix configuration updated."

# 6. Apply Configuration
msg "Reloading Postfix to apply new configuration"
systemctl reload postfix
if [[ $? -ne 0 ]]; then
    error_exit "Failed to reload Postfix. Use 'journalctl -xe' to check for errors."
fi
echo "Postfix reloaded successfully."

# 7. Send Test Email
msg "Sending a test email to verify the setup"
read -p "Enter a destination email address for testing: " DESTINATION_EMAIL
if [[ -z "$DESTINATION_EMAIL" ]]; then
    error_exit "Destination email address cannot be empty."
fi

SUBJECT="SMTP Relay Test from $(hostname)"
BODY="This is a test email sent from the Postfix SMTP relay on your server."
echo "$BODY" | mail -s "$SUBJECT" "$DESTINATION_EMAIL"

if [[ $? -eq 0 ]]; then
    echo "Test email sent to ${DESTINATION_EMAIL}."
    echo "Please check the inbox (and spam folder) to confirm receipt."
else
    echo "The mail command finished, but it doesn't guarantee delivery. Please check the logs if you don't receive the email. You can use 'tail -f /var/log/mail.log'."
fi

msg "Setup Complete!"