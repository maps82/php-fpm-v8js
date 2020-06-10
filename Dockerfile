FROM php:7.4.6-fpm

WORKDIR /tmp

RUN apt-get update \
    && apt-get install -y build-essential curl git python libglib2.0-dev \
    \
    && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    && export PATH=`pwd`/depot_tools:"$PATH" \
    \
    && fetch v8 \
    && cd v8 \
    && git checkout 8.0.426.27 \
    && gclient sync \
    \
    && tools/dev/v8gen.py -vv x64.release -- is_component_build=true use_custom_libcxx=false \
    && ninja -C out.gn/x64.release/ \
    \
    && mkdir -p /usr/local/{lib,include} \
    && cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin out.gn/x64.release/icudtl.dat /usr/local/lib/ \
    && cp -R include/* /usr/local/include/ \
    \
    && cd /tmp \
    && git clone https://github.com/phpv8/v8js.git \
    && cd v8js \
    && phpize \
    && ./configure LDFLAGS="-lstdc++" \
    && make \
    && make install \
    && echo "extension=v8js.so" > /usr/local/etc/php/conf.d/v8js.ini \
     \
    && apt-get -y remove build-essential curl git python libglib2.0-dev \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*
