#!/bin/sh

usage() {
  printf "do-extra-config [-n|--name] <name>\n"
  printf "\n"
  printf "Realiza las ooperaciones de configuración propias del contenedor, que no son\n"
  printf "comunes a otros contenedores squid.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -n --name\t\tNombre del servidor (obligatorio).\n"
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
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$name" ] && usage

data_dir="/var/squid/$name"
logs_dir="$data_dir/logs"
cache_dir="$data_dir/cache"

[ $verbose -eq $TRUE ] && echo "Doing alpine-squid configuration ... "

id squid > /dev/null 2>&1

# Crear el usuario squid si aún no existe
if [ $? -ne 0 ]; then 
  useradd -U -u 31 -r -M -d /bin -s /usr/sbin/nologin -c squid squid
fi

if [ $verbose -eq $TRUE ]; then
  chown -v -R squid: ${logs_dir} ${cache_dir}
else
  chown -R squid: ${logs_dir} ${cache_dir}
fi

if [ $? -gt 0 ]; then
  echo "Error: The extra configuration can not be done."
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... alpine-squid configuration done."
