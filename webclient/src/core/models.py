from datetime import datetime
from flask_login import current_user
from sqlalchemy.orm import validates
from src import db


def get_current_user_name():
    return current_user.email if current_user else "system"


class AutoIncrementMixin():
# Auto Generated Fields:
    id = db.Column(db.Integer, primary_key=True)


class ArchivedMixin():
# Auto Generated Fields:
    archived = db.Column(db.Boolean, default=False)


class AuditableMixin():
# Auto Generated Fields:
    # The Date of the Instance Creation => Created one Time when Instantiation
    created_on = db.Column(db.DateTime(timezone=True), default=datetime.now)
    # The User of the Instance Creation => Created one Time when Instantiation
    created_by = db.Column(db.String, default=get_current_user_name, onupdate=get_current_user_name)
    # The Date of the Instance Update => Changed with Every Update
    updated_on = db.Column(db.DateTime(timezone=True), default=datetime.now, onupdate=datetime.now)
    # The User of the Instance Update => Changed with Every Update
    updated_by = db.Column(db.String, default=get_current_user_name, onupdate=get_current_user_name)
