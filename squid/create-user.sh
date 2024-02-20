#!/bin/sh

usage() {
  printf "create-user [-u|--username] <username>\n"
  printf " OPTIONS\n"
  printf "  -u --username\tusername of the new http user (optional)\n"
  printf "  -p --password\tpassword for the new http user (optional)\n"
  printf "  -f --file\tfile name for the configuration file (optional)\n"
  printf "  -h --help\tprint this help\n"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -f|--file) file="$2" shift ;;
        -h|--help) usage ;;
                *) usage ;;
  esac
  shift
done

[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$file" ] && file="/etc/squid/squid.conf"

if test -f "$file"; then
  htpasswd -B -b ${file} ${username} ${password}
else
  htpasswd -c -B -b ${file} ${username} ${password}
fi

echo "User: $username"
echo "Password: $password"
echo "All done. Your HTPASSWD file is available at $file"