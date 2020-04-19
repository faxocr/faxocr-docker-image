FROM ubuntu:16.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
# ubuntu packages
RUN apt-get update && apt-get install -y \
    build-essential libtool-bin git curl wget \
    bzip2 zlib1g-dev \
    openssl libssl-dev libcurl4-openssl-dev \
    libreadline-dev libyaml-dev libxml2-dev libxslt-dev \
    sqlite3 libsqlite3-dev \
    libmysqlclient-dev \
    nodejs
RUN apt-get install -y --no-install-recommends \
    libopencv-dev
RUN apt-get install -y --no-install-recommends \
    php php-mbstring php-mysql \
    imagemagick wkhtmltopdf ghostscript gocr netpbm \
    fetchmail sendemail pdftk zip mpack xvfb procmail \
    parallel fonts-takao-gothic fonts-takao-mincho ghostscript
COPY imagemagick_policy.xml /etc/ImageMagick-6/policy.xml
# ruby
ENV RUBY_DIR=/root/.rbenv
ENV RUBY_VERSION=1.9.2-p330
RUN git clone https://github.com/sstephenson/rbenv.git $RUBY_DIR
ENV PATH=$RUBY_DIR/bin:$PATH
RUN mkdir -p $RUBY_DIR/plugins && cd $RUBY_DIR/plugins \
    && git clone https://github.com/sstephenson/ruby-build.git
RUN $RUBY_DIR/bin/rbenv install $RUBY_VERSION
RUN echo "install: --no-ri --no-rdoc" > /root/.gemrc \
    && echo "update: --no-ri --no-rdoc" >> /root/.gemrc
ENV PATH=$RUBY_DIR/versions/$RUBY_VERSION/bin:$PATH
RUN $RUBY_DIR/versions/$RUBY_VERSION/bin/gem install bundler -v 1.11.2
# faxocr
RUN echo faxocr
RUN useradd -d /home/faxocr faxocr
RUN git clone -b kentaro/ruby19rails23mysql56 https://github.com/KentaroAOKI/faxocr.git /home/faxocr
RUN cd /home/faxocr/rails && $RUBY_DIR/versions/$RUBY_VERSION/bin/bundle install
COPY faxocr_database.yml /home/faxocr/rails/config/database.yml
RUN mkdir /root/.fonts && cp /home/faxocr/etc/OCRB.ttf /root/.fonts/ && fc-cache -v -f
# kocr and sheet-reader 
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
RUN cd /home/faxocr/src \
    && git clone https://github.com/cluscore/cluscore.git \
    && cd cluscore \
    && ./configure \
    && make install \
    && make clean
RUN cd /home/faxocr/src/srhelper \
    && make \
    && make install
RUN cd /home/faxocr/src \
    && git clone https://github.com/faxocr/kocr.git \
    && cd kocr && git fetch origin pull/3/head:replace_preprocessing && git checkout replace_preprocessing && cd .. \
    && cd kocr/src \
    && make library \
    && make install \
    && make clean
RUN cd /home/faxocr/src \
    && git clone -b feature/alphabet https://github.com/faxocr/sheet-reader.git \
    && cd sheet-reader \
    && ./configure \
    && make install \
    && cp src/sheetreader ../../bin/ \
    && make clean
# apache and passenger (If you don't use it, you can safely delete it.)
RUN apt-get install -y apache2 apache2-dev --no-install-recommends
RUN $RUBY_DIR/versions/$RUBY_VERSION/bin/gem install passenger
RUN $RUBY_DIR/versions/$RUBY_VERSION/bin/passenger-install-apache2-module --auto
RUN $RUBY_DIR/versions/$RUBY_VERSION/bin/passenger-install-apache2-module --snippet > /etc/apache2/mods-available/passenger.load
COPY apache2_site-faxocr.conf /tmp/faxocr.conf
RUN tr -d '\r' < /tmp/faxocr.conf > /etc/apache2/sites-available/faxocr.conf
COPY apache2_ports.conf /tmp/ports.conf
RUN tr -d '\r' < /tmp/ports.conf > /etc/apache2/ports.conf
RUN a2dissite 000-default && a2ensite faxocr && a2enmod passenger
RUN chown -R faxocr:faxocr /home/faxocr
ENV APACHE_RUN_USER root
ENV APACHE_RUN_GROUP root
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
RUN chmod 755 /root
# mail
COPY faxocr_procmailrc /tmp/procmailrc
RUN tr -d '\r' < /tmp/procmailrc > /etc/procmailrc
RUN mkdir /root/Maildir
# sheet-reader
RUN cp /home/faxocr/src/kocr/databases/cnn-num.bin /home/faxocr/src/kocr/databases/cnn-alphabet_lowercase.bin
RUN cp /home/faxocr/src/kocr/databases/cnn-num.bin /home/faxocr/src/kocr/databases/cnn-alphabet_uppercase.bin
RUN cp /home/faxocr/src/kocr/databases/cnn-num.bin /home/faxocr/src/kocr/databases/cnn-alphabet_number.bin
