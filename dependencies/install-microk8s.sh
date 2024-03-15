#!/bin/sh

usage() {
  printf "install-microk8s [-u|--user] <usuario>\n"
  printf "\n"
  printf "Ejecuta todos los comandos para instalar MicroK8s. Si no se proporciona un usuario se\n"
  printf "utilizará el usuario actual. Si no se desea adicionar ningún usuario, se debe utilizar\n"
  printf "la opción -n o --no-user. En este caso se ignorará el usuario, aún si es proporcionado.\n"
  printf "Antes de instalar MicroK8s se actualiza el sistema de manera predeterminada. Si no se\n"
  printf "desea chequear por actualizaciones puede utilizarse el comando -a o --no-apt.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -u --user\t\tNombre del usuario a adicionar al grupo de usuarios de MicroK8s (Opcional).\n"
  printf "  -n --no-user\t\tIndica que no se desea adicionar ningún usuario al grupo (Opcional).\n"
  printf "  -a --no-apt\t\tIndica que no se desea chequear por actualizaciones del sistema (Opcional).\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--user) user="$2" shift ;;
    -n|--no-user) no_user=$TRUE ;;
    -a|--no-apt) no_apt=$TRUE ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$user" ] && user="$USER"

echo "Comenzó la instalación de MicroK8s."

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

# Instalar MicroK8s.
sudo snap install microk8s --classic

# Chequear si se desea unir el usuario al grupo de usuarios de MicroK8s.
if [ $no_user -eq $FALSE ]; then
  # Adicionar el usuario al grupo de usuarios de MicroK8s
  sudo usermod -aG microk8s "$user"
  # Crear el directorio de almacenamiento en caché
  sudo mkdir -p ~/.kube
  # Configurar los permisos de acceso al directorio de almacenamiento
  sudo chown -f -R "$user" ~/.kube
  # # Reloguear la consola para que tome los cambios
  # su - "$user" 
fi

# Activar los addons de MicroK8s
# Activar el dashboard
microk8s enable dashboard
# Activar el DNS
microk8s enable dns
# Activar el registro
microk8s enable registry
# Activar el balanceador de carga
microk8s enable metallb

echo "Instalación de MicroK8s finalizada."
