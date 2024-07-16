#!/bin/sh

usage() {
  printf "install-proxy [-n|--name] <server name>\n"
  printf "\n"
  printf "Configura e inicia un servidor Squid. El nombre del servidor es obligatorio.\n"
  printf "Otros parámetros opcionales son el número del puerto, la zona horaria para el servidor Squid,\n"
  printf "la etiqueta de la imagen docker de Squid a utilizar, el nombre para el contenedor docker\n"
  printf "de Squid a crear, si se desea desplegar el contenedor en MicroK8s y la cantidad de réplicas.\n"
  printf "Si número del puerto no es proporcionado, se tomará el valor 3128 como predeterminado.\n"
  printf "Si la zona horaria no es proporcionada, se utilizará el valor actual del host.\n"
  printf "Si la etiqueta de la imagen de docker de Squid no es proporcionada, se utilizará\n"
  printf "ubuntu/squid:5.2-22.04_beta como valor predeterminado.\n"
  printf "Si se indica desplegar el contenedor en MicroK8s, se importará la imagen en esta plataforma\n"
  printf "y a partir de esta se desplegará el contenedor y se creará un servicio para establecer la\n"
  printf "comunicación. De lo contrario, se ejecutará un contenedor en docker que será\n"
  printf "nombrado utilizando el nombre de contenedor proporcionado. Si no se proporciona, se tomará\n"
  printf "ubuntu-squid como valor predeterminado. Debe asegurarse que el nombre de contenedor\n"
  printf "proporcionado coincida con el nombre de su directorio correspondiente en el contexto\n"
  printf "de los scripts de instalación. Cada contenedor a desplegar debe disponer de un directorio\n"
  printf "en el contexto de los scripts de instalación que contenga sus archivos de configuración.\n"
  printf "Si no se proporciona la cantidad de réplicas, se tomará el valor 2 como predeterminado. La\n"
  printf "cantidad de réplicas solo tiene sentido si se despliega el contenedor en MicroK8s.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
  printf "  -z --timezone\t\tZona horaria para Squid (opcional).\n"
  printf "  -t --image-tag\t\tEtiqueta de la imagen docker de Squid (opcional).\n"
  printf "  -o --port\t\tNúmero del puerto (opcional).\n"
  printf "  -c --container-name\tNombre del contenedor docker de Squid a crear y ejecutar (opcional).\n"
  printf "  -k --microk8s\t\tIndica si se despliega el contenedor en MicroK8s (opcional).\n"
  printf "  -r --replicas\t\tIndica la cantidad de pods que se desea desplegar en MicroK8s (opcional).\n"
  printf "  -v --verbose\t\tExplica los pasos que se están ejecutando con más detalles.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0
NONE="None"
PENDING="pending"

microk8s=$FALSE
verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) name="$2" shift ;;
    -z|--timezone) timezone="$2" shift ;;
    -t|--image-tag) image_tag="$2" shift ;;
    -o|--port) port="$2" shift ;;
    -c|--container-name) container_name="$2" shift ;;
    -k|--microk8s) microk8s=$TRUE ;;
    -r|--replicas) replicas="$2" ;;
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
  if [ -z "$name" ]; then name="$(grep --color=never -Po "^name=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$timezone" ]; then timezone="$(grep --color=never -Po "^timezone=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$image_tag" ]; then image_tag="$(grep --color=never -Po "^image_tag=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$port" ]; then port="$(grep --color=never -Po "^port=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$container_name" ]; then container_name="$(grep --color=never -Po "^container_name=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$replicas" ]; then replicas="$(grep --color=never -Po "^replicas=\K.*" $defaults_file_path || true)"; fi
  microk8s="$(grep --color=never -Po "^microk8s=\K.*" $defaults_file_path || true)";
fi 

[ -z "$name" ] && usage
[ -z "$timezone" ] && timezone=$(cat /etc/timezone)
[ -z "$image_tag" ] && image_tag="ubuntu/squid:5.2-22.04_beta"
[ -z "$port" ] && port="3128"
[ -z "$container_name" ] && container_name="ubuntu-squid"
[ -z "$replicas" ] && replicas="2"

# Ensure a valid value for server name
name=$(echo "$name" | tr -d -c [:alnum:])

if [ $verbose -eq $TRUE ]; then
  echo "-------------------------------";
  echo "NAME........... $name";
  echo "CONTAINER_NAME. $container_name";
  echo "TIMEZONE....... $timezone";
  echo "IMAGE_TAG...... $image_tag";
  echo "PORT........... $port";
  echo "-------------------------------";
fi

# Container files and directories
cont_conf_file="/etc/squid/squid.conf"
cont_snippets_dir="/etc/squid/conf.d"
cont_logs_dir="/var/log/squid"
cont_cache_dir="/var/spool/squid"
# Snippets file path
snippets_file_path="$script_dir/$container_name/conf.d/snippets.conf"
# Installations file
installs_path="$script_dir/installs"
# MicroK8s deployment file path
deploy_file_path=$NONE

# Checking for a previous installation
# Getting the deployment type from installs file
grep_cmd="grep --color=never -Po ^"$name"=\K.* "$installs_path""
deploy_file_path="$($grep_cmd)"

if [ -n "$deploy_file_path" ]; then
  echo "Error: There is a previous installation for a server named $name."
  return 1
fi

# Initializing installs file. Setting deploy_file_path value to PENDING
echo "$name=$PENDING" >> "$installs_path"

