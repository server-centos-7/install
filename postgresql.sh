#! /bin/bash
# -*- coding: utf-8 -*-
# PostgreSQL
POSTGRES_PS=$(whiptail --title "Пароль для базы данных" --inputbox "Введите пароль для базы данных PostgreSQL и нажмите Ok для продолжения." 10 60 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
#POSTGRES_PS=""

################################################################
# Install Postgress
yum -y install http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-2.noarch.rpm
yum -y install postgresql94-server pgtune pg_top
echo "export PATH=\$PATH:/usr/pgsql-9.4/bin" >> ~/.bash_profile
su - postgres -c "echo \"export PATH=\$PATH:/usr/pgsql-9.4/bin\" >> ~/.bash_profile"
## меняем дирректорию 
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Confined_Services/sect-Managing_Confined_Services-PostgreSQL-Configuration_Examples.html
mkdir -p /log/postgres
chown -R postgres:postgres /log/postgres
mkdir -p /data/db_transac_log/pgsql/pg_xlog
chown -R postgres:postgres /data/db_transac_log/pgsql
mkdir -p /db/pgsql
chown -R postgres:postgres /db/pgsql/
chcon -t postgresql_db_t /db/pgsql/
su - postgres -c "initdb \
-D /db/pgsql \
-X /data/db_transac_log/pgsql/pg_xlog \
--pwprompt \
-A md5 \
--locale=ru_RU.UTF-8 \
--lc-messages=en_US.UTF-8 \
--text-search-config='russian'"

semanage fcontext -a -t postgresql_db_t "/db/pgsql(/.*)?"
restorecon -Rv /db/pgsql
cp /usr/lib/systemd/system/postgresql-9.4.service /etc/systemd/system/postgresql-9.4.service
sed -i 's#Environment=PGDATA=/var/lib/pgsql/9.4/data/#Environment=PGDATA=/db/pgsql/#g' /etc/systemd/system/postgresql-9.4.service
sed -i '31 i PGLOG=/log/postgres/pgstartup.log' /etc/systemd/system/postgresql-9.4.service
systemctl daemon-reload
## настраиваем
pgtune \
    -i /db/pgsql/postgresql.conf \
    -o /db/pgsql/postgresql.conf.pgtune \
    --memory=4294967296 \
    --type=Web \
    --connections=500
sed -i 's#US/Eastern#Europe/Moscow#g' /db/pgsql/postgresql.conf.pgtune
echo "port = 5432" >> /db/pgsql/postgresql.conf.pgtune
echo "ssl = false" >> /db/pgsql/postgresql.conf.pgtune
echo "unix_socket_directory = '/var/run/postgresql'" >> /db/pgsql/postgresql.conf.pgtune
echo "default_text_search_config = 'pg_catalog.russian'" >> /db/pgsql/postgresql.conf.pgtune
sed -i 's#pg_log#/log/postgres#g' /db/pgsql/postgresql.conf.pgtune
# Полнотекстовой поиск
cd /tmp
wget http://download.services.openoffice.org/files/contrib/dictionaries/ru_RU.zip
unzip ru_RU.zip -d ru_RU
sed -i 's#SET KOI8-R#SET UTF-8#g' ru_RU/ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.aff > /usr/pgsql-9.4/share/tsearch_data/russian.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.dic > /usr/pgsql-9.4/share/tsearch_data/russian.dic
rm -rf ru_RU ru_RU.zip

wget http://download.services.openoffice.org/files/contrib/dictionaries/en_US.zip
unzip en_US.zip -d en_US
sed -i 's#SET ISO8859-1#SET UTF-8#g' en_US/en_US.aff
iconv -f iso-8859-1 -t utf-8 en_US/en_US.aff > /usr/pgsql-9.4/share/tsearch_data/english.aff
iconv -f iso-8859-1 -t utf-8 en_US/en_US.dic > /usr/pgsql-9.4/share/tsearch_data/english.dic 
rm -rf en_US en_US.zip


cd /tmp
wget https://stop-words.googlecode.com/files/stop-words-collection-2011.11.21.zip
unzip stop-words-collection-2011.11.21.zip
cat stop-words/stop-words-english3-google.txt english.stop | sort | uniq -u > /usr/pgsql-9.4/share/tsearch_data/english.stop
cat stop-words/stop-words-russian.txt russian.stop | sort | uniq -u > /usr/pgsql-9.4/share/tsearch_data/russian.stop
rm -rf stop-words-collection-2011.11.21.zip  stop-words project-information.txt

######################### варинт словарей hunspell ########################
# русские словари hunspell Alexander I. Lebedev
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/ru_RU.dic
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/ru_RU.dic_delta
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/ru_RU.aff
# русские словари в KOI8-R конвертируем в UTF-8
sed -i 's#SET KOI8-R#SET UTF-8#g' ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU.aff > /usr/pgsql-9.4/share/tsearch_data/ru_ru.affix
iconv -f KOI8-R -t UTF-8 ru_RU.dic
iconv -f KOI8-R -t UTF-8 ru_RU.dic_delta
# удаляем первую строку
sed -i 1d ru_RU.dic
# объединяем с дельтой
cat ru_RU.dic ru_RU.dic_delta | sort > /usr/pgsql-9.4/share/tsearch_data/ru_ru.dict
sed -i 1d /usr/pgsql-9.4/share/tsearch_data/ru_ru.dict
# английские словари hunspell SCOWL из коробки в UTF-8
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/en_US.dic
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/en_US.dic_delta
wget http://src.chromium.org/svn/trunk/deps/third_party/hunspell_dictionaries/en_US.aff -O /usr/pgsql-9.4/share/tsearch_data/en_us.affix
## Remove first line
sed -i 1d en_US.dic
## Concat the dic and dic_delta, sort alphabetically and remove the leading blank line (leaves the ending newline intact)
cat en_US.dic en_US.dic_delta | sort > /usr/pgsql-9.4/share/tsearch_data/en_us.dict
sed -i 1d /usr/pgsql-9.4/share/tsearch_data/en_us.dict
## clean up
rm -rf en_US* ru_RU*
###########################################################################





# \dF+ russian
sudo -u postgres psql -c "
"



mv /db/pgsql/postgresql.conf /db/pgsql/postgresql-factory-default.conf
mv /db/pgsql/postgresql.conf.pgtune /db/pgsql/postgresql.conf
chown postgres:postgres /db/pgsql/postgresql.conf
mkdir -p /data/log/postgres
chown postgres:postgres /data/log/postgres
sed -i '84 s/trust/md5/g' /db/pgsql/pg_hba.conf
sed -i '86 s/trust/md5/g' /db/pgsql/pg_hba.conf
sed -i '88 s/trust/md5/g' /db/pgsql/pg_hba.conf

systemctl enable postgresql-9.4.service
systemctl start postgresql-9.4.service
# создаем пользователя и базу данных для discourse
# createdb и dropdb

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PS';"
systemctl restart postgresql-9.4.service

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[PostgreSQL OK]"
$SETCOLOR_NORMAL
echo

else
	echo "You chose Cancel."
fi
