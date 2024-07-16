import subprocess
import shlex
import types
from os.path import dirname, join

scripts_dir = join(dirname(dirname(dirname(dirname(__file__)))), "deployment")

install_script = join(scripts_dir, 'install.sh')
add_client_script = join(scripts_dir, 'add-client.sh')
remove_client_script = join(scripts_dir, 'remove-client.sh')
uninstall_script = join(scripts_dir, 'uninstall.sh')


class CommandExecuted(object):
    """A command that has been executed.

    Is returned by every function.

    Attributes:
      is_ok:        Indicates success.
      error_msg:    The error message if execution fails.
    """
    def __init__(self, is_ok: bool, error_msg: str=None):
        self.is_ok = is_ok
        self.error_msg = error_msg

    def __repr__(self):
        args = ['is_ok={!r}'.format(self.is_ok)]
        if self.error_msg is not None:
            args.append('error_msg={!r}'.format(self.error_msg))
        return "{}({})".format(type(self).__name__, ', '.join(args))

    __class_getitem__ = classmethod(types.GenericAlias)


def _execute_command(user_password: str, cmd: str, user_name: str=None):
    # Print the sudo password to a text-formated output PIPE
    result = subprocess.run(['echo', user_password], stdout=subprocess.PIPE, text=True)
    # Use the previous text-formated output PIPE as input text in command running
    user = user_name if user_name else None
    result = subprocess.run(shlex.split(cmd), input=result.stdout, capture_output=True, text=True,
                            user=user)
    
    return CommandExecuted(result.returncode == 0, result.stderr)

def install_server(user_password: str, name: str, hostname: str, namespace: str, port: int, 
                   protocol: str, appversion: str, user_name=None):
    # Build command
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
    return _execute_command(user_password, cmd, user_name)


def uninstall_server(user_password: str, name: str, user_name=None):
    # Build command
    cmd = "sudo -Si {scriptpath} -n {name}"
    cmd = cmd.format(
        scriptpath=uninstall_script,
        name=name
    )
    return _execute_command(user_password, cmd, user_name)


def add_client(user_password: str, server_name: str, client_name: str, user_name=None):
    # Build command
    cmd = "sudo -Si {scriptpath} -n {server_name} -c {client_name}"
    cmd = cmd.format(
        scriptpath=add_client_script,
        server_name=server_name,
        client_name=client_name
    )
    return _execute_command(user_password, cmd, user_name)


def remove_client(user_password: str, server_name: str, client_name: str, user_name=None):
    # Build command
    cmd = "sudo -Si {scriptpath} -n {server_name} -c {client_name}"
    cmd = cmd.format(
        scriptpath=remove_client_script,
        server_name=server_name,
        client_name=client_name
    )
    return _execute_command(user_password, cmd, user_name)
