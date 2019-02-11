# A customized nginx with both the ngx_aws_auth and mod_zip modules.
#
# A sample nginx.conf is provided as a proof of concept of creating a zip
# file on-the-fly from Amazon Web Services Simple Storage Service (S3),
# without downloading the files to a temporary location first.

FROM centos:7
MAINTAINER Ira W. Snyder <isnyder@lcogt.net>

EXPOSE 80

ENV NGINX_VERSION=1.15.8

# install system packages
RUN yum -y install epel-release \
        && yum -y install gcc git make openssl-devel pcre-devel zlib-devel \
                  supervisor \
        && yum -y update \
        && yum -y clean all

# install nginx
RUN curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
        && tar zxf nginx-${NGINX_VERSION}.tar.gz \
        && cd nginx-${NGINX_VERSION} \
        && git clone --single-branch --branch AuthV2 https://github.com/anomalizer/ngx_aws_auth.git \
        && git clone https://github.com/evanmiller/mod_zip.git \
        && ./configure \
            --prefix=/usr \
            --conf-path=/etc/nginx/nginx.conf \
            --sbin-path=/usr/sbin \
            --http-log-path=/dev/stdout \
            --error-log-path=/dev/stdout \
            --lock-path=/var/lock/nginx.lock \
            --pid-path=/run/nginx.pid \
            --http-client-body-temp-path=/var/lib/nginx/body \
            --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
            --http-proxy-temp-path=/var/lib/nginx/proxy \
            --http-scgi-temp-path=/var/lib/nginx/scgi \
            --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
            --with-pcre-jit \
            --with-ipv6 \
            --with-file-aio \
            --with-threads \
            --with-http_ssl_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_gzip_static_module \
            --with-http_gunzip_module \
            --with-http_sub_module \
            --add-module=ngx_aws_auth \
            --add-module=mod_zip \
        && make install \
        && cd .. \
        && rm -f nginx-${NGINX_VERSION}.tar.gz \
        && rm -rf nginx-${NGINX_VERSION} \
        && mkdir -p /var/lib/nginx/body

RUN mkdir -p /var/www/html

COPY init /
COPY nginx.conf /etc/nginx/

CMD [ "/init", "-c", "/etc/nginx/nginx.conf" ]
