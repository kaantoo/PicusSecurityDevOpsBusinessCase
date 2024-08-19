from flask import Flask, request, jsonify
import boto3
import uuid

app = Flask(__name__)

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('TestDB')

@app.route('/dev/picus/list', methods=['GET'])
def list_items():
    response = table.scan()
    return jsonify(response['Items'])

@app.route('/dev/picus/put', methods=['POST'])
def put_item():
    item = request.json
    item['id'] = str(uuid.uuid4())
    table.put_item(Item=item)
    return jsonify(item)

@app.route('/dev/picus/get/<key>', methods=['GET'])
def get_item(key):
    response = table.get_item(Key={'id': key})
    return jsonify(response['Item'])

if __name__ == '__main__':
    app.run(host='127.0.0.1', port = 8082, debug=True)
