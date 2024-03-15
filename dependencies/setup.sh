#!/bin/sh

usage() {
  printf "setup [-u|--user] <usuario>\n"
  printf "\n"
  printf "Prepara el host para poder ejecutar el administrador de proxies. Instala las dependencias,\n"
  printf "crea el usuario de la aplicación y configura los permisos de acceso de este último.\n"
  printf "Como nombre del usuario de la aplicación será tomado el proporcionado. En caso de no\n"
  printf "indicarse ninguno, se tomará 'proxyman' como valor predeterminado.\n"
  printf "\n"
  printf " OPTIONS\n"
  printf "  -u --user\t\tNombre del usuario de la aplicación (Opcional).\n"
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

[ -z "$user" ] && user="proxyman"

script_path="$(readlink -f "$0")"
script_dir="$(dirname ${script_path})"

echo "Configurando el administrador de proxies ..."

# Crear el usuario de la aplicación si aún no existe
id "$user" > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  useradd -U -u 313 -r -M -d /bin -s /usr/sbin/nologin -c "$user" "$user"
fi

# Establecer los permisos de ejecución de los scripts de instalación
sudo chmod u+x "$script_dir/install-docker.sh"
sudo chmod u+x "$script_dir/install-microk8s.sh"
sudo chmod u+x "$script_dir/install-apache-utils.sh"
sudo chmod u+x "$script_dir/config-app-files.sh"

# Instalar Docker
("$script_dir/install-docker.sh" "-u" "$user")

# Instalar MicroK8s
("$script_dir/install-microk8s.sh" "-u" "$user" --no-apt)

# Instalar las utilidades de Apache
("$script_dir/install-apache-utils.sh" --no-apt)

# Configurar los permisos de los archivos de la aplicación
("$script_dir/config-app-files.sh")

echo "... La configuración del administrador de proxies ha finalizado."
