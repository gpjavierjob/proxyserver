#!/bin/sh

usage() {
  printf "remove-client [-s|--server] <server name> [-c|--client] <client name>\n"
  printf " \n"
  printf " Elimina el cliente proporcionado del servidor indicado. \n"
  printf " Tanto el nombre del servidor como el del cliente son obligatorios.\n"
  printf " \n"
  printf " OPTIONS\n"
  printf "  -s --server\t\tNombre del servidor (obligatorio).\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--server) server="$2" shift ;;
    -c|--client) client="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$server" ] && usage
[ -z "$client" ] && usage

script_dir="$(dirname "$(readlink -f "$0")")"

# Host directories names
conf_dir="/etc/squid/$server"
snippets_dir="$conf_dir/conf.d"
# File names
pass_file_name="passwords"
ips_file_name="client-ips.conf"
# Host file paths
pass_file_path="$snippets_dir/$pass_file_name"
ips_file_path="$snippets_dir/$ips_file_name"
client_file_path="$conf_dir/$client"
qr_file_path="$conf_dir/$client.png"

# Extracting client parameters from client file.
if ! [ -r ${client_file_path} ]; then
  echo "Error: The client file is not accessible"
  exit 1
fi

grep_cmd="grep --color=never -Po ^username=\K.* $client_file_path"
username="$($grep_cmd)"
grep_cmd="grep --color=never -Po ^ips=\K.* $client_file_path"
ips="$($grep_cmd)"

[ $verbose -eq $TRUE ] && echo "Updating http access configuration file ... "

if [ $verbose -eq $TRUE ]; then
  sed -i "/$username/d" "$pass_file_path"
else
  sed -i "/$username/d" "$pass_file_path" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error: The client security parameters can not be removed"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... http access configuration file updated."

[ $verbose -eq $TRUE ] && echo "Updating the IPs configuration file ... "

ip_list=$(echo $ips | tr "," "\n")

for ip in $ip_list 
do
  # Si varias líneas contienen la dirección IP, sólo debe eliminarse una
  # Buscando el número de la primera línea que contiene la dirección IP ...
  first_line_number=$(awk 'match($0,v){print NR; exit}' v="$ip" "$ips_file_path")
  if ! [ -z "$first_line_number" ]; then
    # Si encuentra la línea, eliminarla ...
    sed -i "$first_line_number"d "$ips_file_path"

    if [ $? -gt 0 ]; then
      echo "Error: The client ips can not be removed"
      return 1
    fi
  fi 
done

[ $verbose -eq $TRUE ] && echo "... IPs configuration file updated."

# Removing client qr file.
if [ -w ${qr_file_path} ]; then
  rm -f "$qr_file_path"
else
  echo "Warning: The client QR file was not removed"
fi

# Removing client file.
if [ -w ${client_file_path} ]; then
  rm -f "$client_file_path"
else
  echo "Warning: The client file was not removed"
fi

# Restarting proxy
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/restart-proxy.sh" "-v" "-n" "$server")
else
  ("$script_dir/restart-proxy.sh" "-n" "$server" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

[ $verbose -eq $TRUE ] && echo "Client removed."
