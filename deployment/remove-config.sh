#!/bin/sh

usage() {
  printf "remove-config [-n|--name] <server name> [-c|--container-name] <container name>\n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
  printf "  -c --container-name\t\tNombre del contenedor (opcional).\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) name="$2" shift ;;
    -c|--container-name) container_name="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$name" ] && usage

script_dir="$(dirname "$(readlink -f "$0")")"

# Host directories names
conf_dir="/etc/squid/$name"
data_dir="/var/squid/$name"
# Host file paths
servers_file_path="/etc/squid/servers"

if [ -z "$container_name" ]; then
  # Getting the container name from servers file.
  if ! [ -e ${servers_file_path} ]; then
    echo "Error: The servers file does not exist"
    return 1
  fi

  if ! [ -r ${servers_file_path} ]; then
    echo "Error: The servers file is not accessible"
    return 1
  fi

  # Getting the container name
  grep_cmd="grep --color=never -Po ^$name=\K.* $servers_file_path"
  container_name="$($grep_cmd)"

  if [ -z "$container_name" ]; then
    echo "Error: The server has no associated container"
    return 1
  fi
fi

# Undoing the container specific configuration
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/$container_name/undo-extra-config.sh" "-v" "-n" "$name")
else
  ("$script_dir/$container_name/undo-extra-config.sh" "-n" "$name")
fi

if [ $? -gt 0 ]; then
  echo "Error: The extra configuration can not be undone."
  return 1
fi

[ $verbose -eq $TRUE ] && echo "Removing the configuration files and directories from the host ... "

script_dir="$(dirname "$(readlink -f "$0")")"

if [ $verbose -eq $TRUE ]; then
  rm -v -f -r "$conf_dir" "$data_dir"
else
  rm -f -r "$conf_dir" "$data_dir" > /dev/null 2>&1
fi

if [ $? -gt 0 ]; then
  echo "Error: The files and directories were not removed."
  return 1
fi

# Removing server from servers file.
if [ -w ${servers_file_path} ]; then
  sed -i "/$name/d" "$servers_file_path"
else
  echo "Warning: The server was not removed from servers file"
fi

[ $verbose -eq $TRUE ] && echo "... configuration files and directories removed."
