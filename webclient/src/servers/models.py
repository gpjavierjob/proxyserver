from sqlalchemy import inspect
from sqlalchemy.orm import validates
from sqlalchemy.schema import Index
from datetime import datetime
from src import db
from src.core.models import AutoIncrementMixin, AuditableMixin

SERVER_PROTOCOL_TCP = "tcp"
SERVER_PROTOCOL_UDP = "udp"

DEFAULT_SERVER_NAME = "openvpn"
DEFAULT_SERVER_HOSTNAME = "vpn.{name}.com"
DEFAULT_SERVER_NAMESPACE = "{name}"
DEFAULT_SERVER_PORT = 1194
DEFAULT_SERVER_PROTOCOL = SERVER_PROTOCOL_TCP
DEFAULT_SERVER_APPVERSION = "latest"

SERVER_STATE_CREATING = "creating"
SERVER_STATE_EXECUTING = "executing"
SERVER_STATE_STOPPED = "stopped"
SERVER_STATE_REMOVING = "removing"
SERVER_STATE_FAILED = "failed"

DEFAULT_SERVER_STATE = SERVER_STATE_CREATING


class Server(db.Model, AutoIncrementMixin, AuditableMixin):

    __tablename__ = "servers"

# Input by User Fields:
    name = db.Column(db.String, unique=True, nullable=False)
    hostname = db.Column(db.String, nullable=False)
    namespace = db.Column(db.String, nullable=False)
    port = db.Column(db.SmallInteger, nullable=False)
    protocol = db.Column(db.String, nullable=False)
    appversion = db.Column(db.String, nullable=False)

# Managed Fields
    state = db.Column(db.String, nullable=False)
    prev_state = db.Column(db.String, nullable=True)
    errmsg = db.Column(db.String, nullable=True)
    clients = db.relationship('Client', backref='server', lazy=True)

    def __init__(self, name, hostname=None, namespace=None, port=None, protocol=None, appversion=None):
        self.name = name
        self.hostname = hostname if hostname else DEFAULT_SERVER_HOSTNAME.format(name=name)
        self.namespace = namespace if namespace else DEFAULT_SERVER_NAMESPACE.format(name=name)
        self.port = port if port else DEFAULT_SERVER_PORT
        self.protocol = protocol if protocol else DEFAULT_SERVER_PROTOCOL
        self.appversion = appversion if appversion else DEFAULT_SERVER_APPVERSION
        self.state = DEFAULT_SERVER_STATE
        self.errmsg = None

    @validates('name', 'hostname', 'namespace', 'protocol', 'appversion')
    def empty_string_to_null(self, key, value):
        if isinstance(value, str) and value == '': return None
        else: return value

    @validates('port')
    def zero_to_null(self, key, value):
        if isinstance(value, int) and value == 0: return None
        else: return value

    def toDict(self):
        return { c.key: getattr(self, c.key) for c in inspect(self).mapper.column_attrs }

    def __repr__(self):
        return f"<{self.name}>"


CLIENT_STATE_ADDING = "adding"
CLIENT_STATE_ADDED = "added"
CLIENT_STATE_REMOVING = "removing"
CLIENT_STATE_FAILED = "failed"

DEFAULT_CLIENT_STATE = CLIENT_STATE_ADDING


class Client(db.Model, AutoIncrementMixin, AuditableMixin):

    __tablename__ = "clients"

# Input by User Fields:
    name = db.Column(db.String, nullable=False)
    email = db.Column(db.String, nullable=False)

# Managed Fields
    state = db.Column(db.String, nullable=False)
    errmsg = db.Column(db.String, nullable=True)
    server_id = db.Column(db.Integer, db.ForeignKey('servers.id'), nullable=False)

    def __init__(self, name, email, server_id):
        self.name = name
        self.email = email
        self.server_id = server_id
        self.state = DEFAULT_CLIENT_STATE
        self.errmsg = None

    @validates('name', 'email')
    def empty_string_to_null(self, key, value):
        if isinstance(value, str) and value == '': return None
        else: return value

    def toDict(self):
        return { c.key: getattr(self, c.key) for c in inspect(self).mapper.column_attrs }

    def __repr__(self):
        return f"<{self.name}>"


Index('client_server_id_name_index', Client.server_id, Client.name)
Index('client_server_id_email_index', Client.server_id, Client.email)
