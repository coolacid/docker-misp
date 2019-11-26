FROM debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive
ARG VERSION=2.4.118

# OS Packages
    RUN apt-get update; apt-get install -y --no-install-recommends \
        sudo \
        apache2 \
        supervisor \
        git make \
        cron \
        gcc \
        zip unzip \
        openssl \
        gpg-agent gpg \
        python3 \
        python3-setuptools \
        python3-dev \
        python3-pip \
        ssdeep \
        php \
        php-xml \
        php-mbstring \
        php-mysql \
        php-pear \
        php-dev \
        php-redis \
        php-gd \
        libfuzzy-dev \
        mariadb-client \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# MISP code
    ARG MISP_TAG=${VERSION}
    ENV MISP_TAG=${MISP_TAG}
    # Download MISP using git in the /var/www/ directory.
    # Attention: we replaced the fixed tag with a variable
    WORKDIR /var/www
    RUN git clone --branch v${MISP_TAG} --recursive --depth 1 https://github.com/MISP/MISP.git /var/www/MISP
    WORKDIR /var/www/MISP
    # Make git ignore filesystem permission differences
#    RUN git config core.filemode false; \
    # CakePHP and a lot of other things is included as a submodule of MISP, execute the following commands to let git fetch it:
#    git submodule update --init --recursive; \
    # Make git ignore filesystem permission differences for submodules
#    git submodule foreach --recursive git config core.filemode false

# Python Modules
    # install Mitre's STIX and its dependencies by running the following commands:
    # install mixbox to accomodate the new STIX dependencies:
    WORKDIR /var/www/MISP/app/files/scripts
    RUN git clone --depth 1 https://github.com/CybOXProject/mixbox.git; \
        cd mixbox; python3 setup.py install

    # install python-maec
    RUN git clone --depth 1 https://github.com/MAECProject/python-maec.git; \
        cd python-maec; python3 setup.py install

    # install python-cybox
    RUN git clone --depth 1 https://github.com/CybOXProject/python-cybox.git; \
        cd python-cybox; python3 setup.py install

    # install python stix
    RUN git clone --depth 1 https://github.com/STIXProject/python-stix.git; \
        cd python-stix; python3 setup.py install

    # install STIX2.0 library to support STIX 2.0 export:
    WORKDIR /var/www/MISP/cti-python-stix2
    RUN python3 setup.py install

    # install PyMISP
    WORKDIR /var/www/MISP/PyMISP
    RUN python3 setup.py install

    RUN pip3 install --no-cache-dir plyara pyzmq redis maec python-magic lief https://github.com/lief-project/packages/raw/lief-master-latest/pylief-0.9.0.dev.zip git+https://github.com/kbandla/pydeep.git

# CakePHP
    # Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
    COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
    WORKDIR /var/www/MISP/app
    RUN  composer require kamisama/cake-resque:4.1.2 \
        ;composer config vendor-dir Vendor \
        ;composer install \
    # Enable CakeResque with php-redis
        ;phpenmod redis \
    # Enable CakeResque with php-gnupgp
        ;phpenmod gnupg \
    #installing ssdeep_php - pecl is dumb, we need to ensure the libs are in the specific place
        ;cp /usr/lib/x86_64-linux-gnu/libfuzzy.* /usr/lib; pecl install ssdeep; phpenmod ssdeep \
    # To use the scheduler worker for scheduled tasks, do the following:
        ;cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

# Configure Apache
    # add HTTP MISP Config
    RUN rm /etc/apache2/sites-enabled/*;
    COPY files/etc/apache2/sites-enabled/misp.conf /etc/apache2/sites-enabled/
    COPY files/etc/apache2/sites-enabled/misp-ssl.conf /etc/apache2/sites-enabled/
    COPY files/etc/apache2/ports.conf /etc/apache2/ports.conf
    RUN set -eu \
        ;chmod 640 /etc/apache2/ports.conf \
        ;chown root.root /etc/apache2/ports.conf \
        ;chmod 640 /etc/apache2/sites-available/* \
        ;chown root.root /etc/apache2/sites-available/* \
    # Configure Apache
        ;a2dismod status \
        ;a2enmod ssl \
        ;a2enmod rewrite \
        ;a2enmod headers

# Make a copy of the file store, so we can sync from it
    RUN cp -R /var/www/MISP/app/files /var/www/MISP/app/files.dist

# Entrypoints
    COPY files/etc/supervisor/supervisor.conf /etc/supervisor/conf.d/supervisord.conf
    COPY files/entrypoint_apache.sh /
    COPY files/entrypoint_cron.sh /
    COPY files/entrypoint_workers.sh /
    COPY files/entrypoint.sh /
    ENTRYPOINT [ "/entrypoint.sh" ]

# Change Workdirectory
    WORKDIR /var/www/MISP
