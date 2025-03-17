#!/bin/bash
cd $(dirname "$0")

source test-utils-ubuntu.sh librenms


PACKAGE_LIST="acl \
    curl \
    fping \
    git \
    graphviz \
    imagemagick \
    mariadb-client \
    mariadb-server \
    mtr-tiny \
    nginx-full \
    nmap \
    rrdtool \
    snmp \
    snmpd \
    unzip \
    python3-pymysql \
    python3-dotenv \
    python3-redis \
    python3-setuptools \
    python3-psutil \
    python3-systemd \
    python3-pip \
    whois \
    traceroute \
    software-properties-common"

# Run common tests
checkCommon

# Actual tests
checkOSPackages "librenms-os-packages" ${PACKAGE_LIST}
check "PHP installation" php8.2 -v
check "Composer installation" composer --version
check "MariaDB service" systemctl status mariadb --no-pager
check "SNMP service" systemctl status snmpd --no-pager
checkExtension "xdebug.php-debug"
checkExtension "bmewburn.vscode-intelephense-client"
checkExtension "mrmlnc.vscode-apache"
checkExtension "ms-azuretools.vscode-docker"
checkExtension "VisualStudioExptTeam.vscodeintellicode"

# Report result
reportResults
