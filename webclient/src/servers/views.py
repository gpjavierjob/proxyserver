from flask import Blueprint, flash, redirect, render_template, request, url_for
from flask_login import login_required

from src import db
from src.core.widgets import (ListWidgetContext, RetrieveWidgetContext, UpdateWidgetContext, 
                              CreateWidgetContext)
from src.servers.models import (Server, SERVER_STATE_CREATING, SERVER_STATE_FAILED, 
                                SERVER_STATE_REMOVING, SERVER_STATE_EXECUTING,
                                Client, CLIENT_STATE_ADDING, CLIENT_STATE_REMOVING,
                                CLIENT_STATE_FAILED)
from src.servers.scheduler import (schedule_install_server_job, schedule_uninstall_server_job,
                                   schedule_add_client_job, schedule_remove_client_job)
from src.servers.forms import (ServerForm, SERVER_PROTOCOL_CHOICES, SERVER_STATE_CHOICES, 
                               ClientForm, CLIENT_STATE_CHOICES)

servers_bp = Blueprint(
    "servers", __name__, template_folder='templates', static_folder='static', url_prefix='/servers/')

# ------- 
# Servers
# -------

server_list_fields = ["name", "namespace", "hostname", "protocol", "port", "appversion", "state"]
server_retrieve_fields = ["id", "name", "namespace", "hostname", "protocol", "port", "appversion", "state", "prev_state"]
server_update_fields = ["id", "name", "namespace", "hostname", "protocol", "port", "appversion"]
server_create_fields = ["name", "namespace", "hostname", "protocol", "port", "appversion"]


@servers_bp.route("/", methods=["GET"])
@login_required
def list_servers():
    servers = Server.query.all()
    context = ListWidgetContext(
        title="Servers", 
        model_name="Server",
        form=ServerForm(), 
        fields=server_list_fields, 
        objs=servers, 
        create_button_title="Add a server", 
        create_url_endpoint="servers.create_server", 
        create_url_values=None, 
        retrieve_url_endpoint="servers.retrieve_server", 
        retrieve_url_values=None, 
        delete_button_title="Remove", 
        delete_url_endpoint="servers.delete_server", 
        delete_url_values=None, 
        empty_list_msg="No servers found", 
        delete_dialog_title="Remove", 
        delete_dialog_msg="Do you want to remove the server <em>%s</em>?", 
        delete_dialog_submit_title="Remove server", 
        delete_dialog_cancel_title="Cancel", 
        value_bindings={
            "state": lambda value: dict(SERVER_STATE_CHOICES)[value],
            "protocol": lambda value: dict(SERVER_PROTOCOL_CHOICES)[value],
        }
    )
    return render_template("layout/server/list.html", context=context, SERVER_STATE_REMOVING=SERVER_STATE_REMOVING)


@servers_bp.route('/add/', methods=['GET', 'POST'])
@login_required
def create_server():
    form = ServerForm(request.form, obj=Server('example'))
    if form.validate_on_submit():
        server = Server(form.name.data, 
                        hostname=form.hostname.data, 
                        namespace=form.namespace.data, 
                        port=form.port.data, 
                        protocol=form.protocol.data, 
                        appversion=form.appversion.data)
        db.session.add(server)
        db.session.commit()

        schedule_install_server_job(server)

        flash("The new server was scheduled for creation.", "success")
        return redirect(url_for("servers.list_servers"))

    context = CreateWidgetContext(
        title="Add server", 
        model_name="Server",
        form=form, 
        fields=server_create_fields, 
        close_button_title="Discard", 
        close_url_endpoint="servers.list_servers", 
        close_url_values=None, 
        create_button_title="Add a new server", 
        create_url_endpoint="servers.create_server", 
        create_url_values=None, 
    )
    return render_template("/layout/server/create.html", context=context)


@servers_bp.route('/get/<int:id>', methods=['GET'])
@login_required
def retrieve_server(id):
    server = Server.query.get(id)
    if server:
        form = ServerForm(request.form, obj=server)
        context = RetrieveWidgetContext(
            title="Details for <em>%s</em>" % server.name, 
            model_name="Server",
            form=form, 
            fields=server_retrieve_fields, 
            close_button_title="Go to list", 
            close_url_endpoint="servers.list_servers", 
            close_url_values=None, 
            delete_button_title="Remove", 
            delete_url_endpoint="servers.delete_server", 
            delete_url_values={"id": server.id}, 
            update_button_title="Edit", 
            update_url_endpoint="servers.update_server", 
            update_url_values={"id": server.id}, 
            retrieve_url_endpoint="servers.retrieve_server", 
            retrieve_url_values={"id": server.id}, 
            delete_dialog_title="Remove", 
            delete_dialog_msg="Do you want to remove this server?", 
            delete_dialog_submit_title="Remove server", 
            delete_dialog_cancel_title="Cancel", 
            render_binding=lambda name: None if name in ["id", "prev_state"] else True,
        )
        return render_template("/layout/server/retrieve.html", context=context, 
                               SERVER_STATE_FAILED=SERVER_STATE_FAILED, 
                               SERVER_STATE_REMOVING=SERVER_STATE_REMOVING, 
                               SERVER_STATE_CREATING=SERVER_STATE_CREATING)
    else:
        flash("Server not found.", "danger")
        return redirect(url_for("servers.list_servers"))


