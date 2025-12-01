# Rspamd actions configuration
# Based on mailcow defaults - battle-tested thresholds
# Installed by modoboa-installer

# Reject message (bounce back to sender)
reject = 15;

# Add spam header but deliver
add_header = 8;

# Greylist (temporary rejection, retry later)
greylist = 7;
