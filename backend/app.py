from flask import Flask
from flask_cors import CORS

from config import engine
from models import metadata
from routes.auth import auth_bp
from routes.exam import exam_bp


metadata.create_all(engine)

app = Flask(__name__)
CORS(app)

app.register_blueprint(auth_bp)
app.register_blueprint(exam_bp)


@app.route("/")
def home():
    return {"message": "Backend running"}


if __name__ == "__main__":
    app.run(debug=True)
