from datetime import datetime
from decouple import config

from src import scheduler, db
from src.servers.bash import CommandExecuted, install_server, uninstall_server, add_client, remove_client
from src.servers.models import (Server, SERVER_STATE_CREATING, SERVER_STATE_FAILED, SERVER_STATE_EXECUTING, SERVER_STATE_REMOVING, 
                                Client, CLIENT_STATE_ADDING, CLIENT_STATE_FAILED, CLIENT_STATE_ADDED, CLIENT_STATE_REMOVING)


SERVER_ID = "SERVER_{0}"
SERVER_NAME = "{0} {1} VPN"

SERVER_OPERATION_INSTALLING = "Installing"
SERVER_OPERATION_UNINSTALLING = "Uninstalling"


def schedule_install_server_job(server):
    if server.state != SERVER_STATE_CREATING:
        return

    with scheduler.app.app_context():
        scheduler.add_job(
            SERVER_ID.format(server.id),
            install_server_job,
            name=SERVER_NAME.format(SERVER_OPERATION_INSTALLING, server.name),
            kwargs={
                "id": server.id, 
                "name": server.name, 
                "hostname": server.hostname, 
                "namespace": server.namespace, 
                "port": server.port, 
                "protocol": server.protocol, 
                "appversion": server.appversion
            },
            misfire_grace_time=None,
            max_instances=1,
            coalesce=False,
            next_run_time=datetime.now(),
            replace_existing=True,
            trigger="interval",
            seconds=300
        )

def install_server_job(id, name, hostname, namespace, port, protocol, appversion):
    with scheduler.app.app_context():
        try:
            result = install_server(config("ASYNC_JOB_USER_NAME"), name, hostname, namespace, port, 
                                    protocol, appversion, config("ASYNC_JOB_USER_PASSWORD"))
        except BaseException as e:
            result = CommandExecuted(False, str(e))

        server = Server.query.get(id)

        if server:
            if result.is_ok:
                server.state = SERVER_STATE_EXECUTING
            else:
                server.prev_state = server.state
                server.state = SERVER_STATE_FAILED
                server.errmsg = result.error_msg
            server.updated_by = "scheduler job"

            db.session.commit()

        scheduler.remove_job(SERVER_ID.format(server.id))


def schedule_uninstall_server_job(server):
    if server.state != SERVER_STATE_REMOVING:
        return

    with scheduler.app.app_context():
        scheduler.add_job(
            SERVER_ID.format(server.id),
            uninstall_server_job,
            name=SERVER_NAME.format(SERVER_OPERATION_UNINSTALLING, server.name),
            kwargs={
                "id": server.id, 
                "name": server.name, 
            },
            misfire_grace_time=None,
            max_instances=1,
            coalesce=False,
            next_run_time=datetime.now(),
            replace_existing=True,
            trigger="interval",
            seconds=300
        )


def uninstall_server_job(id, name):
    with scheduler.app.app_context():
        try:
            result = uninstall_server(config("ASYNC_JOB_USER_NAME"), name, config("ASYNC_JOB_USER_PASSWORD"))
        except BaseException as e:
            result = CommandExecuted(False, str(e))

        server = Server.query.get(id)

        if server:
            if result.is_ok:
                db.session.delete(server)
            else:
                server.state = SERVER_STATE_FAILED
                server.errmsg = result.error_msg
                server.updated_by = "scheduler job"

            db.session.commit()

        scheduler.remove_job(SERVER_ID.format(server.id))


CLIENT_ID = "CLIENT_{0}"
CLIENT_NAME = "{0} {1}"

CLIENT_OPERATION_ADDING = "Adding"
CLIENT_OPERATION_REMOVING = "Removing"


def schedule_add_client_job(client):
    if client.state != CLIENT_STATE_ADDING:
        return

    with scheduler.app.app_context():
        scheduler.add_job(
            CLIENT_ID.format(client.id),
            add_client_job,
            name=CLIENT_NAME.format(CLIENT_OPERATION_ADDING, client.name),
            kwargs={
                "id": client.id, 
                "server_name": client.server.name, 
                "client_name": client.name, 
            },
            misfire_grace_time=None,
            max_instances=1,
            coalesce=False,
            next_run_time=datetime.now(),
            replace_existing=True,
            trigger="interval",
            seconds=300
        )


def add_client_job(id, server_name, client_name):
    with scheduler.app.app_context():
        try:
            result = add_client(config("ASYNC_JOB_USER_NAME"), server_name, client_name, 
                                config("ASYNC_JOB_USER_PASSWORD"))
        except BaseException as e:
            result = CommandExecuted(False, str(e))

        client = Client.query.get(id)

        if client:
            if result.is_ok:
                client.state = CLIENT_STATE_ADDED
            else:
                client.state = CLIENT_STATE_FAILED
                client.errmsg = result.error_msg
            client.updated_by = "scheduler job"

            db.session.commit()

        scheduler.remove_job(CLIENT_ID.format(client.id))


def schedule_remove_client_job(client):
    if client.state != CLIENT_STATE_REMOVING:
        return

    with scheduler.app.app_context():
        scheduler.add_job(
            CLIENT_ID.format(client.id),
            remove_client_job,
            name=CLIENT_NAME.format(CLIENT_OPERATION_REMOVING, client.name),
            kwargs={
                "id": client.id, 
                "server_name": client.server.name, 
                "client_name": client.name, 
            },
            misfire_grace_time=None,
            max_instances=1,
            coalesce=False,
            next_run_time=datetime.now(),
            replace_existing=True,
            trigger="interval",
            seconds=300
        )


def remove_client_job(id, server_name, client_name):
    with scheduler.app.app_context():
        try:
            result = remove_client(config("ASYNC_JOB_USER_NAME"), server_name, client_name, 
                                   config("ASYNC_JOB_USER_PASSWORD"))
        except BaseException as e:
            result = CommandExecuted(False, str(e))

        client = Client.query.get(id)

        if client:
            if result.is_ok:
                db.session.delete(client)
            else:
                client.state = CLIENT_STATE_ADDED
                client.errmsg = result.error_msg
                client.updated_by = "scheduler job"

            db.session.commit()

        scheduler.remove_job(CLIENT_ID.format(client.id))
