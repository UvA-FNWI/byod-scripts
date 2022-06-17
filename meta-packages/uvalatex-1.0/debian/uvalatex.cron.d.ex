#
# Regular cron jobs for the uvalatex package
#
0 4	* * *	root	[ -x /usr/bin/uvalatex_maintenance ] && /usr/bin/uvalatex_maintenance
