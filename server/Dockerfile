FROM debian:buster-slim as php-build

    RUN apt-get update; apt-get install -y --no-install-recommends \
        gcc \
        make \
        libfuzzy-dev \
        ca-certificates \
        php \
        php-dev \
        php-pear \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

        RUN cp /usr/lib/x86_64-linux-gnu/libfuzzy.* /usr/lib; pecl install ssdeep


FROM debian:buster-slim as python-build
    RUN apt-get update; apt-get install -y --no-install-recommends \
        gcc \
        git \
        python3 \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        libfuzzy-dev \
        ca-certificates \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

    WORKDIR /tmp
    RUN git clone --depth 1 https://github.com/CybOXProject/mixbox.git; \
        cd mixbox; python3 setup.py bdist_wheel

    # install python-maec
    RUN git clone --depth 1 https://github.com/MAECProject/python-maec.git; \
        cd python-maec; python3 setup.py bdist_wheel

    # install python-cybox
    RUN git clone --depth 1 https://github.com/CybOXProject/python-cybox.git; \
        cd python-cybox; python3 setup.py bdist_wheel

    # install python stix
    RUN git clone --depth 1 https://github.com/STIXProject/python-stix.git; \
        cd python-stix; python3 setup.py bdist_wheel

    # install STIX2.0 library to support STIX 2.0 export:
    RUN git clone --depth 1 https://github.com/MISP/cti-python-stix2.git; \
        cd cti-python-stix2; python3 setup.py bdist_wheel

    # install PyMISP
    RUN git clone --depth 1 https://github.com/MISP/PyMISP.git; \
        cd PyMISP; python3 setup.py bdist_wheel

    # install pydeep
    RUN git clone --depth 1 https://github.com/coolacid/pydeep.git; \
        cd pydeep; python3 setup.py bdist_wheel

FROM debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive
ARG MISP_TAG=2.4.118
ARG PHP_VER=20180731

# OS Packages
    RUN apt-get update; apt-get install -y --no-install-recommends \
        sudo \
        apache2 \
        supervisor \
        git \
        cron \
        openssl \
        gpg-agent gpg \
        python3 \
        python3-setuptools \
        python3-pip \
        ssdeep \
        mariadb-client \

        zip unzip \

        php \
        php-xml \
        php-mbstring \
        php-mysql \
#        php-dev \
        php-redis \
        php-gd \
        libfuzzy2 \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# MISP code
    # Download MISP using git in the /var/www/ directory.
    RUN git clone --branch v${MISP_TAG} --depth 1 https://github.com/MISP/MISP.git /var/www/MISP; \
        cd /var/www/MISP/app; git submodule update --init --recursive .;

# Python Modules
    COPY --from=python-build /tmp/PyMISP/dist/*.whl /tmp
    COPY --from=python-build /tmp/cti-python-stix2/dist/*.whl /tmp
    COPY --from=python-build /tmp/mixbox/dist/*.whl /tmp
    COPY --from=python-build /tmp/python-cybox/dist/*.whl /tmp
    COPY --from=python-build /tmp/python-maec/dist/*.whl /tmp
    COPY --from=python-build /tmp/python-stix/dist/*.whl /tmp
    COPY --from=python-build /tmp/pydeep/dist/*.whl /tmp

    RUN pip3 install --no-cache-dir /tmp/*.whl plyara pyzmq redis python-magic lief

# CakePHP
    # Once done, install CakeResque, first get latest composer
    COPY --from=php-build /usr/lib/php/${PHP_VER}/ssdeep.so /usr/lib/php/${PHP_VER}/ssdeep.so
    COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
    WORKDIR /var/www/MISP/app
    RUN composer install \
    # Enable CakeResque with php-redis
        ;phpenmod redis \
    # Enable CakeResque with php-gnupgp
        ;phpenmod gnupg \
    # Enable ssdeep we build earlier
        ;phpenmod ssdeep \
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
