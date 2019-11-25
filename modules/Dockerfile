FROM python:3.7-slim-buster
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
                git \
                python3-dev \
                python3-pip \
                build-essential \
                pkg-config \
                libpoppler-cpp-dev \
#                libpq5 \
#                libjpeg-dev \
#                tesseract-ocr \ 
#                imagemagick \
#                virtualenv \
#                libopencv-dev \
#                zbar-tools \
#                libzbar0 \
#                libzbar-dev \
#                libfuzzy-dev \
#                gem \
#                curl \
#                gosu \
            && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Add Argument for MISP-Modules releases
ARG VERSION=2.4.118

# Install MISP Modules
WORKDIR /srv
RUN git clone --branch v${VERSION} --depth 1  https://github.com/MISP/misp-modules.git

WORKDIR /srv/misp-modules

RUN pip3 install -I -r REQUIREMENTS --no-cache-dir
RUN pip3 install . --no-cache-dir 
RUN chown -R www-data /srv/misp-modules

USER www-data
ENTRYPOINT [ "/usr/local/bin/misp-modules", "-l", "0.0.0.0"]
