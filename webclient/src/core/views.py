from flask import Blueprint, render_template
from flask_login import login_required

core_bp = Blueprint("core", __name__, template_folder='templates', static_folder='static', 
                    url_prefix='/core/')


@core_bp.route("/")
@login_required
def home():
    return render_template("index.html")