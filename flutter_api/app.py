# app.py
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
from ml_model import predict_price
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
ocr = PaddleOCR()

# 關鍵字分類
MEAT_KEYWORDS = ["豬", "牛", "雞", "羊", "腿", "排", "骨", "燒烤片", "火烤片", "肉片", "火鍋片", "絞肉"]
SEAFOOD_KEYWORDS = ["魚", "蝦", "魷", "鮭", "花枝", "章魚", "鯛", "干貝", "蛤", "牡蠣", "螺", "白管", "海帶"]
VEG_KEYWORDS = ["菜", "瓜", "果", "蔬", "蘋果", "香蕉", "橘子", "葡萄", "山藥", "豆芽", "筍", "菇", "椒", "番茄", "洋蔥", "芭樂", "蔥", "櫻桃", "秋葵", "梨", "柑", "柚"]
BAKERY_KEYWORDS = ["吐司", "麵包", "蛋糕", "可頌", "甜甜圈", "佛卡夏", "貝果", "鬆餅", "德國結", "蛋塔", "法式", "餅"]
BEAN_KEYWORDS = ["豆腐", "豆干", "豆皮", "百頁", "豆包", "素"]
READY_TO_EAT_KEYWORDS = ["三明治", "便當", "沙拉", "餃子皮", "火鍋料", "水果盤"]


# -------- 工具函數 --------
def extract_prices(texts):
    """抽取原價與即期價，支援 $ 與 元 的標籤"""
    discount_candidates = []  # $ → 折扣
    normal_candidates = []    # 元 → 原價/折扣

    for line in texts:
        # $ 開頭
        matches_dollar = re.findall(r"\$\s*(\d+)", line)
        for m in matches_dollar:
            discount_candidates.append(int(m))

        # "元" 結尾
        matches_yuan = re.findall(r"(\d+)\s*元", line)
        for m in matches_yuan:
            normal_candidates.append(int(m))

    price, pro_price = None, None
    if discount_candidates:  
        # 有 $ → 視為折扣價 (最低)，元價取最大當原價
        pro_price = min(discount_candidates)
        if normal_candidates:
            price = max(normal_candidates)
    else:
        # 沒有 $ → 用 元 最大 = 原價，最小 = 折扣
        if normal_candidates:
            price = max(normal_candidates)
            pro_price = min(normal_candidates)

    return price, pro_price


def extract_product_info(texts):
    info = {"ProName": None, "ExpireDate": None, "Price": None, "ProPrice": None}
    max_length = 0  # 用來記錄目前抓到的最長名稱
    full_text = "\n".join(texts)

    # 商品名稱：抓到有關鍵字的最長行
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
        return "海鮮"
    if any(k in name for k in VEG_KEYWORDS):
        return "蔬果"
    if any(k in name for k in BAKERY_KEYWORDS):
        return "麵包甜點"
    if any(k in name for k in BEAN_KEYWORDS):
        return "豆製品"
    if any(k in name for k in READY_TO_EAT_KEYWORDS):
        return "熟食"
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
        print("❌ 日期解析失敗:", expire_str, e)
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

    # 💡 強制存到伺服器 uploads/
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}.jpg"
    filepath = os.path.join(UPLOAD_DIR, filename)
    file.save(filepath)

    # 存到資料庫的是相對路徑
    db_path = f"/uploads/{filename}"


    # OCR 辨識
    result = ocr.predict(filepath)
    texts = []
    for item in result:
        texts.extend(item['rec_texts'])

    # 轉繁體
    from opencc import OpenCC
    cc = OpenCC('s2t')
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
        print("✅ 插入 product 成功, ProductID:", product_id)

        # 寫入 history
        print("登入 user_id:", user_id)
        if user_id:
            cur.execute(
                "INSERT INTO history (userID, productID, created_at) VALUES (%s, %s, NOW())",
                (user_id, product_id)
            )
            print("✅ 已新增 history 紀錄")

        mysql.connection.commit()
        cur.close()

        return jsonify({
            **info,
            "ExpireDate": expire_date,
            "Status": status,
            "ProductType": product_type,
            "ProductID": product_id,
            "Market": market,
            "ImagePath": db_path  # 💡 直接回傳 Flutter 路徑
        }), 200

    except Exception as e:
        print("❌ 插入失敗:", traceback.format_exc())
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
        cur.execute("SELECT ProductID, ProName, ProPrice, ExpireDate FROM product")
        rows = cur.fetchall()
        df = pd.DataFrame(rows, columns=['ProductID','ProName','ProPrice','ExpireDate'])
        
        # 這裡直接呼叫新版 predict_price
        df = predict_price(df, update_db=True, mysql=mysql)
        
        cur.close()
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 背景自動降價 ----------------------
'''def auto_update_prices(interval=300):  #更新頻率
    with app.app_context():  # ✅ 需要在 Flask app context 內操作資料庫
        while True:
            print("\n⏰ 自動降價執行中...")

            # 1️⃣ 從資料庫抓資料 (以 AI 預測價格 ProPrice 為基準)
            cur = mysql.connection.cursor()
            cur.execute("SELECT ProductID, AiPrice, ExpireDate FROM product")
            rows = cur.fetchall()
            cur.close()

            df = pd.DataFrame(rows, columns=['ProductID','AiPrice','ExpireDate'])
            
            # 2️⃣ 轉型數字 & 日期
            df['AiPrice'] = pd.to_numeric(df['AiPrice'], errors='coerce').fillna(0)
            df['ExpireDate'] = pd.to_datetime(df['ExpireDate'])

            # 3️⃣ 計算剩餘天數
            df['DaysLeft'] = (df['ExpireDate'] - pd.Timestamp.now()).dt.days.clip(lower=0)

            # 4️⃣ 計算折扣 & 降價後價格
            # 範例：剩餘天數越少，折扣越高
            df['Discount'] = df['DaysLeft'].apply(lambda x: min(0.5, max(0.05, 0.5 - x * 0.02)))
            df['CurrentPrice'] = (df['AiPrice'] * (1 - df['Discount'])).round(0).astype(int)

            # 5️⃣ 更新資料庫 AiPrice
            cur = mysql.connection.cursor()
            for _, row in df.iterrows():
                cur.execute(
                    "UPDATE product SET CurrentPrice=%s WHERE ProductID=%s",
                    (row['CurrentPrice'], row['ProductID'])
                )
            mysql.connection.commit()
            cur.close()

            print(df[['ProductID','AiPrice','CurrentPrice','DaysLeft','Discount']])
            time.sleep(interval)'''
