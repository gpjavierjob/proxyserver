#!/bin/sh

usage() {
  printf "create-http-user [-u|--username] <username>\n"
  printf " OPTIONS\n"
  printf "  -u --username\t\tEl nombre de usuario del nuevo usuario http (opcional)\n"
  printf "  -p --password\t\tLa contraseña para el nuevo usuario http (opcional)\n"
  printf "  -f --file\t\tRuta de archivo de configuración (opcional)\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando\n"
  printf "  -h --help\t\tImprime esta ayuda\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -f|--filepath) filepath="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

script_dir="$(dirname "$(readlink -f "$0")")"

[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$filepath" ] && filepath="$script_dir/passwords"

if test -f "$filepath"; then
  if [ $verbose -eq $TRUE ]; then
    htpasswd -B -b ${filepath} ${username} ${password}
  else
    htpasswd -B -b ${filepath} ${username} ${password} > /dev/null 2>&1
  fi
else
  if [ $verbose -eq $TRUE ]; then
    htpasswd -c -B -b ${filepath} ${username} ${password}
  else
    htpasswd -c -B -b ${filepath} ${username} ${password} > /dev/null 2>&1
  fi
fi

if [ $? -gt 0 ]; then
  echo "Error creating the password."
  return 1
fi

echo "User/password creation done."

if [ $verbose -eq $TRUE ]; then
  echo "Your HTPASSWD file is available at $filepath."
fi