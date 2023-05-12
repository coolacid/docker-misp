FROM python:3.9-slim-bullseye  as builder
ENV DEBIAN_FRONTEND noninteractive
ARG MODULES_TAG

RUN apt-get update && apt-get install -y --no-install-recommends \
                cmake \
                git \
                python3-dev \
                build-essential \
                pkg-config \
                libpoppler-cpp-dev \
                libfuzzy-dev \
                libssl-dev \
            && python3 -m pip install --no-cache-dir --no-python-version-warning --disable-pip-version-check --no-color --upgrade \
                pip \
                wheel \
            && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Build MISP Modules
    RUN mkdir /wheel
    WORKDIR /srv

    RUN git clone --branch ${MODULES_TAG} --depth 1  https://github.com/MISP/misp-modules.git /srv/misp-modules; \
        cd /srv/misp-modules || exit; sed -i 's/-e //g' REQUIREMENTS; pip3 wheel -r REQUIREMENTS --no-cache-dir -w /wheel/

    RUN git clone --depth 1 https://github.com/stricaud/faup.git /srv/faup; \
        cd /srv/faup/build || exit; cmake .. && make install; \
        cd /srv/faup/src/lib/bindings/python || exit; pip3 wheel --no-cache-dir -w /wheel/ .

    # Remove extra packages due to incompatible requirements.txt files
    WORKDIR /wheel
    RUN find . -name "chardet*" | grep -v "chardet-4.0.0" | xargs rm -f


FROM python:3.9-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
            libglib2.0-0 \
            libzbar0 \
            libxrender1 \
            libxext6 \
            libpoppler-cpp0v5 \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY --from=builder /wheel /wheel
COPY --from=builder /usr/local/lib/libfaupl* /usr/local/lib/
RUN pip install --use-deprecated=legacy-resolver /wheel/*.whl; ldconfig

ENTRYPOINT [ "/usr/local/bin/misp-modules", "-l", "0.0.0.0"]
