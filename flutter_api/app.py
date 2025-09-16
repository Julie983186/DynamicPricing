from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from db_config import db_config

app = Flask(__name__)

# 修正：明確地將 CORS 套用到整個應用程式
CORS(app, supports_credentials=True)

# 使用從 db_config.py 匯入的資料庫設定
app.config['MYSQL_HOST'] = db_config['host']
app.config['MYSQL_USER'] = db_config['user']
app.config['MYSQL_PASSWORD'] = db_config['password']
app.config['MYSQL_DB'] = db_config['database']

mysql = MySQL(app)

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')

    try:
        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users (name, phone, email, password) VALUES (%s, %s, %s, %s)",
                    (name, phone, email, password))
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '註冊成功'}), 200
    except Exception as e:
        import traceback
        print(traceback.format_exc())  # 印出完整錯誤訊息
        return jsonify({'message': '註冊失敗', 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']

    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM users WHERE email=%s AND password=%s", (email, password))
        user = cur.fetchone()
        cur.close()

        if user:
            return jsonify({'message': '登入成功'}), 200
        else:
            return jsonify({'message': '帳號或密碼錯誤'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500


