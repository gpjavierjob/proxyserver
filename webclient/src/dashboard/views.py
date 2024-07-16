from flask import Flask, Blueprint, render_template
from flask_login import login_required

dashboard_bp = Blueprint("dashboard", __name__, template_folder='templates', static_folder='static')

@dashboard_bp.route("/")
@dashboard_bp.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")
