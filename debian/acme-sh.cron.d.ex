#
# Regular cron jobs for the acme-sh package
#
0 4	* * *	root	[ -x /usr/bin/acme-sh_maintenance ] && /usr/bin/acme-sh_maintenance
