#!/bin/sh
#
# cleansessions.sh
# Removes old session files so we don't end up going over quota on a
# regular basis (which does bad things to Rails).
#
# This needs to be run regularly (eg daily) from a crontab.
#
# USAGE:
#	cleansessions.sh
#
# OPTIONS:
#	None
#
# BUGS:
#	None that I know of.

### Configuration begins

# Where the log files are kept, relative to the user's home directory.
SESS_DIR="www/tmp/sessions"

### Configuration ends

# Use absolute paths in case cron runs this in something other than the home dir.
SESS_DIR=${HOME}/${SESS_DIR}

pushd ${SESS_DIR} > /dev/null 2>&1;

# delete all session files that haven't been accessed for 3 days
find . -mtime +2 -exec rm -f {} \;

# delete all session files that were created more than 7 days ago
find . -ctime +6 -exec rm -f {} \;

popd > /dev/null 2>&1;
