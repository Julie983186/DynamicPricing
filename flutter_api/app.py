from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from db_config import db_config
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from paddleocr import PaddleOCR
import re, traceback
from datetime import datetime, date
from ml_model import predict_price, prepare_features, feature_cols
import threading, time
import os
import traceback
import pandas as pd

app = Flask(__name__)
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
ocr = PaddleOCR(lang='ch', use_textline_orientation=False, ocr_version='PP-OCRv4')


from opencc import OpenCC
cc = OpenCC('s2t')
# 關鍵字分類
MEAT_KEYWORDS = ["豬", "牛", "雞", "羊", "腿", "排", "骨", "燒烤片", "火烤片", "肉片", "火鍋片", "絞肉"]
SEAFOOD_KEYWORDS = ["魚", "蝦", "魷", "鮭", "花枝", "章魚", "鯛", "干貝", "蛤", "牡蠣", "螺", "白管", "海帶"]
VEG_KEYWORDS = ["菜", "瓜", "果", "蔬", "蘋果", "香蕉", "橘子", "葡萄", "山藥", "豆芽", "筍", "菇", "椒", "番茄", "洋蔥", "芭樂", "蔥", "櫻桃", "秋葵", "梨", "柑", "柚"]
BAKERY_KEYWORDS = ["吐司", "麵包", "蛋糕", "可頌", "甜甜圈", "佛卡夏", "貝果", "鬆餅", "德國結", "蛋塔", "法式", "餅"]
BEAN_KEYWORDS = ["豆腐", "豆干", "豆皮", "百頁", "豆包", "素"]
READY_TO_EAT_KEYWORDS = ["三明治", "便當", "沙拉", "餃子皮", "火鍋料", "水果盤"]



def extract_prices(texts):
    normal_candidates = []

    for line in texts:
        
        matches = re.findall(r"(\d+(?:\.\d+)?)\s*元", line)

        for m in matches:
            if "元/" in line:
                continue

            normal_candidates.append(int(float(m)))

    price = max(normal_candidates) if normal_candidates else None
    pro_price = min(normal_candidates) if normal_candidates else None

    return price, pro_price


def extract_product_info(texts):
    info = {"ProName": None, "ExpireDate": None, "Price": None, "ProPrice": None}
    max_length = 0 
    full_text = "\n".join(texts)
    # 商品名稱
    for line in texts:
        if any(k in line for k in MEAT_KEYWORDS + SEAFOOD_KEYWORDS + VEG_KEYWORDS +
                                BAKERY_KEYWORDS + BEAN_KEYWORDS + READY_TO_EAT_KEYWORDS):
            if len(line) > max_length:
                info["ProName"] = line
                max_length = len(line)

    # 有效日期
    date_match = re.search(r"(\d{4}\.\d{1,2}\.\d{1,2})", full_text)
    if date_match:
        info["ExpireDate"] = date_match.group(1)

    # 原價 / 即期價
    price, pro_price = extract_prices(texts)
    info["Price"] = price
    info["ProPrice"] = pro_price

    return info


def detect_product_type(name: str) -> str:
    if not name:
        return "未知"
    if any(k in name for k in MEAT_KEYWORDS):
        return "肉類"
    if any(k in name for k in SEAFOOD_KEYWORDS):
        return "魚類"
    if any(k in name for k in VEG_KEYWORDS):
        return "蔬果類"
    if any(k in name for k in BAKERY_KEYWORDS):
        return "麵包甜點類"
    if any(k in name for k in BEAN_KEYWORDS):
        return "豆製品類"
    if any(k in name for k in READY_TO_EAT_KEYWORDS):
        return "熟食/其他"
    return "其他"


def normalize_date(expire_str):
    """轉換日期字串為 YYYY-MM-DD, 並判斷狀態"""
    if not expire_str:
        return None, "未知"
    try:
        clean_str = expire_str.replace(".", "-")
        exp = datetime.strptime(clean_str, "%Y-%m-%d").date()
        status = "未過期" if exp >= date.today() else "已過期"
        return exp.strftime("%Y-%m-%d"), status
    except Exception as e:
        print("日期解析失敗:", expire_str, e)
        return None, "未知"

