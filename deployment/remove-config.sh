#!/bin/sh

usage() {
  printf "remove-config [-c|--client] <client name>\n"
  printf " OPTIONS\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -n --container-name\t\tNombre del contenedor (obligatorio).\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--client) client="$2" shift ;;
    -n|--container-name) container_name="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$client" ] && usage
[ -z "$container_name" ] && usage

# Undoing the container specific configuration
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/$container_name/undo-extra-config.sh" "-v" "-c" "$client")
else
  ("$script_dir/$container_name/undo-extra-config.sh" "-c" "$client")
fi

if [ $? -gt 0 ]; then
  return 1
fi

echo "Removing the configuration files and directories from the host ... "

script_dir="$(dirname "$(readlink -f "$0")")"

# Host directories names
conf_dir="/etc/squid/$client"
data_dir="/var/squid/$client"

if [ $verbose -eq $TRUE ]; then
  echo ""
  rm -v -f -r "$conf_dir" "$data_dir"
  echo -n "... "
else
  rm -f -r "$conf_dir" "$data_dir" > /dev/null 2>&1
fi

if [ $? -gt 0 ]; then
  echo "Error removing files and directories."
  return 1
fi

echo "Done."
