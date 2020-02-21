FROM python:3.7-slim-buster  as builder
ENV DEBIAN_FRONTEND noninteractive
ARG MISP_TAG

RUN apt-get update && apt-get install -y --no-install-recommends \
                git \
                python3-dev \
                python3-pip \
                python3-wheel \
                build-essential \
                pkg-config \
                libpoppler-cpp-dev \
                libfuzzy-dev \
            && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Build MISP Modules
    WORKDIR /srv
    RUN git clone --branch ${MISP_TAG} --depth 1  https://github.com/MISP/misp-modules.git
    RUN mkdir /wheel
    WORKDIR /srv/misp-modules
    RUN sed -i 's/-e //g' REQUIREMENTS
    RUN pip3 wheel -r REQUIREMENTS --no-cache-dir -w /wheel/

FROM python:3.7-slim-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
            libglib2.0-0 \
            libzbar0 \
            libxrender1 \
            libxext6 \
            libpoppler-cpp0v5 \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY --from=builder /wheel /wheel
RUN pip install /wheel/*.whl

ENTRYPOINT [ "/usr/local/bin/misp-modules", "-l", "0.0.0.0"]
