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


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']

    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE email=%s AND password=%s", (email, password))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3]
            }
            return jsonify({'message': '登入成功', 'user': user_data}), 200
        else:
            return jsonify({'message': '帳號或密碼錯誤'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
# 抓取會員資料
@app.route('/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, name, phone, email FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        cur.close()

        if user:
            user_data = {
                'id': user[0],
                'name': user[1],
                'phone': user[2],
                'email': user[3],
            }
            return jsonify(user_data), 200
        else:
            return jsonify({'message': '找不到該會員'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
# 更新會員資料
@app.route('/user/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.get_json()
    
    # 只取出前端傳過來的欄位
    fields = {}
    for key in ['name', 'email', 'phone', 'password']:
        if key in data:
            fields[key] = data[key]

    if not fields:
        return jsonify({'message': '沒有可更新的欄位'}), 400

    # 動態生成 SQL
    set_clause = ", ".join([f"{key}=%s" for key in fields.keys()])
    values = list(fields.values())
    values.append(user_id)  # id 放最後

    try:
        cur = mysql.connection.cursor()
        sql = f"UPDATE users SET {set_clause} WHERE id=%s"
        cur.execute(sql, values)
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '更新成功'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500



    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)


