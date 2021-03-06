#!/bin/bash
#
# 2018/1/17
#0 13,23 * * * /bin/bash -xe /usr/local/bin/jenkins_backup.sh >/var/log/jenkins_backup.log 2>&1 &


prefix="jenkins_$(hostname)_$(/usr/sbin/ip a |grep global |grep brd |awk '{print $2}' |awk -F'/' '{print $1}')"
jenkins_home='/var/lib/jenkins'
jenkins_backup_root='/data/backup/jenkins_data'
jenkins_backup_file=${jenkins_backup_root}/${prefix}_$(date +%Y%m%d_%H%M%S).tar.gz
rotate=7


[ -z ${jenkins_backup_root} ] && exit 1
find ${jenkins_backup_root} -maxdepth 1 -type f -name '*.gz' -mtime +${rotate} -print
find ${jenkins_backup_root} -maxdepth 1 -type f -name '*.gz' -mtime +${rotate} -delete

tar zcf ${jenkins_backup_file} ${jenkins_home} \
  --exclude "${jenkins_home}/workspace" \
  --exclude "${jenkins_home}/caches" \
  --exclude "${jenkins_home}/plugins" \
  --exclude "${jenkins_home}/tools"

s_day_of_week=$(date +%u)
if [ ${s_day_of_week} -eq 1 ]; then
  tar zcf ${jenkins_backup_root}/latest.plugins.tar.gz ${jenkins_home}/plugins
  tar zcf ${jenkins_backup_root}/latest.tools.tar.gz ${jenkins_home}/tools
fi