@servers_bp.route('/install/<int:id>', methods=['POST'])
@login_required
def install_server(id):
    server = Server.query.get(id)
    if server:
        server.prev_state = server.state
        server.state = SERVER_STATE_CREATING
        server.errmsg = None
        db.session.commit()

        schedule_install_server_job(server)

        flash("The new server was scheduled for creation.", "success")

        form = ServerForm(request.form, obj=server)
        return redirect(url_for("servers.retrieve_server", id=server.id))
    else:
        flash("Server not found.", "danger")

    return redirect(url_for("servers.list_servers"))


@servers_bp.route('/update/<int:id>', methods=['GET', 'POST'])
@login_required
def update_server(id):
    server = Server.query.get(id)
    if server:
        form = ServerForm(request.form, obj=server)
        if form.validate_on_submit():
            form.populate_obj(server)
            db.session.commit()
            flash("The server was updated.", "success")
            return redirect(url_for("servers.retrieve_server", id=server.id))
        else:
            context = UpdateWidgetContext(
                title="Edit <em>%s</em>" % server.name, 
                model_name="Server",
                form=form, 
                fields=server_update_fields, 
                close_button_title="Discard", 
                close_url_endpoint="servers.retrieve_server", 
                close_url_values={"id": server.id}, 
                update_button_title="Update server", 
                update_url_endpoint="servers.update_server", 
                update_url_values={"id": server.id}, 
                render_binding=lambda name: None if name == "id" else True,
            )
            return render_template("layout/server/update.html", context=context)
    else:
        flash("Server not found.", "danger")

    return redirect(url_for("servers.list_servers"))


@servers_bp.route('/delete/<int:id>', methods=['POST'])
@login_required
def delete_server(id):
    server = Server.query.get(id)
    if not server:
        flash("Server not found.", "danger")
    else:
        server.prev_state = server.state
        server.state = SERVER_STATE_REMOVING
        server.errmsg = None
        db.session.commit()

        schedule_uninstall_server_job(server)

        flash(f"The server {server.name} was scheduled for removal.", "success")

    return redirect(url_for("servers.list_servers"))


# ------- 
# Clients
# -------

client_list_fields = ["name", "email", "state", "server_id"]
client_retrieve_fields = ["id", "name", "email", "state"]
client_update_fields = ["id", "name", "email"]
client_create_fields = ["name", "email"]


@servers_bp.route("/<int:server_id>/client", methods=["GET"])
@login_required
def list_clients(server_id):
    server = Server.query.get(server_id)
    clients = server.clients
    context = ListWidgetContext(
        title="Clients for server <em>%s</em>" % server.name, 
        model_name="client",
        form=ClientForm(), 
        fields=client_list_fields, 
        objs=clients, 
        create_button_title="Add a client", 
        create_url_endpoint="servers.create_client", 
        create_url_values={'server_id': server.id}, 
        retrieve_url_endpoint="servers.retrieve_client", 
        retrieve_url_values={'server_id': server.id}, 
        delete_button_title="Remove", 
        delete_url_endpoint="servers.delete_client", 
        delete_url_values={'server_id': server.id}, 
        empty_list_msg="No clients found", 
        delete_dialog_title="Remove", 
        delete_dialog_msg="Do you want to remove the client <em>%s</em>?", 
        delete_dialog_submit_title="Remove client", 
        delete_dialog_cancel_title="Cancel", 
        value_bindings={
            "state": lambda value: dict(CLIENT_STATE_CHOICES)[value],
        }
    )
    return render_template("layout/client/list.html", context=context, server=server, 
                           SERVER_STATE_EXECUTING=SERVER_STATE_EXECUTING,
                           CLIENT_STATE_REMOVING=CLIENT_STATE_REMOVING)


