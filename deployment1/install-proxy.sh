#!/bin/sh

usage() {
  printf "install-proxy [-c|--client] <client name> [-i|--ips] <ips>\n"
  printf "\n"
  printf "Ejecuta la configuración final utilizando los datos del cliente e inicia el servidor Squid.\n"
  printf "Los datos del cliente son su nombre, las direcciones IP desde las que se conectará al\n"
  printf "servidor, su usuario y su contraseña. De estos, el nombre del cliente y sus direcciones IP\n"
  printf "son parámetos obligatorios y el usuario y la contraseña son opcionales. Si el usuario o\n"
  printf "la contraseña no son proporcionados, se generarán automáticamente.\n"
  printf "Otros parámetros opcionales son el número del puerto, la zona horaria para el servidor Squid,\n"
  printf "la etiqueta de la imagen de docker de Squid a utilizar, un nombre para el contenedor de\n"
  printf "docker a crear y si se desea desplegar el contenedor en MicroK8s.\n"
  printf "Si número del puerto no es proporcionado, se tomará el valor 3128 como predeterminado.\n"
  printf "Si la zona horaria no es proporcionada, se utilizará el valor actual del host.\n"
  printf "Si la etiqueta de la imagen de docker de Squid no es proporcionada, se utilizará\n"
  printf "ubuntu/squid:5.2-22.04_beta como valor predeterminado.\n"
  printf "Si se indica desplegar el contenedor en MicroK8s, se importará la imagen en esta plataforma\n"
  printf "y a partir de esta se desplegará el contenedor y se creará un servicio para establecer la\n"
  printf "comunicación. De lo contrario, se ejecutará un contenedor en docker que será\n"
  printf "nombrado con el nombre de contenedor proporcionado. Si no se proporciona, se tomará\n"
  printf "ubuntu-squid como valor predeterminado. Debe asegurarse que el nombre de contenedor\n"
  printf "proporcionado coincida con el nombre de su directorio correspondiente en el contexto\n"
  printf "de los scripts de instalación. Cada contenedor a desplegar debe disponer de un directorio\n"
  printf "en el contexto de los scripts de instalación que contenga sus archivos de configuración.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -i --ips\t\tDirecciones IP del cliente, separadas por comas (obligatorio).\n"
  printf "  -u --username\t\tNombre de usuario del cliente (opcional).\n"
  printf "  -p --password\t\tContraseña del cliente (opcional).\n"
  printf "  -z --timezone\t\tZona horaria para Squid (opcional).\n"
  printf "  -t --image-tag\t\tEtiqueta de la imagen docker de Squid (opcional).\n"
  printf "  -o --port\t\tNúmero del puerto (opcional).\n"
  printf "  -n --container-name\t\tNombre del contenedor docker de Squid a crear y ejecutar (opcional).\n"
  printf "  -k --microk8s\t\tIndica si se despliega el contenedor en MicroK8s (opcional).\n"
  printf "  -v --verbose\t\tExplica los pasos que se están ejecutando con más detalles.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0
NONE="None"

microk8s=$FALSE
verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--client) client="$2" shift ;;
    -i|--ips) ips="$2" shift ;;
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -z|--timezone) timezone="$2" shift ;;
    -t|--image-tag) image_tag="$2" shift ;;
    -o|--port) port="$2" shift ;;
    -n|--container-name) container_name="$2" shift ;;
    -k|--microk8s) microk8s=$TRUE ;;
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
  if [ -z "$ips" ]; then ips="$(grep --color=never -Po "^ips=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$username" ]; then username="$(grep --color=never -Po "^username=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$password" ]; then password="$(grep --color=never -Po "^password=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$timezone" ]; then timezone="$(grep --color=never -Po "^timezone=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$image_tag" ]; then image_tag="$(grep --color=never -Po "^image_tag=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$port" ]; then port="$(grep --color=never -Po "^port=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$container_name" ]; then container_name="$(grep --color=never -Po "^container_name=\K.*" $defaults_file_path || true)"; fi
  microk8s="$(grep --color=never -Po "^microk8s=\K.*" $defaults_file_path || true)";
fi 

