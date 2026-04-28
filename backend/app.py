from flask import Flask

from config import Config

from routes.auth import auth_bp
from routes.exam import exam_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(exam_bp, url_prefix="/exam")

    @app.get("/")
    def health_check():
        return {
            "status": "ok",
            "message": "secure-exam-usb-os backend is running",
        }

    return app


if __name__ == "__main__":
    create_app().run(debug=True)
