upstream modoboa {
    server unix:%uwsgi_socket_path fail_timeout=0;
}

server {
    listen 80;
    listen [::]:80;
    server_name %hostname;
    rewrite ^ https://$server_name$request_uri? permanent;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name %hostname;
    root %app_instance_path;

    ssl_certificate %tls_cert_file;
    ssl_certificate_key %tls_key_file;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384";
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_verify_depth 3;
    ssl_dhparam /etc/nginx/dhparam.pem;

    # Security headers (server-level for locations without their own add_header)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    client_max_body_size 10M;

    access_log /var/log/nginx/%{hostname}-access.log;
    error_log /var/log/nginx/%{hostname}-error.log;

    location /sitestatic/ {
        try_files $uri $uri/ =404;
    }

    location /media/ {
        try_files $uri $uri/ =404;
    }

%{rspamd_enabled}    location /rspamd/ {
%{rspamd_enabled}        proxy_pass       http://localhost:11334/;
%{rspamd_enabled}
%{rspamd_enabled}        proxy_set_header Host      $host;
%{rspamd_enabled}        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
%{rspamd_enabled}    }

%{radicale_enabled}    # Well-known redirects for CalDAV/CardDAV autodiscovery
%{radicale_enabled}    # Note: /radicale/ location is added by nginx.py post_run()
%{radicale_enabled}    location /.well-known/caldav {
%{radicale_enabled}        return 301 /radicale/;
%{radicale_enabled}    }
%{radicale_enabled}
%{radicale_enabled}    location /.well-known/carddav {
%{radicale_enabled}        return 301 /radicale/;
%{radicale_enabled}    }

    location ~ ^/(api|accounts|autodiscover) {
        include uwsgi_params;
        uwsgi_param UWSGI_SCRIPT instance.wsgi:application;
        uwsgi_pass modoboa;
    }

    location / {
        alias  %{app_instance_path}/frontend/;
        index  index.html;

        expires -1;
        add_header Pragma "no-cache";
        add_header Cache-Control "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";
        # Security headers (must repeat here since add_header in location overrides server level)
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;

        try_files $uri $uri/ /index.html = 404;
    }

    %{extra_config}
}
