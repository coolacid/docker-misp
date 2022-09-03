FROM python:3.9-slim-bullseye  as builder
ENV DEBIAN_FRONTEND noninteractive
ARG MODULES_TAG
ARG MODULES_COMMIT

RUN apt-get update && apt-get install -y --no-install-recommends \
                cmake \
                git \
                python3-dev \
                python3-pip \
                python3-wheel \
                build-essential \
                pkg-config \
                libpoppler-cpp-dev \
                libfuzzy-dev \
                libssl-dev \
            && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Build MISP Modules
    RUN mkdir /wheel
    WORKDIR /srv

    RUN git clone --branch ${MODULES_TAG} --depth 1  https://github.com/MISP/misp-modules.git /srv/misp-modules
    RUN if [ ! -z ${MODULES_COMMIT} ]; then cd /srv/misp-modules && git checkout ${MODULES_COMMIT}; fi; \
        # Fixed in master - even though __init__.py is not mandatory in py3, wheels skip packages without it
        touch /srv/misp-modules/misp_modules/modules/action_mod/_utils/__init__.py; \
        # Fixed in master - missing dependencies
        echo "Jinja2==3.1.2\nmattermostdriver==7.3.2" >> /srv/misp-modules/REQUIREMENTS; \
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
            libgl1 \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY --from=builder /wheel /wheel
COPY --from=builder /usr/local/lib/libfaupl* /usr/local/lib/
RUN pip install --use-deprecated=legacy-resolver /wheel/*.whl; ldconfig

# Since we compile faup ourselves and lua is not required anymore, we can load our own library 
#   and skip the pre-compiled blob to improve compatibility with other architectures like arm
RUN sed -i s/LoadLibrary\(LOAD_LIB\)/LoadLibrary\(\"\\/usr\\/local\\/lib\\/libfaupl.so\"\)/ \
    /usr/local/lib/python3.9/site-packages/pyfaup/__init__.py

ENTRYPOINT [ "/usr/local/bin/misp-modules", "-l", "0.0.0.0"]
