from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from db_config import db_config
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
import traceback

app = Flask(__name__)

# CORS
CORS(app, supports_credentials=True)

# MySQL 設定
app.config['MYSQL_HOST'] = db_config['host']
app.config['MYSQL_USER'] = db_config['user']
app.config['MYSQL_PASSWORD'] = db_config['password']
app.config['MYSQL_DB'] = db_config['database']

# JWT 設定
app.config['JWT_SECRET_KEY'] = 'TanJiDynamicPricing2025finalproject'
jwt = JWTManager(app)

mysql = MySQL(app)

# ---------------------- 註冊 ----------------------
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            "INSERT INTO users (name, phone, email, password) VALUES (%s, %s, %s, %s)",
            (name, phone, email, password)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': '註冊成功'}), 200
    except Exception as e:
        print(traceback.format_exc())
        return jsonify({'message': '註冊失敗', 'error': str(e)}), 500

# ---------------------- 登入 ----------------------
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
            # 建立 JWT Token
            token = create_access_token(identity=str(user_data['id']))
            return jsonify({'message': '登入成功', 'user': user_data, 'token': token}), 200
        else:
            return jsonify({'message': '帳號或密碼錯誤'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- 取得會員資料 ----------------------
@app.route('/user/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    current_user = int(get_jwt_identity())
    if current_user != user_id:
        return jsonify({'message': '沒有權限查看此資料'}), 403

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

# ---------------------- 更新會員資料 ----------------------
@app.route('/user/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    current_user = int(get_jwt_identity())
    if current_user != user_id:
        return jsonify({'message': '沒有權限更新此資料'}), 403

    data = request.get_json()
    fields = {k: v for k, v in data.items() if k in ['name', 'email', 'phone', 'password']}

    if not fields:
        return jsonify({'message': '沒有可更新的欄位'}), 400

    set_clause = ", ".join([f"{key}=%s" for key in fields.keys()])
    values = list(fields.values())
    values.append(user_id)

    try:
        cur = mysql.connection.cursor()
        sql = f"UPDATE users SET {set_clause} WHERE id=%s"
        cur.execute(sql, values)
        mysql.connection.commit()

        # 再抓更新後的資料
        cur.execute("SELECT id, name, phone, email FROM users WHERE id=%s", (user_id,))
        updated_user = cur.fetchone()
        cur.close()

        user_data = {
            'id': updated_user[0],
            'name': updated_user[1],
            'phone': updated_user[2],
            'email': updated_user[3],
        }

        return jsonify({'message': '更新成功', 'user': user_data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- 抓歷史資料 ----------------------
@app.route('/get_products/<string:user_id>', methods=['GET'])
def get_products(user_id):
    try:
        # 支援訪客模式
        if user_id == "0" or user_id.lower() == "guest":
            return jsonify({'products': []}), 200

        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.productid, p.producttype, p.proname, p.proprice,   
                   h.created_at, p.expiredate, p.status, p.market
            FROM history h
            JOIN product p ON h.productid = p.productid
            WHERE h.userid = %s
            ORDER BY h.created_at DESC
        """, (user_id,))
        products = cur.fetchall()
        cur.close()

        product_list = []
        for p in products:
            product_list.append({
                'ProductID': p[0],
                'ProductType': p[1],
                'ProName': p[2],
                'ProPrice': p[3],
                'ScanDate': p[4].strftime('%Y-%m-%d') if p[4] else None,
                'ExpireDate': p[5].strftime('%Y-%m-%d') if p[5] else None,
                'Status': p[6],
                'Market': p[7],
            })
        return jsonify({'products': product_list}), 200

    except Exception as e:
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

# ---------------------- 啟動 ----------------------

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
