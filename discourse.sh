#! /bin/bash
# -*- coding: utf-8 -*-
# Discurse

#DISQDB=""
#DISQDB_USR=""
#DISQDB_USR_PS=""

sudo -u postgres psql -c "CREATE DATABASE $DISQDB \
ENCODING 'Unicode' \
LC_COLLATE 'ru_RU.UTF-8' \
LC_CTYPE 'ru_RU.UTF-8' \
TEMPLATE template0;" 

sudo -u postgres psql -c "CREATE USER $DISQDB_USR PASSWORD '$DISQDB_USR_PS';"
sudo -u postgres psql -c "GRANT ALL privileges ON DATABASE $DISQDB TO $DISQDB_USR;" 