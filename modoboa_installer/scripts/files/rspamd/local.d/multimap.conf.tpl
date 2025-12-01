# Rspamd multimap configuration for whitelist/blacklist
# Simplified version based on mailcow patterns
# Installed by modoboa-installer

# Global sender whitelist (SMTP envelope FROM)
# Add addresses to /etc/rspamd/local.d/maps/global_smtp_from_whitelist.map
GLOBAL_SMTP_FROM_WL {
    type = "from";
    map = "${LOCAL_CONFDIR}/maps/global_smtp_from_whitelist.map";
    regexp = true;
    score = -10;
    description = "Sender is on global whitelist";
}

# Global sender blacklist (SMTP envelope FROM)
# Add addresses to /etc/rspamd/local.d/maps/global_smtp_from_blacklist.map
GLOBAL_SMTP_FROM_BL {
    type = "from";
    map = "${LOCAL_CONFDIR}/maps/global_smtp_from_blacklist.map";
    regexp = true;
    score = 10;
    description = "Sender is on global blacklist";
}

# IP whitelist
# Add IPs/networks to /etc/rspamd/local.d/maps/ip_whitelist.map
IP_WHITELIST {
    type = "ip";
    map = "${LOCAL_CONFDIR}/maps/ip_whitelist.map";
    symbols_set = ["IP_WHITELIST"];
    score = -10;
    description = "IP is on whitelist";
}

# IP blacklist
# Add IPs/networks to /etc/rspamd/local.d/maps/ip_blacklist.map
IP_BLACKLIST {
    type = "ip";
    map = "${LOCAL_CONFDIR}/maps/ip_blacklist.map";
    symbols_set = ["IP_BLACKLIST"];
    score = 10;
    description = "IP is on blacklist";
}

# Domain whitelist (header FROM)
# Add domains to /etc/rspamd/local.d/maps/domain_whitelist.map
DOMAIN_WHITELIST {
    type = "header";
    header = "from";
    filter = "email:domain";
    map = "${LOCAL_CONFDIR}/maps/domain_whitelist.map";
    regexp = true;
    score = -5;
    description = "Domain is on whitelist";
}

# Domain blacklist (header FROM)
# Add domains to /etc/rspamd/local.d/maps/domain_blacklist.map
DOMAIN_BLACKLIST {
    type = "header";
    header = "from";
    filter = "email:domain";
    map = "${LOCAL_CONFDIR}/maps/domain_blacklist.map";
    regexp = true;
    score = 5;
    description = "Domain is on blacklist";
}
