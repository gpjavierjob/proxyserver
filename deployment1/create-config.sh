#!/bin/sh

usage() {
  printf "create-config [-c|--client] <client name> [-i|--ips] <ips>\n"
  printf " OPTIONS\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -i --ips\t\tDirecciones IP del cliente, separadas por comas (obligatorio).\n"
  printf "  -n --container-name\t\tNombre del contenedor (obligatorio).\n"
  printf "  -u --username\t\tEl nombre de usuario del cliente (opcional).\n"
  printf "  -p --password\t\tLa contraseña del usuario del cliente (opcional).\n"
  printf "  -f --force\t\tFuerza la creación de los archivos y directorios de configuración.\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE
force=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--client) client="$2" shift ;;
    -i|--ips) ips="$2" shift ;;
    -n|--container-name) container_name="$2" shift ;;
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -f|--force) force=$TRUE ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$client" ] && usage
[ -z "$ips" ] && usage
[ -z "$container_name" ] && usage
[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')

script_dir="$(dirname "$(readlink -f "$0")")"

# Host directories names
conf_dir="/etc/squid/$client"
snippets_dir="$conf_dir/conf.d"
data_dir="/var/squid/$client"
logs_dir="$data_dir/logs"
cache_dir="$data_dir/cache"
# File names
conf_file_name="squid.conf"
snippets_file_name="snippet.conf"
pass_file_name="passwords"
ips_file_name="client-ips.conf"
# Host file paths
conf_file_path="$conf_dir/$conf_file_name"
pass_file_path="$snippets_dir/$pass_file_name"
ips_file_path="$snippets_dir/$ips_file_name"

if [ $force -eq $TRUE ]; then
  # Removing the old configuration
  if [ $verbose -eq $TRUE ]; then
    ("$script_dir/remove-config.sh" "-v" "-c" "$client" "-n" "$container_name")
  else
    ("$script_dir/remove-config.sh" "-c" "$client" "-n" "$container_name")
  fi
fi

if [ $? -gt 0 ]; then
  return 1
fi

echo -n "Creating the client directories on the host ... "

if [ $verbose -eq $TRUE ]; then
  echo ""
  mkdir -v -p ${snippets_dir}
  mkdir -v -p ${logs_dir}
  mkdir -v -p ${cache_dir}
  echo -n "... "
else
  mkdir -p ${snippets_dir}
  mkdir -p ${logs_dir}
  mkdir -p ${cache_dir}
fi

echo "Done."

echo -n "Copying the main configuration file ... "

if [ $verbose -eq $TRUE ]; then
  cp -v -t "$conf_dir" "$script_dir/$container_name/$conf_file_name"
else
  cp -t "$conf_dir" "$script_dir/$container_name/$conf_file_name" > /dev/null
fi

echo "Done."

echo -n "Copying the snippets configuration file ... "

if [ $verbose -eq $TRUE ]; then
  cp -v "$script_dir/$container_name/conf.d/$snippets_file_name" "$snippets_dir"
else
  cp "$script_dir/$container_name/conf.d/$snippets_file_name" "$snippets_dir" > /dev/null
fi

echo "Done."

echo "Generating http access configuration file ... "

if [ $verbose -eq $TRUE ]; then
  ("$script_dir/create-http-user.sh" "-v" "-u" "$username" "-p" "$password" "-f" "$pass_file_path")
else
  ("$script_dir/create-http-user.sh" "-u" "$username" "-p" "$password" "-f" "$pass_file_path" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

echo "... Done."

echo -n "Generating the IPs configuration file ... "

touch "$ips_file_path"

ip_list=$(echo $ips | tr "," "\n")

for ip in $ip_list 
do
    echo "$ip" >> "$ips_file_path"
done

echo "Done."

# Doing the container specific configuration
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/$container_name/do-extra-config.sh" "-v" "-c" "$client")
else
  ("$script_dir/$container_name/do-extra-config.sh" "-c" "$client")
fi

if [ $? -gt 0 ]; then
  return 1
fi

if [ $verbose -eq $TRUE ]; then
  echo "Configuration done."
  echo "Your main configuration file is available at $conf_dir/$conf_file_name"
  echo "Your configuration snippets file is available at $snippets_dir/$snippets_file_name"
  echo "Your user/password pairs file is available at $pass_file_path"
  echo "Your ips file is available at $ips_file_path"
  echo "Your logs directory is available at $logs_dir"
  echo "Your cache directory is available at $cache_dir"
fi