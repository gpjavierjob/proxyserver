#!/bin/sh

usage() {
  printf "create-config [-n|--name] <server name> [-c|--container-name] <container name>\n"
  printf "\n"
  printf "Crea los directorios y archivos de configuración del servidor Squid.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
  printf "  -c --container-name\t\tNombre del contenedor (obligatorio).\n"
  printf "  -f --force\t\tFuerza la creación de los archivos y directorios de configuración (opcional).\n"
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
    -n|--name) name="$2" shift ;;
    -c|--container-name) container_name="$2" shift ;;
    -f|--force) force=$TRUE ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$name" ] && usage
[ -z "$container_name" ] && usage

script_dir="$(dirname "$(readlink -f "$0")")"

# Host directories names
conf_dir="/etc/squid/$name"
snippets_dir="$conf_dir/conf.d"
data_dir="/var/squid/$name"
logs_dir="$data_dir/logs"
cache_dir="$data_dir/cache"
# File names
conf_file_name="squid.conf"
snippets_file_name="snippet.conf"
pass_file_name="passwords"
ips_file_name="client-ips.conf"
# Host file paths
pass_file_path="$snippets_dir/$pass_file_name"
ips_file_path="$snippets_dir/$ips_file_name"
servers_file_path="/etc/squid/servers"

if [ $force -eq $TRUE ]; then
  # Removing the old configuration
  if [ $verbose -eq $TRUE ]; then
    ("$script_dir/remove-config.sh" "-v" "-n" "$name" "-c" "$container_name")
  else
    ("$script_dir/remove-config.sh" "-n" "$name" "-c" "$container_name")
  fi

  if [ $? -gt 0 ]; then
    return 1
  fi
fi

[ $verbose -eq $TRUE ] && echo "Creating the server directories on the host ... "

if [ $verbose -eq $TRUE ]; then
  mkdir -v -p ${snippets_dir}
  if [ $? -eq 0 ]; then mkdir -v -p ${logs_dir}; fi
  if [ $? -eq 0 ]; then mkdir -v -p ${cache_dir}; fi
else
  mkdir -p ${snippets_dir} > /dev/null
  if [ $? -eq 0 ]; then mkdir -p ${logs_dir} > /dev/null; fi
  if [ $? -eq 0 ]; then mkdir -p ${cache_dir} > /dev/null; fi
fi

if [ $? -gt 0 ]; then
  echo "Error: Impossible to create the server directories on the host"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... server directories on the host created."

[ $verbose -eq $TRUE ] && echo "Copying the main configuration file ... "

if [ $verbose -eq $TRUE ]; then
  cp -v -t "$conf_dir" "$script_dir/$container_name/$conf_file_name"
else
  cp -t "$conf_dir" "$script_dir/$container_name/$conf_file_name" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error: Impossible to copy the main configuration file"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... main configuration file copied."

[ $verbose -eq $TRUE ] && echo "Copying the snippets configuration file ... "

if [ $verbose -eq $TRUE ]; then
  cp -v "$script_dir/$container_name/conf.d/$snippets_file_name" "$snippets_dir"
else
  cp "$script_dir/$container_name/conf.d/$snippets_file_name" "$snippets_dir" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error: Impossible to copy the snippets configuration file"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... snippets configuration file copied."

[ $verbose -eq $TRUE ] && echo "Generating http access configuration file ... "

if [ $verbose -eq $TRUE ]; then
  touch "$pass_file_path"
else
  touch "$pass_file_path" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error: Impossible to generate the http access configuration file"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... http access configuration file generated."

[ $verbose -eq $TRUE ] && echo "Generating the IPs configuration file ... "

if [ $verbose -eq $TRUE ]; then
  touch "$ips_file_path"
else
  touch "$ips_file_path" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error: Impossible to generate the IPs configuration file"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... IPs configuration file generated."

# Doing the container specific configuration
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/$container_name/do-extra-config.sh" "-v" "-n" "$name")
else
  ("$script_dir/$container_name/do-extra-config.sh" "-n" "$name" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

# Storing server configuration.
echo "$name=$container_name" > "$servers_file_path"

if [ $verbose -eq $TRUE ]; then
  echo "Configuration done."
  echo "Your main configuration file is available at $conf_dir/$conf_file_name"
  echo "Your configuration snippets file is available at $snippets_dir/$snippets_file_name"
  echo "Your user/password pairs file is available at $pass_file_path"
  echo "Your ips file is available at $ips_file_path"
  echo "Your logs directory is available at $logs_dir"
  echo "Your cache directory is available at $cache_dir"
fi