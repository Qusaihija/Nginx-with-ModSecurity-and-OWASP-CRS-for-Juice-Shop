FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
#--Installing The Requrements--#

RUN apt-get update && apt-get install -y \
    nginx bison build-essential ca-certificates curl dh-autoreconf doxygen \
    flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \
    libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales \
    lua5.3-dev pkg-config wget zlib1g-dev libgd-dev libpcre2-dev

#--Building ModSecurity--#
WORKDIR /opt
RUN git clone https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity \
    && git submodule init && git submodule update \
    && ./build.sh && ./configure \
    && make && make install

#--Downloading ModSecurity-Nginx Connector--#
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && nginx -v \
    && nginx -v 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' > /opt/nginx_version.txt \
    && wget http://nginx.org/download/nginx-$(cat /opt/nginx_version.txt).tar.gz \
    && tar -xvzmf nginx-$(cat /opt/nginx_version.txt).tar.gz \
    && cd nginx-* && nginx -V \
    && ./configure --add-dynamic-module=../ModSecurity-nginx  --with-compat \
    && make modules && mkdir /etc/nginx/modules && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

#--Loading the ModSecurity Module in Nginx--#
RUN sed -i '/include \/etc\/nginx\/modules-enabled\/\*\.conf;/a load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

#--Setting Up OWASP-CRS--#
RUN rm -rf /usr/share/modsecurity-crs \
    && git clone https://github.com/coreruleset/coreruleset /usr/local/modsecurity-crs \
    && mv /usr/local/modsecurity-crs/crs-setup.conf.example /usr/local/modsecurity-crs/crs-setup.conf \
    && mv /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

#--Configuring Modsecurity--#
RUN mkdir -p /etc/nginx/modsec \
    && cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec \
    && cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec \
    && cp /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf \
    && sed -i 's/^\s*SecRuleEngine\s\+.*$/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf \
    && touch /etc/nginx/modsec/main.conf \
    && printf "Include /etc/nginx/modsec/modsecurity.conf\nInclude /usr/local/modsecurity-crs/crs-setup.conf\nInclude /usr/local/modsecurity-crs/rules/*.conf\n" > /etc/nginx/modsec/main.conf

#--Configuring Nginx--#
COPY juice_shop.conf /etc/nginx/conf.d/juice_shop.conf

CMD ["nginx","-g","daemon off;"]