@servers_bp.route('/<int:server_id>/client/add/', methods=['GET', 'POST'])
@login_required
def create_client(server_id):
    form = ClientForm(request.form, obj=Client(None, None, server_id))
    if form.validate_on_submit():
        client = Client(form.name.data,
                        form.server_id.data)
        db.session.add(client)
        db.session.commit()

        schedule_add_client_job(client)

        flash("The new client was scheduled for addition.", "success")
        return redirect(url_for("servers.retrieve_server", id=server_id))

    context = CreateWidgetContext(
        title="Add client", 
        model_name="client",
        form=form, 
        fields=client_create_fields, 
        close_button_title="Discard", 
        close_url_endpoint="servers.list_clients", 
        close_url_values={'server_id': server_id},
        create_button_title="Add a new client", 
        create_url_endpoint="servers.create_client", 
        create_url_values={'server_id': server_id}, 
    )
    return render_template("layout/create.html", context=context)


@servers_bp.route('/<int:server_id>/client/retry/<int:id>', methods=['POST'])
@login_required
def retry_create_client(server_id, id):
    client = Client.query.get(id)
    if client:
        client.state = CLIENT_STATE_ADDING
        client.errmsg = None
        db.session.commit()

        schedule_add_client_job(client)

        flash("The new client was scheduled for creation.", "success")

        form = ClientForm(request.form, obj=client)
        return redirect(url_for("servers.retrieve_client", server_id=server_id, id=client.id))
    else:
        flash("Client not found.", "danger")

    return redirect(url_for("servers.retrieve_server", id=server_id))


@servers_bp.route('/<int:server_id>/client/get/<int:id>', methods=['GET'])
@login_required
def retrieve_client(server_id, id):
    client = Client.query.get(id)
    if client:
        form = ClientForm(request.form, obj=client)
        context = RetrieveWidgetContext(
            title="Details for <em>%s</em>" % client.name, 
            model_name="client",
            form=form, 
            fields=client_retrieve_fields, 
            close_button_title="Go to list", 
            close_url_endpoint="servers.list_clients", 
            close_url_values={"server_id": server_id}, 
            delete_button_title="Remove", 
            delete_url_endpoint="servers.delete_client", 
            delete_url_values={"server_id": server_id}, 
            update_button_title="Edit", 
            update_url_endpoint="servers.update_client", 
            update_url_values={"server_id": server_id}, 
            retrieve_url_endpoint="servers.retrieve_client", 
            retrieve_url_values={"server_id": server_id}, 
            delete_dialog_title="Remove", 
            delete_dialog_msg="Do you want to remove this client?", 
            delete_dialog_submit_title="Remove client", 
            delete_dialog_cancel_title="Cancel", 
            render_binding=lambda name: None if name == "id" else True,
        )
        return render_template("layout/client/retrieve.html", context=context,
                               CLIENT_STATE_FAILED=CLIENT_STATE_FAILED, 
                               CLIENT_STATE_REMOVING=CLIENT_STATE_REMOVING, 
                               CLIENT_STATE_ADDING=CLIENT_STATE_ADDING)
    else:
        flash("Client not found.", "danger")
        return redirect(url_for("servers.retrieve_server", id=server_id))


@servers_bp.route('/<int:server_id>/client/update/<int:id>', methods=['GET', 'POST'])
@login_required
def update_client(server_id, id):
    client = Client.query.get(id)
    if client:
        form = ClientForm(request.form, obj=client)
        if form.validate_on_submit():
            form.populate_obj(client)
            db.session.commit()
            flash("The client was updated.", "success")
            return redirect(url_for("servers.retrieve_client", server_id=server_id, id=client.id))
        else:
            context = UpdateWidgetContext(
                title="Edit <em>%s</em>" % client.name, 
                model_name="client",
                form=form, 
                fields=client_update_fields, 
                close_button_title="Discard", 
                close_url_endpoint="servers.retrieve_client", 
                close_url_values={"server_id": server_id}, 
                update_button_title="Update client", 
                update_url_endpoint="servers.update_client", 
                update_url_values={"server_id": server_id}, 
                render_binding=lambda name: None if name == "id" else True,
            )
            return render_template("layout/update.html", context=context)
    else:
        flash("Client not found.", "danger")

    return redirect(url_for("servers.list_clients"))

@servers_bp.route('/<int:server_id>/client/delete/<int:id>', methods=['POST'])
@login_required
def delete_client(server_id, id):
    client = Client.query.get(id)
    if not client:
        flash("Client not found.", "danger")
    else:
        client.state = SERVER_STATE_REMOVING
        client.errmsg = None
        db.session.commit()

        schedule_remove_client_job(client)

        flash(f"The client {client.name} was scheduled for removal.", "success")

    return redirect(url_for("servers.retrieve_server", id=server_id))

