"""SSL tools."""

import os
import sys

from . import package
from . import utils


class CertificateBackend:
    """Base class."""

    def __init__(self, config):
        """Set path to certificates."""
        self.config = config

    def overwrite_existing_certificate(self):
        """Check if certificate already exists."""
        if os.path.exists(self.config.get("general", "tls_key_file")):
            if not self.config.getboolean("general", "force"):
                answer = utils.user_input(
                    "Overwrite the existing SSL certificate? (y/N) ")
                if not answer.lower().startswith("y"):
                    return False
        return True

    def generate_cert(self):
        """Create a certificate."""
        pass


class ManualCertificate(CertificateBackend):
    """Use certificate provided."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        path_correct = True
        self.tls_cert_file_path = self.config.get("certificate",
                                                  "tls_cert_file_path")
        self.tls_key_file_path = self.config.get("certificate",
                                                 "tls_key_file_path")

        if not os.path.exists(self.tls_key_file_path):
            utils.error("'tls_key_file_path' path is not accessible")
            path_correct = False
        if not os.path.exists(self.tls_cert_file_path):
            utils.error("'tls_cert_file_path' path is not accessible")
            path_correct = False

        if not path_correct:
            sys.exit(1)

        self.config.set("general", "tls_key_file",
                        self.tls_key_file_path)
        self.config.set("general", "tls_cert_file",
                        self.tls_cert_file_path)


class SelfSignedCertificate(CertificateBackend):
    """Create a self signed certificate."""

    def __init__(self, *args, **kwargs):
        """Sanity checks."""
        super().__init__(*args, **kwargs)
        if self.config.has_option("general", "tls_key_file"):
            # Compatibility
            return
        for base_dir in ["/etc/pki/tls", "/etc/ssl"]:
            if os.path.exists(base_dir):
                self.config.set(
                    "general", "tls_key_file",
                    "{}/private/%(hostname)s.key".format(base_dir))
                self.config.set(
                    "general", "tls_cert_file",
                    "{}/certs/%(hostname)s.cert".format(base_dir))
                return
        raise RuntimeError("Cannot find a directory to store certificate")

    def generate_cert(self):
        """Create a certificate."""
        if not self.overwrite_existing_certificate():
            return
        hostname = self.config.get("general", "hostname")
        cert_file = self.config.get("general", "tls_cert_file")
        utils.printcolor(
            "Generating new self-signed certificate", utils.YELLOW)
        # Include SAN extension for hostname verification (required by modern SSL libs)
        # SAN includes: hostname, localhost, and 127.0.0.1 for internal OAuth2 calls
        utils.exec_cmd(
            "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 "
            "-subj '/CN={}' "
            "-addext 'subjectAltName=DNS:{},DNS:localhost,IP:127.0.0.1' "
            "-keyout {} -out {}".format(
                hostname,
                hostname,
                self.config.get("general", "tls_key_file"),
                cert_file)
        )
        # Add self-signed certificate to system trust store
        # This is required for Radicale OAuth2 authentication to work with self-signed certs
        utils.printcolor(
            "Adding self-signed certificate to system trust store", utils.YELLOW)
        trust_store_cert = "/usr/local/share/ca-certificates/{}.crt".format(hostname)
        utils.exec_cmd("cp {} {}".format(cert_file, trust_store_cert))
        utils.exec_cmd("update-ca-certificates")
        # Also append to ca-certificates.crt bundle directly (update-ca-certificates may not always work)
        utils.exec_cmd("cat {} >> /etc/ssl/certs/ca-certificates.crt".format(cert_file))


class LetsEncryptCertificate(CertificateBackend):
    """Create a certificate using letsencrypt."""

    def __init__(self, *args, **kwargs):
        """Update config."""
        super().__init__(*args, **kwargs)
        self.hostname = self.config.get("general", "hostname")
        self.config.set("general", "tls_cert_file", (
            "/etc/letsencrypt/live/{}/fullchain.pem".format(self.hostname)))
        self.config.set("general", "tls_key_file", (
            "/etc/letsencrypt/live/{}/privkey.pem".format(self.hostname)))

    def install_certbot(self):
        """Install certbot script to generate cert."""
        name, version = utils.dist_info()
        name = name.lower()
        if name == "ubuntu":
            package.backend.update()
            package.backend.install("software-properties-common")
            utils.exec_cmd("add-apt-repository -y universe")
            if version == "18.04":
                utils.exec_cmd("add-apt-repository -y ppa:certbot/certbot")
            package.backend.update()
            package.backend.install("certbot")
        elif name.startswith("debian"):
            package.backend.update()
            package.backend.install("certbot")
        elif "centos" in name:
            package.backend.install("certbot")
        else:
            utils.printcolor("Failed to install certbot, aborting.")
            sys.exit(1)
        # Nginx plugin certbot
        if (
                self.config.has_option("nginx", "enabled") and
                self.config.getboolean("nginx", "enabled")
        ):
            if name == "ubuntu" or name.startswith("debian"):
                package.backend.install("python3-certbot-nginx")

    def generate_cert(self):
        """Create a certificate."""
        utils.printcolor(
            "Generating new certificate using letsencrypt", utils.YELLOW)
        self.install_certbot()
        utils.exec_cmd(
            "certbot certonly -n --standalone -d {} -m {} --agree-tos"
            .format(
                self.hostname, self.config.get("letsencrypt", "email")))
        with open("/etc/cron.d/letsencrypt", "w") as fp:
            fp.write("0 */12 * * * root certbot renew "
                     "--quiet\n")
        cfg_file = "/etc/letsencrypt/renewal/{}.conf".format(self.hostname)
        pattern = "s/authenticator = standalone/authenticator = nginx/"
        utils.exec_cmd("perl -pi -e '{}' {}".format(pattern, cfg_file))
        with open("/etc/letsencrypt/renewal-hooks/deploy/reload-services.sh", "w") as fp:
            fp.write(f"""#!/bin/bash

HOSTNAME=$(basename $RENEWED_LINEAGE)

if [ "$HOSTNAME" = "{self.hostname}" ]
then
	systemctl reload dovecot
	systemctl reload postfix
fi
""")


def get_backend(config):
    """Return the appropriate backend."""
    cert_type = config.get("certificate", "type")
    if cert_type == "letsencrypt":
        return LetsEncryptCertificate(config)
    if cert_type == "manual":
        return ManualCertificate(config)
    return SelfSignedCertificate(config)
