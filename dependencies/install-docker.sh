#!/bin/sh

usage() {
  printf "install-docker [-u|--user] <usuario>\n"
  printf "\n"
  printf "Ejecuta todos los comandos para instalar Docker. Si no se proporciona un usuario se\n"
  printf "utilizará el usuario actual. Si no se desea adicionar ningún usuario, se debe utilizar\n"
  printf "la opción -n o --no-user. En este caso se ignorará el usuario, aún si es proporcionado.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -u --user\t\tNombre del usuario a adicionar al grupo de usuarios de docker (Opcional).\n"
  printf "  -n --no-user\t\tIndica que no se desea adicionar ningún usuario al grupo (Opcional).\n"
  printf "  -v --verbose\t\tExplica los pasos que se están ejecutando con más detalles.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--user) user="$2" shift ;;
    -n|--no-user) no_user=$TRUE ;;
    -v|--verbose) verbose=$TRUE ;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$user" ] && user="$USER"

# Actualizar Ubuntu.
# Obtener la lista de las actualizaciones disponibles:
sudo apt update
# Instalar algunas actualizaciones (no remueve los paquetes):
sudo apt upgrade
# Instalar las actualizaciones (puede remover algunos paquetes de ser necesario):
sudo apt full-upgrade
# Eliminar todos los paquetes viejos que ya no son necesarios:
sudo apt autoremove

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

# Unirse al grupo de usuarios.
if [ $no_user -eq $FALSE ]; then
  # Adicionar el usuario al grupo de usuarios de Docker
  sudo usermod -aG docker "$user" 
  # Reloguear la consola para que tome los cambios
  su - "$user" 
fi

echo "Instalación finalizada."
