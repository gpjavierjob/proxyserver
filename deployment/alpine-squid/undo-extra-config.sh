#!/bin/sh

usage() {
  printf "undo-extra-config [-n|--name] <name>\n"
  printf "\n"
  printf "Deshace las ooperaciones de configuración propias del contenedor, que no son\n"
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

[ $verbose -eq $TRUE ] && echo "Undoing alpine-squid configuration ... "

# Write your code here

[ $verbose -eq $TRUE ] && echo "... alpine-squid configuration undone."
