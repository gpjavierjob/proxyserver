#!/bin/sh

usage() {
  printf "remove-proxy [-n|--name] <server name>\n"
  printf "\n"
  printf "Desinstala el proxy del cliente con el nombre de contenedor proporcionado. El nombre del\n"
  printf "cliente es un parámetro obligatorio, mientras que el nombre del contenedor es opcional.\n"
  printf "Si no se proporciona el nombre del contenedor se utilizará ubuntu-squid como valor\n"
  printf "predeterminado. Detecta, a partir del archivo installs, si la instalación se realizó\n"
  printf "en Docker o MicroK8s.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
  printf "  -c --container-name\t\tNombre del contenedor docker de Squid (opcional).\n"
  printf "  -v --verbose\t\tExplica los pasos que se están ejecutando con más detalles.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0
NONE="None"
PENDING="pending"

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) name="$2" shift ;;
    -c|--container-name) container_name="$2" shift ;;
    -v|--verbose) verbose=$TRUE ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$name" ] && usage

# Ensure a valid value for server name
name=$(echo "$name" | tr -d -c [:alnum:]) # | tr '[a-z]' '[A-Z]')

script_path="$(readlink -f "$0")"
script_dir="$(dirname ${script_path})"
script_fullname="$(basename ${script_path})"
script_name="${script_fullname%.*}"
defaults_file_path="$script_dir/$script_name.defaults"
servers_file_path="/etc/squid/servers"
installs_path="$script_dir/installs"

# Checking for a previous installation
# Getting the deployment type from installs file
grep_cmd="grep --color=never -Po ^"$name"=\K.* "$installs_path""
deploy_file_path="$($grep_cmd)"

if [ $? -gt 0 ]; then
  echo "Error: A server named $name does not exist."
  return 1
fi


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

# Check deployment type
if [ "$deploy_file_path" = $NONE ]; then
  # Uninstalling from docker
  [ $verbose -eq $TRUE ] && echo "Stopping the container ... "

  if [ $verbose -eq $TRUE ]; then
    docker stop "$container_name"
  else
    docker stop "$container_name" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error: Failed to stop the proxy container on Docker."
    return 1
  fi

  [ $verbose -eq $TRUE ] && echo "... container stopped."

  [ $verbose -eq $TRUE ] && echo "Removing the container ... "

  if [ $verbose -eq $TRUE ]; then
    docker rm "$container_name"
  else
    docker rm "$container_name" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error: Failed to remove the proxy from Docker."
    return 1
  fi

  if [ $verbose -eq $TRUE ]; then
    echo "... container removed."
    echo "The docker container has been uninstalled."
  fi
elif [ "$deploy_file_path" != $PENDING ]; then
  # Uninstalling from MicroK8s
  [ $verbose -eq $TRUE ] && echo "Removing the MicroK8s resources ... "

  if ! [ -r "$deploy_file_path" ]; then
    echo "Error: Failed to read from the deployment file. The resources have not been removed from MicroK8s."
    return 1
  fi 

  if [ $verbose -eq $TRUE ]; then
    # microk8s kubectl delete -f "$deploy_file_path" --namespace="$name"
    microk8s kubectl delete namespace "$name" --ignore-not-found=true
  else
    # microk8s kubectl delete -f "$deploy_file_path" --namespace="$name" > /dev/null
    microk8s kubectl delete namespace "$name" --ignore-not-found=true > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error: Failed to remove the resources from MicroK8s."
    return 1
  fi

  [ -w "$deploy_file_path" ] && rm -f "$deploy_file_path"
  
  if [ $? -gt 0 ]; then
    echo "Warning: Failed to remove the deployment file."
  fi 

  if [ $verbose -eq $TRUE ]; then
    echo "... MicroK8s resources removed."
    echo "The proxy has been uninstalled from MicroK8s."
  fi
fi

# Removing the installation configuration 
if [ -w ${installs_path} ]; then
  # Removes the line where the server name appears from installs file
  sed -i.bkp "/$name/d" "$installs_path"
else
  echo "Warning: The installs file was not updated"
fi

# Removing the configuration files and directories
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/remove-config.sh" "-v" "-n" "$name" "-c" "$container_name")
else
  ("$script_dir/remove-config.sh" "-n" "$name" "-c" "$container_name" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

[ $verbose -eq $TRUE ] && echo "Uninstallation done."