# ---------------------- OCR API ----------------------
import os
from flask import send_from_directory

UPLOAD_DIR = os.path.join(os.getcwd(), "uploads")
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

@app.route("/ocr", methods=["POST"])
@jwt_required(optional=True)
def ocr_api():
    file = request.files.get("image")
    market = request.form.get("market", "未知賣場")
    user_id = get_jwt_identity()

    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}.jpg"
    filepath = os.path.join(UPLOAD_DIR, filename)
    file.save(filepath)

    db_path = f"/uploads/{filename}"


    # OCR 辨識
    result = ocr.predict(filepath)
    texts = []
    for item in result:
        texts.extend(item['rec_texts'])

    # 轉繁體
    texts = [cc.convert(t) for t in texts]

    print("===== OCR 辨識結果 =====")
    print(texts)

    info = extract_product_info(texts)
    print("===== 抽取後的商品資訊 =====")
    print(info)

    # 格式化日期
    expire_date, status = normalize_date(info.get("ExpireDate"))

    # 判斷類別
    product_type = detect_product_type(info["ProName"])

    try:
        cur = mysql.connection.cursor()
        sql = """
            INSERT INTO product (ProName, ExpireDate, Price, ProPrice, Market, Status, ProductType, ImagePath)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cur.execute(sql, (
            info["ProName"],
            expire_date,
            info["Price"],
            info["ProPrice"],
            market,
            status,
            product_type,
            db_path
        ))
        product_id = cur.lastrowid
        print("插入 product 成功, ProductID:", product_id)

        # 寫入 history
        print("登入 user_id:", user_id)
        if user_id:
            cur.execute(
                "INSERT INTO history (userID, productID, created_at) VALUES (%s, %s, NOW())",
                (user_id, product_id)
            )
            print("已新增 history 紀錄")

        mysql.connection.commit()
        cur.close()

        return jsonify({
            **info,
            "ExpireDate": expire_date,
            "Status": status,
            "ProductType": product_type,
            "ProductID": product_id,
            "Market": market,
            "ImagePath": db_path
        }), 200

    except Exception as e:
        print("插入失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500
    
# ---------------------- 圖片存取 API ----------------------

@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_DIR, filename)

# ---------------------- AI 預測價格 API ----------------------
@app.route("/predict_price", methods=["GET"])
def predict_price_api():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT ProductID, ProName, ProPrice, Price, ExpireDate, Status, ProductType FROM product")
        rows = cur.fetchall()
        df = pd.DataFrame(rows, columns=['ProductID','ProName','ProPrice','price','ExpireDate','Status','商品大類'])        
        before = len(df)
        df = df[df['Status'] != '已過期']
        after = len(df)
        print(f"已過濾掉 {before - after} 筆已過期商品，剩下 {after} 筆需重新計算")

        df = predict_price(df, update_db=True, mysql=mysql)
        
        cur.close()
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 更新商品 API ----------------------
@app.route("/product/<int:product_id>", methods=["PUT"])
def update_product(product_id):
    data = request.get_json()
    fields = {k: v for k, v in data.items() if k in ["ProName", "ExpireDate", "Price", "ProPrice", "Market", "Status", "ProductType", "ImagePath"]}

    # 更新日期就重新計算 Status
    if "ExpireDate" in fields:
        expire_date, status = normalize_date(fields["ExpireDate"])
        fields["ExpireDate"] = expire_date
        fields["Status"] = status

    # 更新商品名稱就重新計算 ProductType
    if "ProName" in fields:
        fields["ProductType"] = detect_product_type(fields["ProName"])

    if not fields:
        return jsonify({"error": "沒有可更新的欄位"}), 400

    set_clause = ", ".join([f"{k}=%s" for k in fields.keys()])
    values = list(fields.values()) + [product_id]

    try:
        cur = mysql.connection.cursor()
        sql = f"UPDATE product SET {set_clause} WHERE productID=%s"
        cur.execute(sql, values)
        mysql.connection.commit()
        cur.close()
        print(f"已更新 Product {product_id}, 更新欄位: {fields}")
        return jsonify({"message": "更新成功", "fields": fields}), 200
    except Exception as e:
        print("更新失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 刪除商品 API ----------------------
@app.route('/product/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT ProductID FROM product WHERE ProductID=%s", (product_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "商品不存在"}), 404

        cur.execute("DELETE FROM product WHERE ProductID=%s", (product_id,))
        mysql.connection.commit()
        cur.close()

        return jsonify({"message": f"已刪除 ProductID={product_id}"}), 200
    except Exception as e:
        print("刪除商品失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500
    
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

        # 抓更新後的資料
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
        search = request.args.get("search", None)   
        date_str = request.args.get("date", None)   

        # 支援訪客模式
        if user_id == "0" or user_id.lower() == "guest":
            return jsonify({'products': []}), 200

        query = """
            SELECT p.productid, p.producttype, p.proname, p.proprice,   
                   h.created_at, p.expiredate, p.status, p.market, p.ImagePath, h.id, p.AiPrice as history_id
            FROM history h
            JOIN product p ON h.productid = p.productid
            WHERE h.userid = %s
        """
        params = [user_id]

        
        if search:
            query += " AND p.proname LIKE %s"
            params.append(f"%{search}%")

        if date_str:
            query += " AND DATE(h.created_at) = %s"
            params.append(date_str)

        query += " ORDER BY h.created_at DESC"

        cur = mysql.connection.cursor()
        cur.execute(query, tuple(params))
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
                'ImagePath': p[8],
                'HistoryID': p[9],
                'AiPrice': p[10],   
            })

        return jsonify({'products': product_list}), 200

    except Exception as e:
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

    
# ---------------------- 刪除歷史紀錄 ----------------------
@app.route('/history/<int:history_id>', methods=['DELETE'])
@jwt_required(optional=True)
def delete_history(history_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id FROM history WHERE id=%s", (history_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": f"History ID {history_id} 不存在"}), 404

        cur.execute("DELETE FROM history WHERE id=%s", (history_id,))
        mysql.connection.commit()
        cur.close()
        print(f"已刪除 history_id={history_id}")
        return jsonify({"message": f"刪除成功 (ID={history_id})"}), 200

    except Exception as e:
        print("刪除失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 儲存訪客歷史紀錄 ----------------------
@app.route('/save_guest_history', methods=['POST'])
@jwt_required()
def save_guest_history():
    user_id = int(get_jwt_identity()) 
    data = request.get_json()
    product_id = data.get('productID')

    if not product_id:
        return jsonify({"error": "缺少 productID"}), 400

    try:
        cur = mysql.connection.cursor()
        
        cur.execute(
            "SELECT id FROM history WHERE userID=%s AND productID=%s",
            (user_id, product_id)
        )
        if cur.fetchone():
            cur.close()
            return jsonify({"message": "紀錄已存在"}), 200

        cur.execute(
            "INSERT INTO history (userID, productID, created_at) VALUES (%s, %s, NOW())",
            (user_id, product_id)
        )
        history_id = cur.lastrowid
        mysql.connection.commit()
        cur.close()

        print(f"已將 ProductID={product_id} 綁定到 UserID={user_id}, HistoryID={history_id}")
        return jsonify({
            "message": "歷史紀錄儲存成功",
            "HistoryID": history_id
        }), 200

    except Exception as e:
        print("儲存訪客歷史紀錄失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 推薦商品 ----------------------

@app.route('/recommend_products/<int:product_id>', methods=['GET'])
def recommend_products(product_id):
    cur = mysql.connection.cursor()
    cur.execute(
        "SELECT Market, ProductType, ExpireDate, Reason FROM product WHERE ProductID=%s",
        (product_id,)
    )
    base = cur.fetchone()
    if not base:
        cur.close()
        return jsonify({"error": "找不到商品"}), 404

    market, ptype, exp, reason = base

    if reason == "合理":
        query = """
            SELECT *
            FROM product
            WHERE Market=%s 
            AND ExpireDate <= %s
            AND Reason='合理'
            AND Status='未過期'
            AND ProductType != %s
            ORDER BY ExpireDate ASC, ProPrice ASC
            LIMIT 6
        """
        cur.execute(query, (market, exp, ptype))
    else:
        query = """
            SELECT *
            FROM product
            WHERE Market=%s 
            AND ExpireDate <= %s
            AND ProductType=%s 
            AND Reason='合理' 
            AND Status='未過期'
            ORDER BY ExpireDate DESC, ProPrice ASC
            LIMIT 6
        """
        cur.execute(query, (market, exp, ptype))

    rows = cur.fetchall()
    column_names = [desc[0] for desc in cur.description]
    cur.close()

    products = []
    for row in rows:
        product = dict(zip(column_names, row))
        if isinstance(product.get('ExpireDate'), (datetime, date)):
            product['ExpireDate'] = product['ExpireDate'].strftime("%Y-%m-%d")
        products.append(product)

    return jsonify(products), 200

#---------------------啟動過期商品檢查----------------------
def update_product_status_once():
    """啟動時掃描所有商品的 ExpireDate，更新 Status 為 '已過期' 或 '未過期'"""
    with app.app_context():
        try:
            print("啟動時自動檢查商品過期狀態...")
            cur = mysql.connection.cursor()
            cur.execute("SELECT ProductID, ExpireDate FROM product")
            rows = cur.fetchall()

            updated_count = 0
            for pid, exp_str in rows:
                if not exp_str:
                    continue
                try:
                    exp = exp_str if isinstance(exp_str, date) else datetime.strptime(str(exp_str), "%Y-%m-%d").date()
                    status = "未過期" if exp >= date.today() else "已過期"
                    cur.execute("UPDATE product SET Status=%s WHERE ProductID=%s", (status, pid))
                    updated_count += 1
                except Exception as e:
                    print(f"更新 ProductID={pid} 狀態失敗:", e)

            mysql.connection.commit()
            cur.close()
            print(f"商品狀態更新完成，共 {updated_count} 筆")
        except Exception as e:
            print("自動更新狀態失敗:", e)

# ---------------------- 訪客登入後儲存 ----------------------

@app.route('/scan_records', methods=['POST'])
@jwt_required()
def save_scan_record():
    user_id = int(get_jwt_identity())  
    data = request.get_json()
    product_id = data.get('productId')  

    if not product_id:
        return jsonify({"error": "缺少 productId"}), 400

    try:
        cur = mysql.connection.cursor()
        
        cur.execute(
            "SELECT id FROM history WHERE userID=%s AND productID=%s",
            (user_id, product_id)
        )
        if cur.fetchone():
            cur.close()
            return jsonify({"message": "紀錄已存在"}), 200

        cur.execute(
            "INSERT INTO history (userID, productID, created_at) VALUES (%s, %s, NOW())",
            (user_id, product_id)
        )
        history_id = cur.lastrowid
        mysql.connection.commit()
        cur.close()

        print(f"已將 ProductID={product_id} 綁定到 UserID={user_id}, HistoryID={history_id}")
        return jsonify({
            "message": "歷史紀錄儲存成功",
            "HistoryID": history_id
        }), 201  

    except Exception as e:
        print("儲存掃描紀錄失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500



# ---------------------- 啟動 ----------------------
if __name__ == "__main__":
    if os.environ.get("WERKZEUG_RUN_MAIN") == "true":
        update_product_status_once()


    app.run(host='0.0.0.0', port=5000, debug=True)





