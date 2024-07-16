#!/bin/sh

usage() {
  printf "restart-proxy [-n|--name] <server name>\n"
  printf " \n"
  printf " Reinicia el servidor proxy con el nombre proporcionado.\n"
  printf " \n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0
NONE="None"

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) name="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$name" ] && usage

script_dir="$(dirname "$(readlink -f "$0")")"
installs_file_path="$script_dir/installs"
servers_file_path="/etc/squid/servers"
 
# Getting the container name from servers file.
if ! [ -e ${servers_file_path} ]; then
  echo "Error: The servers file does not exist"
  return 1
fi

if ! [ -r ${servers_file_path} ]; then
  echo "Error: The servers file is not accessible"
  return 1
fi

grep_cmd="grep --color=never -Po ^$name=\K.* $servers_file_path"
container_name="$($grep_cmd)"

if [ -z "$container_name" ]; then
  echo "Error: The server has no associated container"
  return 1
fi

# Getting the deployment type from installs file
grep_cmd="grep --color=never -Po ^"$name"=\K.* "$installs_file_path""
deploy_file_path="$($grep_cmd)"

# Check deployment type
if [ "$deploy_file_path" = $NONE ]; then
  # Deployed on docker
  [ $verbose -eq $TRUE ] && echo "Restarting the docker container ... "

  # Restarting the container
  if [ $verbose -eq $TRUE ]; then
    docker restart "$container_name"
  else
    docker restart "$container_name" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Warning: The container was not restarted. You must restarted it manually."
  else
    [ $verbose -eq $TRUE ] && echo "... The container was restarted."
  fi
else
  # Deployed on MicroK8s
  [ $verbose -eq $TRUE ] && echo "Restarting MicroK8s deployment ... "

  # Restarting pods with a rollout
  if [ $verbose -eq $TRUE ]; then
    microk8s kubectl rollout restart -n "$name" "deployment.apps/${name}-${container_name}-deploy"
  else
    microk8s kubectl rollout restart -n "$name" "deployment.apps/${name}-${container_name}-deploy" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Warning: The MicroK8s deployment was not restarted. You must restarted it manually."
  else
    [ $verbose -eq $TRUE ] && echo "... The MicroK8s deployment was restarted."
  fi
fi
