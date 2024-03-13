#!/bin/sh

usage() {
  printf "do-extra-config [-c|--client] <client name>\n"
  printf "\n"
  printf "Realiza las ooperaciones de configuración propias del contenedor, que no son\n"
  printf "comunes a otros contenedores squid.\n"
  printf "\n"
  printf " OPTIONS\n"
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
    -c|--client) client="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$client" ] && usage

data_dir="/var/squid/$client"
logs_dir="$data_dir/logs"
cache_dir="$data_dir/cache"

echo -n "Doing ubuntu-squid configuration ... "

if [ $verbose -eq $TRUE ]; then
  echo ""
  chown -v -R proxy: ${logs_dir} ${cache_dir}
  echo -n "... "
else
  chown -R proxy: ${logs_dir} ${cache_dir}
fi

echo "Done."
