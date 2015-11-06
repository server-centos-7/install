#! /bin/bash
# -*- coding: utf-8 -*-
# Solr
################################################################
# Install Java 1.8
yum -y install java-1.8.0-openjdk

################################################################
# Install Solr 1.5
yum -y yinstall unzip zip lsof patch
adduser solr
cd /opt
wget http://apache-mirror.rbc.ru/pub/apache/lucene/solr/5.3.1/solr-5.3.1.tgz
tar -zxvf solr-5.3.1.tgz
firewall-cmd --add-port=8983/tcp --permanent
cp /opt/solr-5.3.1/bin/install_solr_service.sh .
./install_solr_service.sh solr-5.3.1.tgz
rm -rf solr-5.3.1 solr-5.3.1.tgz
cd /tmp
wget http://ftp.drupal.org/files/projects/search_api_solr-7.x-1.x-dev.tar.gz
tar -zxvf search_api_solr-7.x-1.x-dev.tar.gz
cd search_api_solr
wget https://www.drupal.org/files/issues/solr5_conf.patch
patch -p0 < solr5_conf.patch
# русская морфология
wget http://download.services.openoffice.org/files/contrib/dictionaries/ru_RU.zip
unzip ru_RU.zip -d ru_RU
sed -i 's#SET KOI8-R#SET UTF-8#g' ru_RU/ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.aff > solr-conf/5.x/ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.dic > solr-conf/5.x/ru_RU.dic
rm -rf ru_RU ru_RU.zip




mkdir -p /var/solr/data/axept/conf
cp -a search_api_solr/solr-conf/5.x/* /var/solr/data/axept/conf
chown -R solr:solr /var/solr/
# меняем дирректорию для индекса
sed -i 's#<dataDir>${solr.data.dir:}</dataDir>#<dataDir>/data/solr/axept/</dataDir>#g' /var/solr/data/axept/conf/solrconfig.xml
mkdir -p /data/solr/axept
chown -R solr:solr /data/solr
/opt/solr/bin/solr create -c axept
systemctl start solr.service
chkconfig --add solr

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Solr OK]"
$SETCOLOR_NORMAL
echo
