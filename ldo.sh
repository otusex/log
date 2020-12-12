#!/bin/bash

mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
timedatectl set-timezone Europe/Moscow
yum install epel-release -y
yum check-update

yum install ntp -y 
systemctl start ntpd 
systemctl enable ntpd
yum install audit audispd-plugins policycoreutils-python firewalld -y


systemctl enable firewalld 
sudo systemctl start firewalld


cat << EOF > /etc/audit/auditd.conf

local_events = yes
write_logs = yes
log_file = /var/log/audit/audit.log
log_group = root
log_format = RAW
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 8
num_logs = 5
priority_boost = 4
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = NONE
##name = mydomain
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
verify_email = yes
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
use_libwrap = yes
tcp_listen_port = 60
tcp_listen_queue = 5
tcp_max_per_addr = 1
##tcp_client_ports = 1024-65535
tcp_client_max_idle = 0
enable_krb5 = no
krb5_principal = auditd
##krb5_key_file = /etc/audit/audit.key
distribute_network = no
EOF

cat << EOF > rsyslog.conf

$ModLoad imuxsock 
$ModLoad imjournal 

$ModLoad imudp
$UDPServerRun 514

$ModLoad imtcp
$InputTCPServerRun 514



$WorkDirectory /var/lib/rsyslog

$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat


$IncludeConfig /etc/rsyslog.d/*.conf

$OmitLocalLogging on

$IMJournalStateFile imjournal.state


$template Incoming-logs,"/mnt/logging/192.168.10.22/%PROGRAMNAME%.log"
if $fromhost-ip == "192.168.10.22"  then -?Incoming-logs
& stop

#kern.*                                                 /dev/console

*.info;mail.none;authpriv.none;cron.none                /var/log/messages

authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
uucp,news.crit                                          /var/log/spooler

local7.*                                                /var/log/boot.log


EOF

sudo chown root:root /etc/audit/auditd.conf
sudo chmod 640 /etc/audit/auditd.conf
sudo chown root:root /etc/rsyslog.conf
sudo chmod 644 /etc/rsyslog.conf
sudo mkdir -p /mnt/logging/192.168.10.22
sudo semanage fcontext -a -t var_log_t '/mnt/logging/192.168.10.22(/.*)?'
sudo restorecon -Rv /mnt/logging/192.168.10.22/
sudo firewall-cmd --permanent --add-port=514/udp; sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --permanent --add-port=60/udp; sudo firewall-cmd --permanent --add-port=60/tcp; sudo firewall-cmd --reload
systemctl restart rsyslog
service auditd restart 
systemctl daemon-reload

