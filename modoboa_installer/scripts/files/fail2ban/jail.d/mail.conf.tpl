# Fail2ban jails for Postfix and Dovecot
# Installed by modoboa-installer

[postfix]
enabled = true
port = smtp,submission,smtps
filter = postfix
logpath = /var/log/mail.log
maxretry = %max_retry
bantime = %ban_time
findtime = %find_time

[dovecot]
enabled = true
port = imap,imaps,pop3,pop3s
filter = dovecot
logpath = /var/log/mail.log
maxretry = %max_retry
bantime = %ban_time
findtime = %find_time
