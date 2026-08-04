
from flask import Flask
from flask_cors import CORS

from backend.auth_setup import ensure_default_admin
from backend.config import engine
from backend.models import metadata
from backend.routes.auth import auth_bp
from backend.routes.exam import exam_bp
from backend.routes.imports import import_bp
from backend.routes.config_routes import config_bp


# Ensure DB tables exist
metadata.create_all(engine)
ensure_default_admin(engine)

app = Flask(__name__)
CORS(app)

app.register_blueprint(auth_bp)
app.register_blueprint(exam_bp)
app.register_blueprint(import_bp)
app.register_blueprint(config_bp)


@app.route("/")
def home():
    return {"message": "Backend running"}


if __name__ == "__main__":
    app.run(debug=True)
