#!/bin/sh

usage() {
  printf "install-docker [-u|--user] <usuario>\n"
  printf "\n"
  printf "Ejecuta todos los comandos para instalar Docker. Si no se proporciona un usuario se\n"
  printf "utilizará el usuario actual. Si no se desea adicionar ningún usuario, se debe utilizar\n"
  printf "la opción -n o --no-user. En este caso se ignorará el usuario, aún si es proporcionado.\n"
  printf "Antes de instalar Docker se actualiza el sistema de manera predeterminada. Si no se\n"
  printf "desea chequear por actualizaciones puede utilizarse el comando -a o --no-apt.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -u --user\t\tNombre del usuario a adicionar al grupo de usuarios de docker (Opcional).\n"
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

echo "Comenzó la instalación de Docker."

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

# Preparar la instalación de Docker
# Instalar los paquetes de prerrequisitos que permiten a apt utilizar paquetes por HTTPS
sudo apt install apt-transport-https ca-certificates curl software-properties-common
# Adicionar al sistema la llave GPG del repositorio oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# Adicionar el repositorio de Docker a las fuentes APT
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Actualizar la lista de paquetes nuevamente para que la adición sea reconocida
sudo apt update

# Instalar Docker
sudo apt install docker-ce 

# Chequear si se desea unir el usuario al grupo de usuarios de Docker.
if [ $no_user -eq $FALSE ]; then
  # Adicionar el usuario al grupo de usuarios de Docker
  sudo usermod -aG docker "$user" 
  # # Reloguear la consola para que tome los cambios
  # su - "$user" 
fi

echo "Instalación de Docker finalizada."
