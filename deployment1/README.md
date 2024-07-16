Los parámetros de entrada son:

    Nombre del cliente
    IPs del cliente

Se crea los directorios:

    /etc/squid/${CLIENT_NAME}/
    /var/squid/${CLIENT_NAME}/

Donde CLIENT_NAME es el nombre del cliente proporcionado.

En el directorio /etc/squid/${CLIENT_NAME}/ se almacenan los siguientes archivos:

    conf.d/client_ips.conf : Es el archivo donde se almacenan las IPs del cliente, una por línea.
    conf.d/passwords : Es el archivo donde se almacenan los pares usuario/contraseña del cliente.

y en el directorio /var/squid/${CLIENT_NAME}/ se crean los directorios:

    logs : Donde se almacenarán los archivos de logs.
    cache : Donde se almacenarán los datos de la cache.

Para estos archivos y directorios se crearán los siguientes volúmenes:

    /etc/squid/${CLIENT_NAME}/conf.d:/etc/squid/conf.d
    /var/squid/${CLIENT_NAME}/logs:/var/log/squid
    /var/squid/${CLIENT_NAME}/cache:/var/spool/squid

Para ejecutar el contenedor:

```shell
 docker run -d --name jgp-squid -p 3128:3128 -e TZ=${TIME_ZONE} -v /etc/squid/${CLIENT_NAME}/conf.d:/etc/squid/conf.d -v /var/squid/${CLIENT_NAME}/logs:/var/log/squid -v /var/squid/${CLIENT_NAME}/cache:/var/spool/squid gpjavierjob/alpine-squid:6.6
```