if [ $? -gt 0 ]; then
  echo "Error: Imposible to update installs file."
  return 1
fi

[ $verbose -eq $TRUE ] && echo "Creating the configuration files and directories ... "

# Creating the configuration files and directories
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/create-config.sh" "-v" "-f" "-n" "$name" "-c" "$container_name")
else
  ("$script_dir/create-config.sh" "-f" "-n" "$name" "-c" "$container_name" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... configuration files and directories created."

# Check deployment type
if [ $microk8s -eq $FALSE ]; then
  # Deploying on docker
  [ $verbose -eq $TRUE ] && echo "Starting the container ... "

  # Host files and directories
  host_conf_file="/etc/squid/$name/squid.conf"
  host_snippets_dir="/etc/squid/$name/conf.d"
  host_logs_dir="/var/squid/$name/logs"
  host_cache_dir="/var/squid/$name/cache"

  # Updating the deployment type in installs file. When deploy_file_path value equals NONE, 
  # the deployment was on Docker
  sed_param="s/${name}=.*/${name}=${NONE}/" 
  sed -i "$sed_param" "$installs_path"

  if [ $? -gt 0 ]; then
    echo "Error: Imposible to update installs file."
    return 1
  fi

  # Creating the squid container
  if [ $verbose -eq $TRUE ]; then
    docker run -d --name "$container_name" -p "$port:3128" -e TZ="$timezone" -v "$host_snippets_dir:$cont_snippets_dir:ro" -v "$host_logs_dir:$cont_logs_dir" -v "$host_cache_dir:$cont_cache_dir" -v "$host_conf_file:$cont_conf_file:ro" "$image_tag"
  else
    docker run -d --name "$container_name" -p "$port:3128" -e TZ="$timezone" -v "$host_snippets_dir:$cont_snippets_dir:ro" -v "$host_logs_dir:$cont_logs_dir" -v "$host_cache_dir:$cont_cache_dir" -v "$host_conf_file:$cont_conf_file:ro" "$image_tag" > /dev/null
  fi

  if [ $? -gt 0 ]; then
    echo "Error: The proxy failed to deploy on Docker."
    return 1
  fi

  if [ $verbose -eq $TRUE ]; then
    echo "... container started. The proxy is running at localhost:3128."
  fi
else
  # Deploying on MicroK8s
  [ $verbose -eq $TRUE ] && echo "Creating MicroK8s resources ... "

  # Get a random id for deployment file name
  id="$(echo $(date +%s%N) | sha256sum | head -c 10)"
  
  # Deployment files path
  deploy_template_path="$script_dir/k8s-deployment.template.yaml"
  deploy_file_path="$script_dir/microk8s/k8s-deployment_$id.yaml"

  # Updating the deployment type in installs file. When deploy_file_path value is not equals to 
  # NONE or PENDING, the deployment was on MicroK8s (Used # as separator, intead of /)
  sed_param="s#${name}=.*#${name}=${deploy_file_path}#"
  sed -i "${sed_param}" "${installs_path}"

  if [ $? -gt 0 ]; then
    echo "Error: Imposible to update installs file."
    return 1
  fi

  # Creating the tag for importing to Microk8s register 
  # First, remove username from image tag and then, prefix the Microk8s register address
  reg_tag="localhost:32000/$container_name:$(echo "$image_tag" | awk -F '/' '{print $2}' | awk -F ':' '{print $2}')"

  # sed script command for variables substitution
  sed_param='s|${REPLICAS}|'"$replicas"'|g;s|${SERVER_NAME}|'"$name"'|g;s|${CONTAINER_NAME}|'"$container_name"'|g;s|${IMAGE_TAG}|'"$reg_tag"'|g;s|${PORT}|'"$port"'|g'
  # Preparing deployment file
  sed "-e" "$sed_param" "$deploy_template_path" > "$deploy_file_path"

  if [ $? -gt 0 ]; then
    echo "Error: Imposible to generate the MicroK8s deployment file."
    return 1
  fi

  if [ $verbose -eq $TRUE ]; then
    docker image tag "$image_tag" "$reg_tag"
    # Importing new tag to MicroK8s register 
    if [ $? -eq 0 ]; then docker push "$reg_tag"; fi
    # Creating the namespace 
    if [ $? -eq 0 ]; then microk8s kubectl create namespace "$name"; fi
    # Apply deployment file on MicroK8s
    if [ $? -eq 0 ]; then microk8s kubectl create -f "$deploy_file_path" --namespace="$name"; fi
  else
    docker image tag "$image_tag" "$reg_tag" > /dev/null
    # Importing new tag to Microk8s register 
    if [ $? -eq 0 ]; then docker push "$reg_tag" > /dev/null; fi
    # Creating the namespace 
    if [ $? -eq 0 ]; then microk8s kubectl create namespace "$name" > /dev/null; fi
    # Apply deployment file on MicroK8s
    if [ $? -eq 0 ]; then microk8s kubectl create -f "$deploy_file_path" --namespace="$name" > /dev/null; fi
  fi

  if [ $? -gt 0 ]; then
    echo "Error: The proxy failed to deploy on MicroK8s."
    return 1
  fi

  if [ $verbose -eq $TRUE ]; then
    echo "... MicroK8s resources created. The proxy has been deployed on MicroK8s."
  fi
fi

[ $verbose -eq $TRUE ] && echo "Installation done."
