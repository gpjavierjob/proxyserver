#!/bin/sh

usage() {
  printf "config-app-files [-u|--user] <usuario>\n"
  printf "\n"
  printf "Concede permisos al usuario proporcionado sobre los archivos de la aplicación.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -u --user\t\tNombre del usuario de la aplicación (Obligatorio).\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--user) user="$2" shift ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$user" ] && usage

script_path="$(readlink -f "$0")"
script_dir="$(dirname ${script_path})"
app_dir="$(dirname ${script_dir})"

echo "Configurando los permisos sobre los archivos de la aplicación ..."

sudo chown -R "$user:" "$app_dir/deployment"
sudo chmod u+x "$app_dir/deployment/alpine-squid/build-image.sh"
sudo chmod u+x "$app_dir/deployment/alpine-squid/do-extra-config.sh"
sudo chmod u+x "$app_dir/deployment/alpine-squid/undo-extra-config.sh"
sudo chmod u+x "$app_dir/deployment/ubuntu-squid/do-extra-config.sh"
sudo chmod u+x "$app_dir/deployment/ubuntu-squid/undo-extra-config.sh"
sudo chmod u+x "$app_dir/deployment/create-config.sh"
sudo chmod u+x "$app_dir/deployment/create-http-user.sh"
sudo chmod u+x "$app_dir/deployment/install-proxy.sh"
sudo chmod u+x "$app_dir/deployment/remove-config.sh"
sudo chmod u+x "$app_dir/deployment/remove-proxy.sh"

echo "... La configuración de los permisos sobre los archivos de la aplicación ha finalizado."