[ -z "$client" ] && usage
[ -z "$ips" ] && usage
[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$timezone" ] && timezone=$(cat /etc/timezone)
[ -z "$image_tag" ] && image_tag="ubuntu/squid:5.2-22.04_beta"
[ -z "$port" ] && port="3128"
[ -z "$container_name" ] && container_name="ubuntu-squid"

# Ensure a valid value for client name
client=$(echo "$client" | tr -d -c [:alnum:]) #  | tr '[a-z]' '[A-Z]')

# Container files and directories
cont_conf_file="/etc/squid/squid.conf"
cont_snippets_dir="/etc/squid/conf.d"
cont_logs_dir="/var/log/squid"
cont_cache_dir="/var/spool/squid"
# Snippets file path
snippets_file_path="$script_dir/$container_name/conf.d/snippets.conf"
# MicroK8s deployment file path
deploy_file_path=$NONE

echo "Creating the configuration files and directories ... "

# Creating the configuration files and directories
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/create-config.sh" "-v" "-f" "-c" "$client" "-i" "$ips" "-n" "$container_name" "-u" "$username" "-p" "$password")
else
  ("$script_dir/create-config.sh" "-f" "-c" "$client" "-i" "$ips" "-n" "$container_name" "-u" "$username" "-p" "$password" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

echo "... Done."

# Check deployment type
if [ $microk8s -eq $FALSE ]; then
  # Deploying on docker
  echo -n "Starting the container ... "

  # Host files and directories
  host_conf_file="/etc/squid/$client/squid.conf"
  host_snippets_dir="/etc/squid/$client/conf.d"
  host_logs_dir="/var/squid/$client/logs"
  host_cache_dir="/var/squid/$client/cache"

  # Creating the squid container
  if [ $verbose -eq $TRUE ]; then
    echo ""
    docker run -d --name "$container_name" -p "$port:3128" -e TZ="$timezone" -v "$host_snippets_dir:$cont_snippets_dir:ro" -v "$host_logs_dir:$cont_logs_dir" -v "$host_cache_dir:$cont_cache_dir" -v "$host_conf_file:$cont_conf_file:ro" "$image_tag"
    echo -n "... "
  else
    docker run -d --name "$container_name" -p "$port:3128" -e TZ="$timezone" -v "$host_snippets_dir:$cont_snippets_dir:ro" -v "$host_logs_dir:$cont_logs_dir" -v "$host_cache_dir:$cont_cache_dir" -v "$host_conf_file:$cont_conf_file:ro" "$image_tag" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error deploying the proxy on Docker."
    return 1
  fi

  echo "Done."
  echo "The proxy is running at localhost:3128."
else
  # Deploying on MicroK8s
  echo -n "Creating MicroK8s resources ... "

  # Creating the tag for importing to Microk8s register 
  # First, remove username from image tag and then, prefix the Microk8s register address
  reg_tag="localhost:32000/$container_name:$(echo "$image_tag" | awk -F '/' '{print $2}' | awk -F ':' '{print $2}')"

  # Get a random id for deployment file name
  id="$(echo $(date +%s%N) | sha256sum | head -c 10)"
  
  # Deployment files path
  deploy_template_path="$script_dir/k8s-deployment.template.yaml"
  deploy_file_path="$script_dir/microk8s/k8s-deployment_$id.yaml"

  # sed script command for variables substitution
  sed_cmd='s|${CLIENT_NAME}|'"$client"'|g;s|${CONTAINER_NAME}|'"$container_name"'|g;s|${IMAGE_TAG}|'"$reg_tag"'|g;s|${PORT}|'"$port"'|g'
  # Preparing deployment file
  sed "-e" "$sed_cmd" "$deploy_template_path" > "$deploy_file_path"

  if [ $verbose -eq $TRUE ]; then
    echo ""
    docker image tag "$image_tag" "$reg_tag"
    # Importing new tag to MicroK8s register 
    if [ $? -eq 0 ]; then docker push "$reg_tag"; fi
    # Apply deployment file on MicroK8s
    if [ $? -eq 0 ]; then microk8s kubectl create -f "$deploy_file_path"; fi
    echo -n "... "
  else
    docker image tag "$image_tag" "$reg_tag" > /dev/null 2>&1
    # Importing new tag to Microk8s register 
    if [ $? -eq 0 ]; then docker push "$reg_tag" > /dev/null 2>&1; fi
    # Apply deployment file on MicroK8s
    if [ $? -eq 0 ]; then microk8s kubectl create -f "$deploy_file_path" > /dev/null 2>&1; fi
  fi

  if [ $? -gt 0 ]; then
    echo "Error deploying the proxy on MicroK8s."
    return 1
  fi

  echo "Done."
  echo "The proxy has been deployed on MicroK8s."
fi

# Storing the deployment in installs file. When deploy_file_path value equals NONE, the deployment
# was on Docker, otherway, on MicroK8s
echo "$client=$deploy_file_path" >> "$script_dir/installs"

echo "Installation done."

