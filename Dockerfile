FROM centos:7

#ADD ceph.repo /etc/yum.repos.d/ceph.repo
ADD scripts/pgsql_setup.sh /

# Install prereq
RUN yum clean all && \
    rm -rf /var/cache/yum  && \
    rpm --import 'https://download.ceph.com/keys/release.asc' && \
    rpm -ivh https://download.ceph.com/rpm/el7/noarch/ceph-release-1-1.el7.noarch.rpm && \
    rpm -ivh https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm && \
    yum install -y epel-release httpd git gcc python-devel mod_wsgi nodejs ceph-common-12.2.0 && \
    yum install -y python-dbus python-gobject python-psycopg2 python-pam m2crypto python-netifaces python-netaddr python-pyudev python-memcached numpy python-rtslib python-ceph python-pip postgresql10-server postgresql10-contrib postgresql10-libs npm
   

# Download openATTIC
WORKDIR /srv
RUN git clone https://bitbucket.org/openattic/openattic.git

WORKDIR /srv/openattic

# Install openATTIC backend
RUN mkdir -p /etc/openattic && \
    mkdir -p /var/log/openattic && \
    mkdir -p /var/lib/openattic && \
    mkdir -p /var/lib/openattic/static && \
    cp etc/openattic/database.ini /etc/openattic/database.ini && \
    cp rpm/sysconfig/openattic.RedHat /etc/default/openattic && \
    cp version.txt backend/version.txt && \
    ln -sf /srv/openattic/backend /usr/share/openattic && \
    pip install --upgrade pip && \
    pip install --upgrade setuptools && \
    pip install --upgrade rtslib-fb && \
    pip install -r /srv/openattic/requirements/ubuntu-16.04.txt -i https://pypi.doubanio.com/simple/ 


# Install openATTIC frontend
RUN cd webui && npm install && npm run build && cd .. && \
    cp etc/apache2/conf-available/openattic.conf /etc/httpd/conf.d/openattic.conf && \
    cp webui/redirect.html /var/www/html/index.html && \
    ln -sf /srv/openattic/webui/dist /usr/share/openattic-gui && \
    sed -ri -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' "/etc/httpd/conf/httpd.conf"

# Add group
RUN groupadd -r openattic 2>/dev/null || : && usermod -a --groups openattic wwwrun 2>/dev/null || :

# Add user
RUN useradd -r -g openattic -d /var/lib/openattic -s /bin/bash -c "openATTIC System User" openattic 2>/dev/null || : && \
    usermod -a --groups www openattic 2>/dev/null || :

EXPOSE 5432 80

# Install & Config supervisord
RUN mkdir -p /etc/supervisord/conf.d && pip install supervisor -i https://pypi.doubanio.com/simple/
ADD supervisord/supervisord.conf /etc/supervisord/supervisord.conf
ADD supervisord/httpd.conf /etc/supervisord/conf.d/httpd.conf
ADD supervisord/openattic.conf /etc/supervisord/conf.d/openattic.conf
ADD supervisord/pgsql.conf /etc/supervisord/conf.d/pgsql.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]
