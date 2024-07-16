
import subprocess
import shlex
import argparse

from os.path import dirname, join

scripts_dir = join(dirname(dirname(__file__)), "deployment")

install_script = join(scripts_dir, 'install.sh')
uninstall_script = join(scripts_dir, 'uninstall.sh')

def install_server(sudo_password: str, name: str, hostname: str, namespace: str, port: int, protocol: str, appversion: str):
    print("install_server() !!!")
    cmd = "sudo -Si {scriptpath} -n {name} -o {hostname} -s {namespace} -p {port:d} -t {protocol} -a {appversion}"
    cmd = cmd.format(
        scriptpath=install_script,
        name=name,
        hostname=hostname, 
        namespace=namespace, 
        port=port, 
        protocol=protocol, 
        appversion=appversion
    )
    print(cmd)
    result = subprocess.run(['echo', sudo_password], stdout=subprocess.PIPE, text=True)
    print("Password: {0}".format(result.stdout))
    result = subprocess.run(shlex.split(cmd), input=result.stdout, capture_output=True, text=True)
    print("returncode: {0}".format(result.returncode))
    print("stdout: {0}".format(result.stdout))
    print("stderr: {0}".format(result.stderr))

def uninstall_server(sudo_password: str, name: str):
    print("uninstall_server() !!!")
    cmd = "sudo -Si {scriptpath} -n {name}"
    cmd = cmd.format(
        scriptpath=uninstall_script,
        name=name
    )
    print(cmd)
    result = subprocess.run(['echo', sudo_password], stdout=subprocess.PIPE, text=True)
    print("Password: {0}".format(result.stdout))
    result = subprocess.run(shlex.split(cmd), input=result.stdout, capture_output=True, text=True)
    print("returncode: {0}".format(result.returncode))
    print("stdout: {0}".format(result.stdout))
    print("stderr: {0}".format(result.stderr))

def main ():
    parser = argparse.ArgumentParser(description="Script para instalar y desinstalar servidores VPN en Micro8s")
    parser.add_argument("operation", help="Indica la operación. Los valores son install o uninstall (Obligatorio)")
    parser.add_argument("--name", "-n", help="Nombre del servidor (Opcional)")
    parser.add_argument("--pwd", "-p", help="Contraseña de sudo (Opcional)")

    args = parser.parse_args()

    operation = args.operation
    name = args.name if args.name else 'example'
    pwd = args.pwd if args.pwd else 'javier'
    
    print(f"Operación: {operation}")
    print(f"Nombre del servidor: {name}")
    print(f"Contraseña para sudo: {pwd}")

    if operation == "install":
        install_server(pwd, f"{name}", f"vpn.{name}.com", f"{name}", 1194, "tcp", "latest")
    elif operation == "uninstall":
        uninstall_server(pwd, f"{name}")
    else:
        print("Unknown operation. Accepted values are: install or uninstall")

if __name__ == "__main__":
    main()
