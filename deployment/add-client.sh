#!/bin/sh

usage() {
  printf "add-client [-s|--server] <server name> [-c|--client] <client name> [-i|--ips] <ips>\n"
  printf " \n"
  printf " Permite que un cliente tenga acceso al servidor proxy desde determinadas ips.\n"
  printf " El nombre del servidor, del cliente y las direcciones ips son obligatorias.\n"
  printf " El username y el password son opcionales; si no se proporcionan, son generados\n"
  printf " automáticamente. Los valores de username y password son exportados a las\n"
  printf " variables de entorno SQUID_PROXY_USERNAME y SQUID_PROXY_PASSWORD, respectivamente.\n"
  printf " \n"
  printf " OPTIONS\n"
  printf "  -s --server\t\tNombre del servidor (obligatorio).\n"
  printf "  -c --client\t\tNombre del cliente (obligatorio).\n"
  printf "  -i --ips\t\tDirecciones IP del cliente, separadas por el caracter definido como\n"
  printf "          \t\tip-separator (obligatorio).\n"
  printf "  -u --username\t\tEl nombre de usuario del cliente (opcional).\n"
  printf "  -p --password\t\tLa contraseña del usuario del cliente (opcional).\n"
  printf "  -q --qr-string\t\tLa cadena a utilizar para generar elcódigo QR. Debe contener las\n"
  printf "                \t\tvariables username y password (opcional).\n"
  printf "  -r --ip-separator\tCaracter utilizado para separar las direcciones IP. Su valor\n"
  printf "                   \tpredeterminado será la coma (opcional).\n"
  printf "  -v --verbose\t\tExplicación detallada de los pasos que se están ejecutando.\n"
  printf "  -h --help\t\tImprime esta ayuda.\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--server) server="$2" shift ;;
    -c|--client) client="$2" shift ;;
    -i|--ips) ips="$2" shift ;;
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
    -q|--qr-string) qr_string="$2" shift ;;
    -r|--ip-separator) ip_separator="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
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
  if [ -z "$qr_string" ]; then qr_string="$(grep --color=never -Po "^qr_string=\K.*" $defaults_file_path || true)"; fi
  if [ -z "$ip_separator" ]; then ip_separator="$(grep --color=never -Po "^ip_separator=\K.*" $defaults_file_path || true)"; fi
fi 

[ -z "$server" ] && usage
[ -z "$client" ] && usage
[ -z "$ips" ] && usage
[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$qr_string" ] && usage
[ -z "$ip_separator" ] && usage

# Ensure a valid value for client name
client=$(echo "$client" | tr -d -c [:alnum:])

# Host directories names
conf_dir="/etc/squid/$server"
snippets_dir="$conf_dir/conf.d"
# File names
pass_file_name="passwords"
ips_file_name="client-ips.conf"
# Host file paths
pass_file_path="$snippets_dir/$pass_file_name"
ips_file_path="$snippets_dir/$ips_file_name"
client_file_path="$conf_dir/$client"
qr_file_path="$conf_dir/$client.png"
servers_file_path="/etc/squid/servers"

if [ -e "$client_file_path" ]; then
  echo "Error: Ya existe un cliente llamado '$client'"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "Updating http access configuration file ... "

if [ $verbose -eq $TRUE ]; then
  ("$script_dir/create-http-user.sh" "-v" "-u" "$username" "-p" "$password" "-f" "$pass_file_path")
else
  ("$script_dir/create-http-user.sh" "-u" "$username" "-p" "$password" "-f" "$pass_file_path" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... http access configuration file updated."

[ $verbose -eq $TRUE ] && echo "Updating the IPs configuration file ... "

ip_list=$(echo $ips | tr "$ip_separator" "\n")

for ip in $ip_list 
do
  echo "$ip" >> "$ips_file_path"

  if [ $? -gt 0 ]; then
    echo "Error: The IPs configuration file does not exists or it is not writable"
    return 1
  fi
done

[ $verbose -eq $TRUE ] && echo "... IPs configuration file updated."

[ $verbose -eq $TRUE ] && echo "Creating QR code file ... "

eval qrencode -o "$qr_file_path" "$qr_string"

if [ $? -gt 0 ]; then
  echo "Error: The QR code file was not created"
  return 1
fi

[ $verbose -eq $TRUE ] && echo "... QR code file created."

# Storing client parameters in client file for later client removal.
echo "username=$username" > "$client_file_path"
echo "ips=$ips" >> "$client_file_path"
echo "qr=$qr_file_path" >> "$client_file_path"

# Restarting proxy
if [ $verbose -eq $TRUE ]; then
  ("$script_dir/restart-proxy.sh" "-v" "-n" "$server")
else
  ("$script_dir/restart-proxy.sh" "-n" "$server" > /dev/null)
fi

if [ $? -gt 0 ]; then
  return 1
fi

export SQUID_PROXY_USERNAME=$username
export SQUID_PROXY_PASSWORD=$password

[ $verbose -eq $TRUE ] && echo "Client added."
