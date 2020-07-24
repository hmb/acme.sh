#
# LetsEncrypt certificate renewal
# Cron job for the acme-sh package
#
# Copyright © Holger Böhnke <holger.boehnke@amarin.de>
# distributed under the terms of the GPL v3
#

# set the mail address this cronjob mails to
#MAILTO=le-admin@example.com

# renew certificated due to renewal once a day
# m h dom mon dow user     command
31  3 *   *   *   acmesh   [ -x /usr/bin/acme.sh ] && /usr/bin/acme.sh --cron >> /var/log/acme-sh/cron-out.log 2>&1
