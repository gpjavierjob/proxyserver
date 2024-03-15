#!/bin/sh

usage() {
  printf "install-apache-utils\n"
  printf "\n"
  printf "Instala las utilidades de Apache.\n"
  printf "Antes de instalar las utilidades de Apache se actualiza el sistema de manera\n"
  printf "predeterminada. Si no se desea chequear por actualizaciones puede utilizarse\n"
  printf "el comando -a o --no-apt.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -a --no-apt\t\tIndica que no se desea chequear por actualizaciones del sistema (Opcional).\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--no-apt) no_apt=$TRUE ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

echo "Comenzó la instalación de las utilidades de Apache."

# Chequear si se desea actualizar Ubuntu.
if [ $no_apt -eq $FALSE ]; then
  # Actualizar Ubuntu.
  # Obtener la lista de las actualizaciones disponibles:
  sudo apt update
  # Instalar algunas actualizaciones (no remueve los paquetes):
  sudo apt upgrade
  # Instalar las actualizaciones (puede remover algunos paquetes de ser necesario):
  sudo apt full-upgrade
  # Eliminar todos los paquetes viejos que ya no son necesarios:
  sudo apt autoremove
fi

# Instalar las utilizades de Apache
sudo apt install apache2-utils -y

echo "Instalación de las utilidades de Apache finalizada."
