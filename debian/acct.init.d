#!/bin/sh

### BEGIN INIT INFO
# Provides:          acct
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: process and login accounting
# Description:       GNU Accounting Utilities is a set of utilities which
#                    reports and summarizes data about user connect times and
#                    process execution statistics.
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/accton
NAME=acct
DESC="process accounting"
LOCKFILE=/var/lock/subsys/acct

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

# Include acct defaults if available
if [ -f /etc/default/acct ]
then
	. /etc/default/acct
else
	ACCT_ENABLE="1"
	ACCT_LOGGING="30"
fi

set -e

case "$1" in
	start)
		if [ "${ACCT_ENABLE}" = "1" ]
		then

		# Have to turn this on to be able to test the return code
		set +e

		/usr/sbin/accton /var/log/account/pacct 2>/dev/null

		rv=$?
		if [ $rv -eq 0 ]
		then
            touch $LOCKFILE
			log_success_msg "Done."
		elif [ $rv -eq 38 ]
		then
			log_failure_msg "Failed."
			log_warning_msg "Process accounting not available on this system."
		elif [ $rv -eq 16 ]
		then
			log_failure_msg "Failed."
			log_warning_msg "Process accounting already running on this system."
		else
			logger -p daemon.err "Unexpected error code $rv received in /etc/init.d/acct"
		fi

		fi

		set -e
		;;

	stop)

		# Have to turn this on to be able to test the return code
		set +e

		/usr/sbin/accton off 2>/dev/null

		if [ $? -eq 0 ]
		then
			log_success_msg "Done."
            rm -f $LOCKFILE
		else
			log_failure_msg "Failed."
			log_warning_msg "Process accounting not available on this system."
		fi

		set -e
		;;

	restart|force-reload)
		$0 stop
		sleep 1
		$0 start
		;;

    status)
        if [ -f $LOCKFILE ]
        then
            echo "Accounting is enabled."
        else
            echo "Accounting is not enabled."
        fi
        ;;

	*)
		N=/etc/init.d/$NAME
		echo "Usage: $N {start|stop|status|restart|force-reload}" >&2
		exit 1
		;;
esac

exit 0
