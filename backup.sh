#!/bin/bash

# посмотреть на https://github.com/pontikis/bash-cloud-backup

DATE=`date '+%Y-%m-%d_%H:%M:%S-%Z'`
OUTPUT_DIRECTORY=/OMERO/backup/database
DATABASE="omero_database"
DATABASE_ADMIN="postgres"

mkdir -p $OUTPUT_DIRECTORY
chown -R $DATABASE_ADMIN $OUTPUT_DIRECTORY
su $DATABASE_ADMIN -c "pg_dump -Fc -f $OUTPUT_DIRECTORY/$DATABASE.$DATE.pg_dump $DATABASE"