#!/bin/sh

usage() {
  printf "create-user [-u|--username] <username>\n"
  printf " OPTIONS\n"
  printf "  -u --username\t\tusername of the new http user (optional)\n"
  printf "  -p --password\t\tpassword for the new http user (optional)\n"
  printf "  -f --file\t\tpath for the configuration file (optional)\n"
  printf "  -h --help\t\tprint this help\n"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -f|--filepath) filepath="$2" shift ;;
        -h|--help) usage ;;
                *) usage ;;
  esac
  shift
done

[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$filepath" ] && filepath="./passwords"

if test -f "$filepath"; then
  htpasswd -B -b ${filepath} ${username} ${password}
else
  htpasswd -c -B -b ${filepath} ${username} ${password}
fi

echo "All done. Your HTPASSWD file is available at $filepath"