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

yum install audit audispd-plugins policycoreutils-python nginx -y



cat << EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log syslog:server=192.168.10.23:514,tag=nginx_access main;
    error_log syslog:server=192.168.10.23:514,tag=nginx_error notice;
    access_log syslog:server=192.168.10.24:514,tag=nginx_access main;
    error_log syslog:server=192.168.10.24:514,tag=nginx_error notice;

    error_log /var/log/nginx/error.log crit;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }


}
EOF

cat << EOF > /etc/rsyslog.conf

$ModLoad imuxsock 
$ModLoad imjournal 


$WorkDirectory /var/lib/rsyslog

$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat


$IncludeConfig /etc/rsyslog.d/*.conf

$OmitLocalLogging on

$IMJournalStateFile imjournal.state


*.info;mail.none;authpriv.none;cron.none                /var/log/messages

authpriv.*                                              /var/log/secure

mail.*                                                  -/var/log/maillog

cron.*                                                  /var/log/cron

*.emerg                                                 :omusrmsg:*

uucp,news.crit                                          /var/log/spooler

local7.*                                                /var/log/boot.log

*.* @192.168.10.23

EOF


cat << EOF > /etc/audit/rules.d/audit.rules
-D

-b 8192

-f 1
-w /etc/nginx/nginx.conf -p wa -k web_config_changed
-w /etc/nginx/conf.d/ -p wa -k web_config_changed
EOF


cat << EOF > /etc/audisp/audisp-remote.conf

remote_server = 192.168.10.23
port = 60
##local_port =
transport = tcp
queue_file = /var/spool/audit/remote.log
mode = immediate
queue_depth = 10240
format = managed
network_retry_time = 1
max_tries_per_record = 3
max_time_per_record = 5
heartbeat_timeout = 0 

network_failure_action = stop
disk_low_action = ignore
disk_full_action = warn_once
disk_error_action = warn_once
remote_ending_action = reconnect
generic_error_action = syslog
generic_warning_action = syslog
queue_error_action = stop
overflow_action = syslog

##enable_krb5 = no
##krb5_principal = 
##krb5_client_name = auditd
##krb5_key_file = /etc/audisp/audisp-remote.key

EOF

cat << EOF > au-remote.conf

active = yes
direction = out
path = /sbin/audisp-remote
type = always
#args =
format = string
EOF

cat << EOF > /etc/audit/auditd.conf

local_events = yes
write_logs = no
log_file = /var/log/audit/audit.log
log_group = root
log_format = ENRICHED
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 8
num_logs = 5
priority_boost = 4
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = HOSTNAME
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
##tcp_listen_port = 60
tcp_listen_queue = 5
tcp_max_per_addr = 1
##tcp_client_ports = 1024-65535
tcp_client_max_idle = 0
enable_krb5 = no
krb5_principal = auditd
##krb5_key_file = /etc/audit/audit.key
distribute_network = no
EOF



sudo chown root:root /etc/audit/auditd.conf
sudo chmod 640 /etc/audit/auditd.conf
sudo chown root:root /etc/nginx/nginx.conf
sudo chmod 644 /etc/nginx/nginx.conf
sudo chown root:root /etc/rsyslog.conf
sudo chmod 644 /etc/rsyslog.conf
sudo chown root:root /etc/audit/rules.d/audit.rules
sudo chmod 644 /etc/audit/rules.d/audit.rules
sudo chown root:root /etc/audisp/audisp-remote.conf
sudo chmod 644 /etc/audisp/audisp-remote.conf
sudo chown root:root /etc/audisp/plugins.d/au-remote.conf
sudo chmod 644 /etc/audisp/plugins.d/au-remote.conf
systemctl enable nginx 
systemctl start nginx
systemctl restart rsyslog
service auditd restart
systemctl daemon-reload

