#! /bin/sh
#
# entrypoint.sh

set -e
[[ "$DEBUG" == "true" ]] && set -x

# Set environments

[ -f /etc/php7/templates/php-fpm.conf -a ! -f /etc/php7/php-fpm.conf ] && {
  cp /etc/php7/templates/php-fpm.conf /etc/php7/
  sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf
  sed -i "s|;*error_log\s*=\s*log/php7/error.log|error_log = /proc/self/fd/2|g" /etc/php7/php-fpm.conf
}

[ -f /etc/php7/templates/php-fpm.d/www.conf -a ! -f /etc/php7/php-fpm.d/www.conf ] && {
  cp /etc/php7/templates/php-fpm.d/www.conf /etc/php7/php-fpm.d/
  sed -i "s|;*access.log\s*=\s*log/php7/\$pool.access.log|access.log = /proc/self/fd/1|g" /etc/php7/php-fpm.d/www.conf
  sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = 127.0.0.1:9000|g" /etc/php7/php-fpm.d/www.conf
  sed -i "s|;*listen.mode\s*=\s*0660|listen.mode = 0666|g" /etc/php7/php-fpm.d/www.conf
  sed -i "s|;*chdir\s*=\s*/var/www|chdir = /var/www|g" /etc/php7/php-fpm.d/www.conf
  sed -i "s|pm.max_children =.*|pm.max_children = ${PM_MAX_CHILDREN}|i" /etc/php7/php-fpm.d/www.conf
  sed -i "s|pm.start_servers =.*|pm.start_servers = ${PM_START_SERVERS}|i" /etc/php7/php-fpm.d/www.conf
  sed -i "s|pm.min_spare_servers =.*|pm.min_spare_servers = ${PM_MIN_SPARE_SERVERS}|i" /etc/php7/php-fpm.d/www.conf
  sed -i "s|pm.max_spare_servers =.*|pm.max_spare_servers = ${PM_MAX_SPARE_SERVERS}|i" /etc/php7/php-fpm.d/www.conf
  sed -i "s|user =.*|user = www|i" /etc/php7/php-fpm.d/www.conf
  sed -i "s|group =.*|group = www-data|i" /etc/php7/php-fpm.d/www.conf
}

[ -f /etc/php7/templates/php.ini -a ! -f /etc/php7/php.ini ] && {
  cp /etc/php7/templates/php.ini /etc/php7/
  sed -i "s|;*date.timezone =.*|date.timezone = ${DATE_TIMEZONE}|i" /etc/php7/php.ini
  sed -i "s|;*memory_limit =.*|memory_limit = ${MEMORY_LIMIT}|i" /etc/php7/php.ini
  sed -i "s|;*max_execution_time =.*|max_execution_time = ${MAX_EXECUTION_TIME}|i" /etc/php7/php.ini
  sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${UPLOAD_MAX_FILESIZE}|i" /etc/php7/php.ini
  sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${MAX_FILE_UPLOADS}|i" /etc/php7/php.ini
  sed -i "s|;*post_max_size =.*|post_max_size = ${POST_MAX_SIZE}|i" /etc/php7/php.ini
  sed -i "s|;\s*max_input_vars =.*|max_input_vars = ${MAX_INPUT_VARS}|i" /etc/php7/php.ini
  sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini
}

if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
  echo >&3 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"
  
  echo >&3 "$0: Looking for shell scripts in /docker-entrypoint.d/"
  find "/docker-entrypoint.d/" -follow -type f -print | sort -n | while read -r f; do
      case "$f" in
          *.sh)
              if [ -x "$f" ]; then
                echo >&3 "$0: Launching $f";
                "$f"
              else
                # warn on shell scripts without exec bit
                echo >&3 "$0: Ignoring $f, not executable";
              fi
              ;;
          *) echo >&3 "$0: Ignoring $f";
      esac
  done
  
  echo >&3 "$0: Configuration complete; ready for start up"
else
  echo >&3 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
fi

mkdir -p /var/www

#addgroup -g ${GID} -S phpgroup && adduser -u ${UID} -G phpgroup -H -D -s /sbin/nologin phpuser

[[ $(stat -c %U /var/www) == "www" ]] || chown -R www /var/www
[[ $(stat -c %G /var/www) == "www-data" ]] || chgrp -R www-data /var/www

exec "$@"
