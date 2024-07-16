from flask_wtf import FlaskForm
from wtforms import (StringField, EmailField, SelectField, IntegerField, SubmitField, TextAreaField, 
                     FieldList, FormField)
from wtforms.validators import AnyOf, Regexp, DataRequired, InputRequired, NumberRange, Length

from .models import (Server, SERVER_PROTOCOL_TCP, SERVER_PROTOCOL_UDP, SERVER_STATE_CREATING, 
                     SERVER_STATE_EXECUTING, SERVER_STATE_STOPPED, SERVER_STATE_REMOVING, 
                     SERVER_STATE_FAILED, Client, CLIENT_STATE_ADDING, CLIENT_STATE_ADDED, 
                     CLIENT_STATE_REMOVING, CLIENT_STATE_FAILED)


REGEX_NAME = "^[a-z0-9][-a-z0-9]*[a-z0-9]$"
REGEX_HOSTNAME = "^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])(.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]))*$"
REGEX_NAMESPACE = "^[a-z0-9][-a-z0-9]*[a-z0-9]$"
REGEX_PORT = "^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"

SERVER_PROTOCOL_TCP_LABEL = "TCP"
SERVER_PROTOCOL_UDP_LABEL = "UDP"

SERVER_PROTOCOL_VALUES = [SERVER_PROTOCOL_TCP, SERVER_PROTOCOL_UDP]
SERVER_PROTOCOL_CHOICES = [(SERVER_PROTOCOL_TCP, SERVER_PROTOCOL_TCP_LABEL), 
                           (SERVER_PROTOCOL_UDP, SERVER_PROTOCOL_UDP_LABEL)]

SERVER_STATE_CREATING_LABEL = "Creating"
SERVER_STATE_EXECUTING_LABEL = "Executing"
SERVER_STATE_STOPPED_LABEL = "Stopped"
SERVER_STATE_REMOVING_LABEL = "Removing"
SERVER_STATE_FAILED_LABEL = "Failed"

SERVER_STATE_VALUES = [SERVER_STATE_CREATING, SERVER_STATE_EXECUTING, SERVER_STATE_STOPPED, 
                       SERVER_STATE_REMOVING, SERVER_STATE_FAILED]
SERVER_STATE_CHOICES = [(SERVER_STATE_CREATING, SERVER_STATE_CREATING_LABEL), 
                        (SERVER_STATE_EXECUTING, SERVER_STATE_EXECUTING_LABEL), 
                        (SERVER_STATE_STOPPED, SERVER_STATE_STOPPED_LABEL), 
                        (SERVER_STATE_REMOVING, SERVER_STATE_REMOVING_LABEL), 
                        (SERVER_STATE_FAILED, SERVER_STATE_FAILED_LABEL)]


CLIENT_STATE_ADDING_LABEL = "Adding"
CLIENT_STATE_ADDED_LABEL = "Added"
CLIENT_STATE_REMOVING_LABEL = "Removing"
CLIENT_STATE_FAILED_LABEL = "Failed"

CLIENT_STATE_VALUES = [CLIENT_STATE_ADDING, CLIENT_STATE_ADDED, CLIENT_STATE_REMOVING, CLIENT_STATE_FAILED]
CLIENT_STATE_CHOICES = [(CLIENT_STATE_ADDING, CLIENT_STATE_ADDING_LABEL),
                        (CLIENT_STATE_ADDED, CLIENT_STATE_ADDED_LABEL),
                        (CLIENT_STATE_REMOVING, CLIENT_STATE_REMOVING_LABEL),
                        (CLIENT_STATE_FAILED, CLIENT_STATE_FAILED_LABEL)]


class ClientForm(FlaskForm):
    id = IntegerField("ID")
    name = StringField(
        "Nombre", validators=[DataRequired(), Regexp(regex=REGEX_NAME), Length(min=1, max=63)]
    )
    email = EmailField(
        "Email", validators=[DataRequired(), Length(min=1, max=63)]
    )
    state = SelectField(
        "Estado", validators=[DataRequired(), AnyOf(CLIENT_STATE_VALUES)], choices=CLIENT_STATE_CHOICES
    )
    errmsg = TextAreaField("Errores")
    server_id = IntegerField("Server")

    submit = SubmitField("Add Client")

    def validate(self, extra_validators=None):
        initial_validation = super(ClientForm, self).validate()
        print('client initial_validation: {0}'.format(initial_validation))
        if not initial_validation:
            return False
        client = Client.query.filter_by(server_id=self.server_id.data, name=self.name.data).first()
        if client and client.id != self.id.data:
            print('client found: {0}'.format(client.name))
            self.name.errors.append("Name already registered")
            return False
        client = Client.query.filter_by(email=self.email.data).first()
        if client and client.id != self.id.data:
            print('client found: {0}'.format(client.name))
            self.name.errors.append("Email already registered")
            return False
        print('client validation OK')
        return True


class ServerForm(FlaskForm):
    id = IntegerField("ID")
    name = StringField(
        "Nombre", validators=[DataRequired(), Regexp(regex=REGEX_NAME), Length(min=1, max=63)]
    )
    hostname = StringField(
        "Hostname", validators=[DataRequired(), Regexp(regex=REGEX_HOSTNAME), Length(min=1, max=255)]
    )
    namespace = StringField(
        "Namespace", validators=[DataRequired(), Regexp(regex=REGEX_NAMESPACE), Length(min=1, max=63)]
    )
    port = IntegerField(
        "Puerto", validators=[DataRequired(), NumberRange(min=1, max=65535)]
    )
    protocol = SelectField(
        "Protocolo", validators=[DataRequired(), AnyOf(SERVER_PROTOCOL_VALUES)], choices=SERVER_PROTOCOL_CHOICES
    )
    appversion = StringField(
        "Versión", validators=[DataRequired()]
    )
    state = SelectField(
        "Estado", validators=[DataRequired(), AnyOf(SERVER_STATE_VALUES)], choices=SERVER_STATE_CHOICES
    )
    prev_state = SelectField(
        "Estado Previo", validators=[AnyOf(SERVER_STATE_VALUES)], choices=SERVER_STATE_CHOICES
    )
    errmsg = TextAreaField("Errores")
    clients = FieldList(FormField(ClientForm))

    submit = SubmitField("Add Server")

    def validate(self, extra_validators=None):
        for name, field in self._fields.items():
            if extra_validators is not None and name in extra_validators:
                extra = extra_validators[name]
            else:
                extra = tuple()
            if not field.validate(self, extra):
                print("Fallo en campo: {0}".format(name))
        initial_validation = super(ServerForm, self).validate()
        print('server initial_validation: {0}'.format(initial_validation))
        if not initial_validation:
            return False
        server = Server.query.filter_by(name=self.name.data).first()
        if server and server.id != self.id.data:
            print('server found: '.format(server.name))
            self.name.errors.append("Name already registered")
            return False
        print('server validation OK')
        return True
