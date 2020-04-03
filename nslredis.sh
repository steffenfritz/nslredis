#!/usr/bin/env bash
#######################################################################
# FILE:    nslredis.sh
# VERSION: v1.0
# DATE:    2020-04-03
# AUTHOR:  Steffen Fritz (ampoff)
#
# DESCRIPTION: 
#
# nslredis.sh downloads the latest version of the NSRL RDS minimal and
# unzipps the archive, creates a redis protocol file for mass import
# and imports sha-1 as key and TRUE as value into redis.
########################################################################

NOW=`date +"%Y-%m-%d"`


echo "+++ NSLREDIS v1.1.0"
echo

mkdir nsrl_minimal_$NOW && cd nsrl_minimal_$NOW

echo "+++ Downloading metadata"

wget https://s3.amazonaws.com/rds.nsrl.nist.gov/RDS/current/README.txt -q --show-progress
wget https://s3.amazonaws.com/rds.nsrl.nist.gov/RDS/current/RDS_HashCounts.txt -q --show-progress
wget https://s3.amazonaws.com/rds.nsrl.nist.gov/RDS/current/rds_modernm.zip.sha -q --show-progress

echo
echo "+++ Summary release"

RELVERS=`head -1 README.txt`
echo "Release version and date: $RELVERS"
grep -m 1 "rds_modernm.zip" README.txt | awk '{ print "Archive file size: " $2 }'

read -p "Should I download RDS Modern Minimal? [y/n] " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo
    echo "Deleting temp download directory"
    cd ..
    rm -rf nsrl_minimal_$NOW
    echo "Done"
    exit 1
fi

echo 
echo "+++ Downloading rds_modernm.zip"
wget https://s3.amazonaws.com/rds.nsrl.nist.gov/RDS/current/rds_modernm.zip -q --show-progress

# unzip
EXPSIZE=`unzip -l rds_modernm.zip | tail -1 | awk '{ print $1/1000000000 }'`
echo
echo "+++ Expected unzipped size: $EXPSIZE GB"
echo
echo "We will need aprox. `3 * $EXPSIZE` GB of storage."

read -p "Should I proceed? [y/n] " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo
    echo "I do not delete the temp directory."
    exit 1
fi

# ToDo check sha1

echo "+++ Unzipping"
unzip rds_modernm.zip

# create redis protocol
## extract sha1 from NSRLFile.txt and write it to file redis_feed.txt
echo "+++ Creating feed file for redis "
awk -F ",|\"" ' FNR > 1 { print "SET " $2 " TRUE"}' NSRLFile.txt >> redis_feed.txt  

# import into redis
cat redis_feed.txt | redis-cli --pipe

# result

echo "Done"