# ---------------------- 更新商品 API ----------------------
@app.route("/product/<int:product_id>", methods=["PUT"])
def update_product(product_id):
    data = request.get_json()
    fields = {k: v for k, v in data.items() if k in ["ProName", "ExpireDate", "Price", "ProPrice", "Market", "Status", "ProductType", "ImagePath"]}

    # 如果有更新日期 → 重新計算 Status
    if "ExpireDate" in fields:
        expire_date, status = normalize_date(fields["ExpireDate"])
        fields["ExpireDate"] = expire_date
        fields["Status"] = status

    # 如果有更新商品名稱 → 重新計算 ProductType
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
        print(f"✅ 已更新 Product {product_id}, 更新欄位: {fields}")
        return jsonify({"message": "更新成功", "fields": fields}), 200
    except Exception as e:
        print("❌ 更新失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 刪除商品 API ----------------------
@app.route('/product/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    try:
        cur = mysql.connection.cursor()
        # 檢查是否存在
        cur.execute("SELECT ProductID FROM product WHERE ProductID=%s", (product_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "商品不存在"}), 404

        # 刪除該商品
        cur.execute("DELETE FROM product WHERE ProductID=%s", (product_id,))
        mysql.connection.commit()
        cur.close()

        return jsonify({"message": f"已刪除 ProductID={product_id}"}), 200
    except Exception as e:
        print("❌ 刪除商品失敗:", traceback.format_exc())
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
        search = request.args.get("search", None)   # 商品名稱 (模糊搜尋)
        date_str = request.args.get("date", None)   # 日期 YYYY-MM-DD

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

        # 商品名稱搜尋
        if search:
            query += " AND p.proname LIKE %s"
            params.append(f"%{search}%")

        # 日期篩選 (比對 history.created_at 日期)
        if date_str:
            query += " AND DATE(h.created_at) = %s"
            params.append(date_str)

        # 依掃描時間新到舊排序
        query += " ORDER BY h.created_at DESC"

        cur = mysql.connection.cursor()
        cur.execute(query, tuple(params))
        products = cur.fetchall()
        cur.close()

        # 整理回傳格式
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
        # 加檢查這筆資料是否存在
        cur.execute("SELECT id FROM history WHERE id=%s", (history_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": f"History ID {history_id} 不存在"}), 404

        # 真正刪除
        cur.execute("DELETE FROM history WHERE id=%s", (history_id,))
        mysql.connection.commit()
        cur.close()
        print(f"✅ 已刪除 history_id={history_id}")
        return jsonify({"message": f"刪除成功 (ID={history_id})"}), 200

    except Exception as e:
        print("❌ 刪除失敗:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500


# ---------------------- 推薦商品 ----------------------

@app.route('/recommend_products/<int:product_id>', methods=['GET'])
def recommend_products(product_id):
    cur = mysql.connection.cursor()
    cur.execute("SELECT Market, ProductType, ExpireDate, Reason FROM product WHERE ProductID=%s", (product_id,))
    base = cur.fetchone()
    if not base:
        cur.close()
        return jsonify({"error": "找不到商品"}), 404

    market, ptype, exp, reason = base

    if reason == "合理":
        query = """
            SELECT p1.*
            FROM product p1
            JOIN (
                SELECT ProductType, MIN(ProPrice) AS min_price
                FROM product
                WHERE Market=%s AND ExpireDate=%s AND Reason='合理' AND ProductType != %s
                GROUP BY ProductType
            ) p2 ON p1.ProductType=p2.ProductType AND p1.ProPrice=p2.min_price
        """
        cur.execute(query, (market, exp, ptype))
    else:
        query = """
            SELECT * FROM product
            WHERE Market=%s AND ExpireDate=%s AND ProductType=%s AND Reason='合理'
            ORDER BY ProPrice ASC LIMIT 6
        """
        cur.execute(query, (market, exp, ptype))

    rows = cur.fetchall()
    # ✅ 這裡先取得欄位描述
    desc = cur.description
    cur.close()

    if not desc:
        return jsonify([]), 200  # 沒有資料就回空陣列避免 TypeError

    cols = [d[0] for d in desc]
    result = [dict(zip(cols, row)) for row in rows]
    return jsonify(result), 200


# ---------------------- 啟動 ----------------------
# 你的 auto_update_prices 函式定義在這裡
if __name__ == '__main__':

    # 啟動背景自動降價 Thread
    '''thread = threading.Thread(target=auto_update_prices, args=(300,), daemon=True) #更新頻率
    thread.start()'''

    app.run(host='0.0.0.0', port=5000, debug=True)

