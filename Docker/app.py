from flask import Flask, jsonify

app = Flask(__name__)

# GET request for root path
@app.route('/', methods=['GET'])
def get_data():
    data = {"CS 454 Project 2": "Hello World!"}
    return jsonify(data)

# Expose port 5000
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)