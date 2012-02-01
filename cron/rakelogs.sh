#!/bin/sh
#
# rakelogs.sh
# Trims the logs of Rails sites so we don't end up going over quota on a
# regular basis (which does bad things to Rails).
#
# This needs to be run regularly (eg daily) from a crontab.  Current
# logs are preserved for investigation if necessary.
#
# The backup logfiles are named xxx.log.1, xxx.log.2 etc, up to the
# amount configured below (with .1 being the most recent).
#
# Note that all *.log files will be processed by this script, regardless 
# of whether rake processes them.
#
# USAGE:
#	rakelogs.sh <num>
#
# OPTIONS:
#	<num> is the amount of backup logs to keep.  If not specified, 
#	 or if it's outside the range of 0 to 100, 5 will be used.
#
# CRON:
#	Note that the HOME variable must be set in the crontab above the call
#	to this file for it to cron properly.
#
# BUGS:
#	None that I know of.

### Configuration begins

# Path to ruby, default rails and rake (differs between dev & production servers).
RUBY_PATH="/usr/bin"

# Path where custom Rails installations put their 'rails' script.
# Relative to the user's home directory.
CUSTOM_RAILS_PATH="www/vendor/rails/railties/bin"

# Where the log files are kept, relative to the user's home directory.
LOG_DIR="www/log"

### Configuration ends

NUM=${1}

if [[ -z "${NUM}" || ${NUM} -gt 100 || ${NUM} -lt 0 ]]; then
        NUM=5
fi

# Use absolute paths in case cron runs this in something other than the home dir.
LOG_DIR=${HOME}/${LOG_DIR}
CUSTOM_RAILS_PATH=${HOME}/${CUSTOM_RAILS_PATH}

pushd ${LOG_DIR} > /dev/null 2>&1;

for logfile in `ls *.log 2> /dev/null`; do
	for((i = ((NUM - 1)); i > 0; i--)); do
		if [ -f ${logfile}.${i} ]; then
			mv ${logfile}.${i} ${logfile}.$((${i}+1))
		fi
	done
	# We copy this one to prevent pulling the carpet out from a 
	# running request.
	cp ${logfile} ${logfile}.1
done

# Now let Rails clear out the running logs
# NOTE: the syntax seems to have changed between Rails 1.0.x and 1.1.x.
# Also, Rails 1.0 seems to output its version string on stderr while v1.1
# sends it to stdout (where it's meant to go!).
#
# UPDATE: the command to get the Rails version number doesn't work on av3.
# A quick web search indicates that it's probably going to be difficult to
# get this, so I'm just going to hard-code it.  Apps with older local Rails
# versions will need to be modified accordingly.

if [ -x ${CUSTOM_RAILS_PATH}/rails ]; then
	RAILS_PATH=${CUSTOM_RAILS_PATH}
else
	RAILS_PATH=${RUBY_PATH}
fi

if [ -x ${RUBY_PATH}/rake ]; then
#	${RUBY_PATH}/rake clear_logs > /dev/null 2>&1; # Rails 1.0 syntax
	${RUBY_PATH}/rake log:clear > /dev/null 2>&1;  # Rails 1.1 / 1.2 syntax
else
	echo "rakelogs: rake not found at ${RAILS_PATH}/!" >&2
fi

popd > /dev/null 2>&1;
