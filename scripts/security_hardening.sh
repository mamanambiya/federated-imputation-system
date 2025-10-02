#!/bin/bash

# Security Hardening Script for Federated Genomic Imputation Platform
# This script implements comprehensive security measures

set -e

echo "🔒 Starting Security Hardening Process..."

# 1. SSH Hardening
echo "🔧 Hardening SSH Configuration..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Create hardened SSH config
sudo tee /etc/ssh/sshd_config.d/99-security-hardening.conf > /dev/null << 'EOF'
# Security Hardening Configuration
Protocol 2
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
GatewayPorts no
PermitTunnel no
Compression no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 60
LogLevel VERBOSE
TCPKeepAlive no
UseDNS no
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
PermitUserEnvironment no
EOF

# 2. Firewall Configuration
echo "🔥 Configuring Advanced Firewall Rules..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow essential services
sudo ufw allow 2222/tcp comment 'SSH (hardened port)'
sudo ufw allow 3000/tcp comment 'Frontend'
sudo ufw allow 8000/tcp comment 'Backend API'

# Rate limiting for SSH
sudo ufw limit 2222/tcp

# Enable firewall
sudo ufw --force enable

# 3. Kernel Security Parameters
echo "🛡️ Applying Kernel Security Parameters..."
sudo tee /etc/sysctl.d/99-security-hardening.conf > /dev/null << 'EOF'
# Network Security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0

# Kernel Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.perf_event_paranoid = 3
kernel.unprivileged_bpf_disabled = 1
kernel.core_uses_pid = 1
kernel.ctrl-alt-del = 0
kernel.sysrq = 0
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
dev.tty.ldisc_autoload = 0
net.core.bpf_jit_harden = 2
EOF

# Apply sysctl settings
sudo sysctl -p /etc/sysctl.d/99-security-hardening.conf

# 4. File Permissions Hardening
echo "📁 Hardening File Permissions..."
sudo chmod 700 /root
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 644 /etc/passwd
sudo chmod 600 /etc/shadow
sudo chmod 644 /etc/group
sudo chmod 600 /etc/gshadow
sudo chmod 600 /boot/grub/grub.cfg 2>/dev/null || true
sudo chmod 755 /etc/cron.d
sudo chmod 755 /etc/cron.daily
sudo chmod 755 /etc/cron.hourly
sudo chmod 755 /etc/cron.weekly
sudo chmod 755 /etc/cron.monthly
sudo chmod 600 /etc/crontab

# 5. Disable Unnecessary Services
echo "🚫 Disabling Unnecessary Services..."
services_to_disable=(
    "bluetooth"
    "cups"
    "avahi-daemon"
    "whoopsie"
    "apport"
)

for service in "${services_to_disable[@]}"; do
    if systemctl is-enabled "$service" >/dev/null 2>&1; then
        sudo systemctl disable "$service"
        sudo systemctl stop "$service" 2>/dev/null || true
        echo "Disabled $service"
    fi
done

# 6. Password Policy
echo "🔐 Configuring Password Policy..."
sudo tee /etc/security/pwquality.conf > /dev/null << 'EOF'
# Password Quality Configuration
minlen = 12
minclass = 3
maxrepeat = 2
maxclassrepeat = 3
lcredit = -1
ucredit = -1
dcredit = -1
ocredit = -1
difok = 8
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
EOF

# 7. Login Security
echo "🔑 Configuring Login Security..."
sudo tee -a /etc/login.defs > /dev/null << 'EOF'

# Security Hardening
PASS_MAX_DAYS 90
PASS_MIN_DAYS 7
PASS_WARN_AGE 14
LOGIN_RETRIES 3
LOGIN_TIMEOUT 60
UMASK 027
EOF

# 8. Audit Configuration
echo "📊 Setting up System Auditing..."
sudo apt-get update
sudo apt-get install -y auditd audispd-plugins

sudo tee /etc/audit/rules.d/99-security-hardening.rules > /dev/null << 'EOF'
# Security Audit Rules
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege_escalation
-w /etc/sudoers.d/ -p wa -k privilege_escalation
-w /var/log/auth.log -p wa -k authentication
-w /var/log/faillog -p wa -k authentication
-w /var/log/lastlog -p wa -k authentication
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/hosts -p wa -k network_config
-w /etc/network/ -p wa -k network_config
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
EOF

# Restart auditd
sudo systemctl enable auditd
sudo systemctl restart auditd

# 9. Postfix Security
echo "📧 Securing Postfix Configuration..."
sudo postconf -e "smtpd_banner = \$myhostname ESMTP"
sudo postconf -e "disable_vrfy_command = yes"
sudo postconf -e "smtpd_helo_required = yes"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks,reject_unauth_destination"
sudo systemctl reload postfix

echo "✅ Security Hardening Complete!"
echo ""
echo "🔒 Security Status Summary:"
echo "- SSH hardened and moved to port 2222"
echo "- Firewall configured with restrictive rules"
echo "- Kernel security parameters applied"
echo "- File permissions hardened"
echo "- Unnecessary services disabled"
echo "- Password policy enforced"
echo "- System auditing enabled"
echo "- Postfix secured"
echo ""
echo "⚠️  IMPORTANT: SSH port changed to 2222"
echo "   Update your SSH connections to use: ssh -p 2222 user@host"
echo ""
echo "🔄 Reboot recommended to apply all kernel security settings"
