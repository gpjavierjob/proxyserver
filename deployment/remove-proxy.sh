#!/bin/sh

usage() {
  printf "remove-proxy [-c|--client] <client name>\n"
  printf "\n"
  printf "Desinstala el proxy del cliente con el nombre de contenedor proporcionado. El nombre del\n"
  printf "cliente es un parámetro obligatorio, mientras que el nombre del contenedor es opcional.\n"
  printf "Si no se proporciona el nombre del contenedor se utilizará ubuntu-squid como valor\n"
  printf "predeterminado. Detecta, a partir del archivo installs, si la instalación se realizó\n"
  printf "en Docker o MicroK8s.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -n --container-name\t\tNombre del contenedor docker de Squid (opcional).\n"
  printf "  -v --verbose\t\tExplica los pasos que se están ejecutando con más detalles.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0
NONE="None"

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--client) client="$2" shift ;;
    -n|--container-name) container_name="$2" shift ;;
    -v|--verbose) verbose=$TRUE ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

script_path="$(readlink -f "$0")"
script_dir="$(dirname ${script_path})"
script_fullname="$(basename ${script_path})"
script_name="${script_fullname%.*}"
defaults_file_path="$script_dir/$script_name.defaults"

# Read default values if file exists
if [ -r ${defaults_file_path} ]; then
  if [ -z "$client" ]; then client="$(grep --color=never -Po "^client=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$container_name" ]; then container_name="$(grep --color=never -Po "^container_name=\K.*" $defaults_file_path || true)"; fi
fi 

[ -z "$client" ] && usage
[ -z "$container_name" ] && container_name="ubuntu-squid"

# Ensure a valid value for client name
client=$(echo "$client" | tr -d -c [:alnum:]) # | tr '[a-z]' '[A-Z]')

# Getting the deployment type from installs file
installs_path="$script_dir/installs"
grep_cmd="grep --color=never -Po ^"$client"=\K.* "$installs_path""
deploy_file_path="$($grep_cmd)"

# Check deployment type
if [ "$deploy_file_path" = $NONE ]; then
  # Uninstalling from docker
  echo -n "Stopping the container ... "

  if [ $verbose -eq $TRUE ]; then
    echo ""
    docker stop "$container_name"
    echo -n "... "
  else
    docker stop "$container_name" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error stopping the proxy container on Docker."
    return 1
  fi

  echo "Done."

  echo -n "Removing the container ... "

  if [ $verbose -eq $TRUE ]; then
    echo ""
    docker rm "$container_name"
    echo -n "... "
  else
    docker rm "$container_name" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error removing the proxy from Docker."
    return 1
  fi

  echo "Done."

  echo "The docker container has been uninstalled."
else
  # Uninstalling from MicroK8s
  echo -n "Removing the MicroK8s objects ... "

  if [ -r ${deploy_file_path} ]; then
    if [ $verbose -eq $TRUE ]; then
      echo ""
      microk8s kubectl delete -f "$deploy_file_path"
      echo "... "
    else
      microk8s kubectl delete -f "$deploy_file_path" > /dev/null
    fi

    if [ $? -gt 0 ]; then
      echo "Error removing the resources from MicroK8s."
      return 1
    fi

    rm -f "$deploy_file_path"
  else
      echo "Error reading from the deployment file. The resources have not been removed from MicroK8s."
      return 1
  fi 
  
  echo "Done."
  echo "The proxy has been uninstalled from MicroK8s."
fi

# Removing the installation configuration 
if [ -w ${installs_path} ]; then
  # Removes the line where the client name appears from installs file
  sed -i.bkp "/$client/d" "$installs_path"
else
  echo "The installs file has not been updated"
fi

# Removing the configuration files and directories
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/remove-config.sh" "-v" "-c" "$client" "-n" "$container_name")
else
  ("$script_dir/remove-config.sh" "-c" "$client" "-n" "$container_name" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

echo "Uninstallation done."
