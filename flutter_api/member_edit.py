from flask import Blueprint, request, jsonify, current_app

# 建立 Blueprint
user_bp = Blueprint("user", __name__)

# -----------------------------
# 註冊 API
# -----------------------------
@user_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    name = data.get("name")
    phone = data.get("phone")
    email = data.get("email")
    password = data.get("password")

    try:
        mysql = current_app.config["MYSQL_INSTANCE"]
        cur = mysql.connection.cursor()
        cur.execute(
            "INSERT INTO users (name, phone, email, password) VALUES (%s, %s, %s, %s)",
            (name, phone, email, password)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify({"message": "註冊成功"}), 200
    except Exception as e:
        return jsonify({"message": "註冊失敗", "error": str(e)}), 500

# -----------------------------
# 登入 API
# -----------------------------
@user_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")

    try:
        mysql = current_app.config["MYSQL_INSTANCE"]
        cur = mysql.connection.cursor()
        cur.execute(
            "SELECT * FROM users WHERE email=%s AND password=%s",
            (email, password)
        )
        user = cur.fetchone()
        cur.close()

        if user:
            return jsonify({"message": "登入成功"}), 200
        else:
            return jsonify({"message": "帳號或密碼錯誤"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -----------------------------
# 修改會員資料 API
# -----------------------------
@user_bp.route("/update_user", methods=["POST"])
def update_user():
    data = request.get_json()
    name = data.get("name")   # 可改成 user_id 或 email 做唯一識別
    phone = data.get("phone")
    email = data.get("email")
    password = data.get("password")

    try:
        mysql = current_app.config["MYSQL_INSTANCE"]
        cur = mysql.connection.cursor()
        query = """
            UPDATE users
            SET phone = %s, email = %s, password = %s
            WHERE name = %s
        """
        cur.execute(query, (phone, email, password, name))
        mysql.connection.commit()
        row_count = cur.rowcount
        cur.close()

        if row_count > 0:
            return jsonify({"message": "資料更新成功"}), 200
        else:
            return jsonify({"message": "找不到該使用者"}), 404
    except Exception as e:
        return jsonify({"message": "資料更新失敗", "error": str(e)}), 500
