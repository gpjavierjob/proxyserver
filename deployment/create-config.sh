#!/bin/sh

usage() {
  printf "create-links [-c|--client] <client name> [-i|--ips] <ips>\n"
  printf " OPTIONS\n"
  printf "  -c --client\t\tthe name of the client (required)\n"
  printf "  -i --ips\t\tip addresses of the client, separated by semicolons (required)\n"
  printf "  -u --username\t\tthe username of the client (optional)\n"
  printf "  -p --password\t\tpassword for the new http user (optional)\n"
  printf "  -h --help\t\tprint this help\n"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--client) client="$2" shift ;;
    -i|--ips) ips="$2" shift ;;
    -u|--username) username="$2" shift ;;
    -p|--password) password="$2" shift ;;
        -h|--help) usage ;;
                *) usage ;;
  esac
  shift
done

[ -z "$client" ] && usage
[ -z "$ips" ] && usage
[ -z "$username" ] && username=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')
[ -z "$password" ] && password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9')

# client=$("$client" | tr -dc 'a-zA-Z0-9')

# echo "$client"

echo -n "Creating the client directories on the host ..."

# Directories names
snippets_dir="/home/javier/prueba/etc/squid/$client/conf.d/"
logs_dir="/home/javier/prueba/var/squid/$client/logs/"  
cache_dir="/home/javier/prueba/var/squid/$client/cache/"
# snippets_dir="/etc/squid/$client/conf.d/"
# logs_dir="/var/squid/$client/logs/"  
# cache_dir="/var/squid/$client/cache/"
# File names
pass_file_name="passwords"
ips_file_name="client-ips.conf"
# File paths
snippets_file_path="./files/squid-docker.conf"
pass_file_path="$snippets_dir$pass_file_name"
ips_file_path="$snippets_dir$ips_file_name"

mkdir -p ${snippets_dir}
mkdir -p ${logs_dir}
mkdir -p ${cache_dir}

echo " done."

echo -n "Copying the snippets configuration file ..."

cp "$snippets_file_path" "$snippets_dir" > /dev/null

echo " done."

echo -n "Generating http access configuration file ..."

./create-http-user.sh "-u" "$username" "-p" "$password" "-f" "$pass_file_path" > /dev/null

echo " done."

echo -n "Generating the IPs configuration file ..."

touch "$ips_file_path"

ip_list=$(echo $ips | tr "," "\n")

for ip in $ip_list 
do
    echo "$ip" >> "$ips_file_path"
done

echo " done."

echo "All done."