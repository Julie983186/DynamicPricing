//ML.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
import re
import joblib

# -----------------------------
# 1️讀取資料
# -----------------------------
df = pd.read_csv("畢業專題田野調查.csv", encoding="utf-8-sig")
# -----------------------------
# 🔹將剩餘保存期限(天) + 時間細化成小時
# -----------------------------

def compute_remaining_hours(row):
    # 剩餘保存期限（天轉小時）
    hours = row['剩餘保存期限'] * 24

    # 從時間欄位中取出「結束時間」的時數
    time_str = str(row['時間'])
    match = re.search(r'(\d{1,2}):\d{2}-(\d{1,2}):\d{2}', time_str)
    if match:
        end_hour = int(match.group(2))
    else:
        end_hour = 0  # 防呆

    # 計算今日剩下幾小時（假設每天24:00結束）
    remaining_today = 24 - end_hour

    # 總剩餘時間（單位：小時）
    total_hours = hours + remaining_today
    return total_hours

# 新增欄位：剩餘保存期限_小時
df['剩餘保存期限_小時'] = df.apply(compute_remaining_hours, axis=1)

print(df[['時間', '剩餘保存期限', '剩餘保存期限_小時']].head())
# -----------------------------
# 2️規則型折扣
# -----------------------------
def calc_rule_discount(row):
    hours = row['剩餘保存期限_小時']  # ✅ 改用小時計算

    if row['商品大類'] == '肉類':
        if hours <= 6: return 0.6
        elif hours <= 12: return 0.45
        elif hours <= 24: return 0.3
        elif hours <= 48: return 0.15
        else: return 0

    elif row['商品大類'] == '魚類':
        if hours <= 6: return 0.5
        elif hours <= 12: return 0.35
        elif hours <= 24: return 0.25
        elif hours <= 48: return 0.1
        else: return 0

    elif row['商品大類'] == '蔬果類':
        if hours <= 6: return 0.45
        elif hours <= 12: return 0.3
        elif hours <= 24: return 0.2
        elif hours <= 48: return 0.1
        else: return 0

    elif row['商品大類'] == '麵包甜點類':
        if hours <= 6: return 0.4
        elif hours <= 12: return 0.25
        elif hours <= 24: return 0.15
        elif hours <= 48: return 0.05
        else: return 0

    elif row['商品大類'] == '豆製品類':
        if hours <= 6: return 0.35
        elif hours <= 12: return 0.25
        elif hours <= 24: return 0.15
        elif hours <= 48: return 0.05
        else: return 0

    elif row['商品大類'] == '熟食/其他':
        if hours <= 6: return 0.3
        elif hours <= 12: return 0.2
        elif hours <= 24: return 0.1
        elif hours <= 48: return 0.05
        else: return 0

    elif row['商品大類'] == '其他':
        if hours <= 6: return 0.25
        elif hours <= 12: return 0.15
        elif hours <= 24: return 0.1
        elif hours <= 48: return 0.05
        else: return 0

    else:
        return 0



df['折扣規則'] = df.apply(calc_rule_discount, axis=1)
df['售價規則'] = df['原價'] * (1 - df['折扣規則'])

# -----------------------------
# 3️準備機器學習特徵
# -----------------------------
# 將商品大類轉為 One-Hot
# 對所有類別欄位做 One-Hot
df = pd.get_dummies(df, columns=['商品大類', '停車狀況', '人流量', '天氣'])
cols = [c for c in df.columns if '_' in c]
df[cols] = df[cols].fillna(0).astype(int)

# 特徵欄位
feature_cols = ['剩餘保存期限_小時','原價','當下溫度','貨架上庫存量'] \
               + [c for c in df.columns if c.startswith('商品大類_')] \
               + [c for c in df.columns if c.startswith('停車狀況_')] \
               + [c for c in df.columns if c.startswith('人流量_')] \
               + [c for c in df.columns if c.startswith('天氣_')]

X = df[feature_cols]
y = df['折扣規則']  # 監督學習目標：學規則折扣

# -----------------------------
# 4️拆分訓練/測試集
# -----------------------------
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# -----------------------------
# 5️訓練 Random Forest
# -----------------------------
model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# 預測
y_pred = model.predict(X_test)
print("MSE:", mean_squared_error(y_test, y_pred))

# -----------------------------
# 6️用模型預測折扣
# -----------------------------
df['折扣預測'] = model.predict(X[feature_cols])
df['售價預測'] = df['原價'] * (1 - df['折扣預測'])
df['折扣預測'] = df['折扣預測'].round(2)
df['售價預測'] = df['售價預測'].round(0)
# -----------------------------
# 7️查看結果
# -----------------------------
print(df[['商品品項','剩餘保存期限_小時','折扣規則','售價規則','折扣預測','售價預測']])

# -----------------------------
# 8️存檔
# -----------------------------
#df.to_csv("dynamic_pricing_result.csv", index=False)
output_path = "dynamic_pricing_result.csv"
df.to_csv(output_path, index=False, encoding="utf-8-sig")
print("已存檔：dynamic_pricing_result.csv")

# 儲存模型
model_path = "random_forest_model.pkl"
joblib.dump(model, model_path)
print("模型已儲存：", model_path)
----------------------------------------------------------------
//ml_model.py
import pandas as pd
import joblib
import numpy as np

try:
    model = joblib.load("random_forest_model.pkl")
    feature_cols = model.feature_names_in_
except:
    feature_cols = ['剩餘保存期限_分鐘','原價',
                    '人流量_少', '人流量_一般', '人流量_多',
                    '天氣_晴天', '天氣_陰天', '天氣_雨天',
                    '停車狀況_少', '停車狀況_一般', '停車狀況_多',
                    '商品大類_肉類','商品大類_魚類','商品大類_蔬果類','商品大類_其他']
    class FakeModel:
        def predict(self, X):
            return np.random.rand(len(X)) * 0.5
    model = FakeModel()

def prepare_features(df):
    df = df.copy()
    #商品名稱
    if 'ProName' not in df.columns:
        df['ProName'] = '未知商品'

    # 原價
    if '原價' not in df.columns:
        if 'price' in df.columns:
            df['原價'] = df['price']
        elif 'ProPrice' in df.columns:
            df['原價'] = df['ProPrice']
        else:
            df['原價'] = 0

    # 剩餘保存期限（分鐘）
    if 'ExpireDate' in df.columns:
        now = pd.Timestamp.now()
        df['剩餘保存期限_小時'] = (
            pd.to_datetime(df['ExpireDate'], errors='coerce') - now
        ).dt.total_seconds().div(60).clip(lower=0)
    else:
        df['剩餘保存期限_小時'] = 0

    # 🟢 自動補上預設特徵（讓模型欄位齊全）
    df['人流量'] = '一般'
    df['天氣'] = '晴天'
    df['停車狀況'] = '一般'

    # 商品大類 → ProductType
    if '商品大類' not in df.columns and 'ProductType' in df.columns:
        df['商品大類'] = df['ProductType']
    elif '商品大類' not in df.columns:
        df['商品大類'] = '其他'

    # one-hot encode
    df = pd.get_dummies(df, columns=['人流量', '天氣', '停車狀況', '商品大類'])

    # 補上模型要求但不存在的欄位
    for col in feature_cols:
        if col not in df.columns:
            df[col] = 0
            
    return df[feature_cols]


def predict_price(df):
    X = prepare_features(df)
    y_pred = model.predict(X)
    df['AI折扣'] = y_pred.round(2)
    # 🟢 確保價格是數字
    df['ProPrice'] = pd.to_numeric(df['ProPrice'], errors='coerce').fillna(0)
    df['AiPrice'] = (df['ProPrice'] * (1 - df['AI折扣'])).round(0).astype(int)
    # 回傳結果時
    result = df[['ProName','AI折扣','AiPrice']].to_dict(orient='records')
    return df
----------------------------------------------------------------
//app.py
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
        cur.execute("SELECT ProductID, ProName, ProPrice, ExpireDate, Status, Market, ProductType, price, ImagePath FROM product")
        rows = cur.fetchall()
        cur.close()
        df = pd.DataFrame(rows, columns=['ProductID', 'ProName', 'ProPrice', 'ExpireDate', 'Status', 'Market', 'ProductType', 'price', 'ImagePath'])
        #df = get_product_df()
        df = predict_price(df)  # 預測結果會有 'AI折扣' 與 'aiPrice'

        # 更新資料庫 aiPrice
        cur = mysql.connection.cursor()
        for _, row in df.iterrows():
            cur.execute("UPDATE product SET AiPrice=%s WHERE ProductID=%s", (row['AiPrice'], row['ProductID']))
        mysql.connection.commit()
        cur.close()

        # 只回傳 ProName + aiPrice 給前端使用
        data = df[['ProName', 'AiPrice']].rename(columns={'ProName':'ProName'}).to_dict(orient="records")
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500

# ---------------------- 背景自動降價 ----------------------
def auto_update_prices(interval=300):  #更新頻率
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
            time.sleep(interval)
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

# ---------------------- 最新商品 ----------------------
'''
@app.route("/latest_product", methods=["GET"])
def latest_product():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT productid, ProName, ExpireDate, Price, ProPrice, Market, Status, ProductType, ImagePath FROM product ORDER BY productid DESC LIMIT 1")
        row = cur.fetchone()
        cur.close()
        if row:
            return jsonify({
                "ProductID": row[0],
                "ProName": row[1],
                "ExpireDate": row[2].strftime('%Y-%m-%d') if row[2] else None,
                "Price": row[3],
                "ProPrice": row[4],
                "Market": row[5],
                "Status": row[6],
                "ProductType": row[7],
                "ImagePath": row[8],
            }), 200
        return jsonify({"error": "No product found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500
'''
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
                   h.created_at, p.expiredate, p.status, p.market, p.ImagePath, h.id as history_id
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
                'HistoryID': p[9],   # 新增：用來刪除 history 紀錄
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

# ---------------------- 啟動 ----------------------
# 你的 auto_update_prices 函式定義在這裡
if __name__ == '__main__':

    # 啟動背景自動降價 Thread
    thread = threading.Thread(target=auto_update_prices, args=(300,), daemon=True) #更新頻率
    thread.start()

    app.run(host='0.0.0.0', port=5000, debug=True)
-----------------------------------------------------------
//main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import pages
import 'pages/splash_screen.dart'; 
import 'pages/scanning_picture_page.dart';
import 'pages/recognition_loading_page.dart';
import 'pages/recognition_result_page.dart';
import 'pages/recognition_edit_page.dart';
import 'pages/register_login_page.dart';
import 'pages/member_history_page.dart';
import 'pages/counting.dart';
import 'pages/countingresult.dart';
import 'pages/adviceproduct.dart';
import 'pages/member_profile_page.dart'; 
import 'pages/member_edit_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '碳即',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),

      // localization (保持不變)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en', 'US'),
      ],

      // 應用程式永遠從 /splash 啟動
      initialRoute: '/splash',
      routes: {
        // ------------------ 啟動畫面路由 ------------------
        '/splash': (context) => const SplashScreen(),

        // ------------------ 會員相關路由 ------------------
        '/login': (context) => const RegisterLoginPage(), 

        // 注意：/member_history 可能也需要修改，因為它的參數也是硬編碼的
        '/member_history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberHistoryPage(
            userId: args['userId'],
            userName: args['userName'],
            token: args['token'],
          );
        },


        '/member_profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberProfilePage(
            userId: args['userId'],
            userName: args['userName'],
            token: args['token'],
          );
        },
        
        '/member_edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberEditPage(
            userId: args['userId'],
            userName: args['userName'],
            phone: args['phone'],
            email: args['email'],
            token: args['token'],
          );
        },

        // ------------------ 掃描與識別路由 (保持不變) ------------------
        '/scan': (context) => ScanningPicturePage(),
        '/counting': (context) => LoadingPage(),
        '/countingResult': (context) => CountingResult(),
        '/loading': (context) => RecognitionLoadingPage(),
        '/resultCheck': (context) => RecognitionResultPage(),
        '/edit': (context) => RecognitionEditPage(),

        // ------------------ 推薦商品路由 (保持不變) ------------------
        '/advice_product': (context) => Scaffold(
          appBar: AppBar(title: const Text('推薦商品')),
          body: AdviceProductList(
            scrollController: ScrollController(),
          ),
        ),
      },
    );
  }
}
---------------------------------------------------
//api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb

/// ------------------ 全域 IP 設定 ------------------
class ApiConfig {
  static const String baseUrl = 'http://192.168.0.129:5000'; 
}
/// ------------------ 註冊 ------------------
Future<bool> registerUser(String name, String phone, String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('註冊成功');
      return true;
    } else {
      print('註冊失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 登入 ------------------
/// 回傳 id, name, token
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("login success data = $data");
      return {
        'id': data['user']['id'],
        'name': data['user']['name'],
        'token': data['token'], // ✅ JWT token
      };
    } else {
      print('登入失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 抓取會員資料 ------------------
/// 需要帶 token
Future<Map<String, dynamic>?> fetchUserData(int userId, String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('取得會員資料失敗: ${response.body}');
      return null;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return null;
  }
}

/// ------------------ 更新會員資料 ------------------
/// 需要帶 token
Future<bool> updateUserData({
  required int userId,
  required String token,
  String? name,
  String? email,
  String? phone,
  String? password,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

  final Map<String, dynamic> body = {};
  if (name != null) body['name'] = name;
  if (email != null) body['email'] = email;
  if (phone != null) body['phone'] = phone;
  if (password != null) body['password'] = password;

  if (body.isEmpty) {
    print('沒有可更新的欄位');
    return false;
  }

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ 加 token
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('更新成功: ${response.body}');
      return true;
    } else {
      print('更新失敗: ${response.body}');
      return false;
    }
  } catch (e) {
    print('連線錯誤: $e');
    return false;
  }
}

/// ------------------ 註冊畫面 ------------------
class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: '電話')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: '密碼'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await registerUser(
                  nameController.text,
                  phoneController.text,
                  emailController.text,
                  passwordController.text,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('註冊成功')),
                  );
                }
              },
              child: const Text('註冊'),
            )
          ],
        ),
      ),
    );
  }
}

/// ------------------ 抓取會員歷史商品紀錄 ------------------
/// 需要帶 token，可選擇帶日期（dateString）
Future<List<dynamic>> fetchHistoryProducts(
  int userId,
  String? token, {
  String? dateString,
}) async {
  try {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/get_products/$userId' +
          (dateString != null ? '?date=$dateString' : ''),
    );

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      } else {
        print('回傳資料格式錯誤: $data');
        return [];
      }
    } else {
      print('取得歷史紀錄失敗: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    print('連線錯誤: $e');
    return [];
  }
}
/// ------------------ 抓取單筆商品 AI 價格 ------------------
Future<double?> fetchAIPrice(int productId) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/predict_price');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      // 改用 ProductID 找對應商品
      final match = data.firstWhere(
        (item) => item['ProductID'] == productId,
        orElse: () => null,
      );

      if (match != null) {
        return (match['AiPrice'] as num).toDouble();
      } else {
        debugPrint("找不到對應商品的 AI 價格: ProductID=$productId");
        return null;
      }
    } else {
      debugPrint("抓 AI 價格失敗: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("抓 AI 價格失敗: $e");
    return null;
  }
}
---------------------------------------------------
//register_login_page.dart
import 'package:flutter/material.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import 'countingresult.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';

// 定義會員頁面的淺綠色背景
const Color _kLightGreenBg = Color(0xFFE8F5E9);

// 註冊與登入頁面
class RegisterLoginPage extends StatefulWidget {
  const RegisterLoginPage({super.key});

  @override
  State<RegisterLoginPage> createState() => _RegisterLoginPageState();
}

class _RegisterLoginPageState extends State<RegisterLoginPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/login'); // 記錄當前頁面
  }

  // Logo 區塊 Helper
  Widget _buildLogo() {
    return SizedBox(
      height: 150,
      width: 300,
      child: Image.asset(
        'assets/logo.png',
        width: 300,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _kLightGreenBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  _buildLogo(),
                  const SizedBox(height: 20),
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        TabBar(
                          labelColor: Colors.black,
                          indicatorColor: Colors.green,
                          tabs: [
                            Tab(text: '註冊會員'),
                            Tab(text: '會員登入'),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 450, // 可根據內容調整高度
                          child: TabBarView(
                            children: [
                              RegisterForm(),
                              LoginForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 輔助函式: 建立文字輸入框
Widget buildTextField(String label,
    {bool obscureText = false, TextEditingController? controller}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );
}

// --- 註冊表單 (RegisterForm) ---
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submitRegister() async {
    try {
      bool isSuccess = await registerUser(
        nameController.text,
        phoneController.text,
        emailController.text,
        passwordController.text,
      );

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊成功！請重新登入'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 2));
        DefaultTabController.of(context)?.animateTo(1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('註冊失敗，請重試。'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 上半部分: 輸入欄位
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('姓名', controller: nameController),
            buildTextField('電話', controller: phoneController),
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        // 下半部分: 按鈕
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '註冊',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanningPicturePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF274E13)),
              ),
              child: const Text(
                '以訪客身份使用',
                style: TextStyle(color: Color(0xFF274E13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- 登入表單 (LoginForm) ---
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submitLogin() async {
    final user = await loginUser(
      emailController.text,
      passwordController.text,
    );

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanningPicturePage(
            userId: user['id'] as int,
            userName: user['name'] as String,
            token: user['token'] as String,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登入失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 上半部分: Email / 密碼
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTextField('Email', controller: emailController),
            buildTextField('密碼', controller: passwordController, obscureText: true),
          ],
        ),
        // 下半部分: 按鈕
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '登入',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanningPicturePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF274E13)),
              ),
              child: const Text(
                '以訪客身份使用',
                style: TextStyle(color: Color(0xFF274E13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

---------------------------------------------------
//scanning_picture_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/route_logger.dart';
import 'recognition_loading_page.dart';
import 'member_profile_page.dart';
import 'register_login_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';



class ScanningPicturePage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const ScanningPicturePage({
    Key? key,
    this.userId,
    this.userName,
    this.token,
  }) : super(key: key); 

  @override
  _ScanningPicturePageState createState() => _ScanningPicturePageState();
}

class _ScanningPicturePageState extends State<ScanningPicturePage>
    with TickerProviderStateMixin {
  late Future<CameraController> _cameraControllerFuture;
  late AnimationController _animationController;
  bool _isFlashing = false;
  bool _isUploading = false;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/scan');
    _cameraControllerFuture = _initCameraController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<CameraController> _initCameraController() async {
    // 要求權限
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception("相機權限未允許");
    }

    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxContentWidth = 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 90, // 整體 AppBar 高度
        title: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5), // 控制上下距離
            child: Image.asset(
              'assets/logo.png',
              height: 90, // 固定 Logo 高度
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

 

      body: Container(
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _buildTopUI(),
                Expanded(
                  child: FutureBuilder<CameraController>(
                    future: _cameraControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text("無法初始化相機"));
                      }
                      final controller = snapshot.data!;
                      return _buildOverlayStack(controller);
                    },
                  ),
                ),
                _buildBottomUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        if (widget.userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberProfilePage(
                                userId: widget.userId!,
                                userName: widget.userName ?? "會員",
                                token: widget.token ?? "",
                              ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("需要登入"),
                                content: const Text("請先登入或註冊以使用會員功能"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("取消"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterLoginPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text("登入/註冊"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_circle,
                            color: Colors.white, size: 25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userId != null ? widget.userName ?? "會員" : "訪客",
                    style: const TextStyle(
                        color: Color(0xFF388E3C), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(child: _buildStoreDropdown()),
            ],
          ),
          const SizedBox(height: 10),
          _buildCurrentStoreInfo(),
        ],
      ),
    );
  }

  Widget _buildStoreDropdown() {
    final List<String> stores = ['家樂福', '全聯', '愛買', '大全聯'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStore,
          hint: const Text('請選擇賣場', style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStore = newValue;
            });
          },
          items: stores.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentStoreInfo() {
    return Text(
      _selectedStore != null ? '目前賣場：$_selectedStore' : '尚未選擇賣場',
      style: const TextStyle(
        color: Color.fromARGB(221, 239, 41, 41),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverlayStack(CameraController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        //_buildScanMask(),
        _buildScanLine(),
        _buildHintText(),
        if (_isFlashing) Container(color: Colors.white.withOpacity(0.7)),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  /*
  Widget _buildScanMask() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        const Color(0xFFE8F5E9).withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 320,
                height: 900,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _buildScanLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          const double scanLineWidth = 320 * 0.8;
          return Transform.translate(
            offset: Offset(0, -125 + _animationController.value * 250),
            child: Container(
              width: scanLineWidth,
              height: 3,
              color: Colors.greenAccent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHintText() {
    return const Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Text(
        '請對準產品名稱、價格與有效期限',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: FutureBuilder<CameraController>(
          future: _cameraControllerFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _takePicture(snapshot.data!),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                  color: Colors.green,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 30),
              ),
            );
          },
        ),
      ),
    );
  }

  void _takePicture(CameraController controller) async {
    try {
      // 停止動畫效果，並顯示閃光效果
      _animationController.stop();
      setState(() => _isFlashing = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _isFlashing = false);

      // 拍照
      final image = await controller.takePicture();
      print('臨時照片路徑: ${image.path}');

      // -------- 儲存到永久資料夾 --------
      final appDir = await getApplicationDocumentsDirectory(); // App Documents 路徑
      final scansDir = Directory('${appDir.path}/scans');

      // 如果資料夾不存在，則建立
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
        print('建立資料夾: ${scansDir.path}');
      }

      // 產生唯一檔名，避免覆蓋
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${scansDir.path}/$fileName');

      print('照片已永久儲存至: ${savedImage.path}');

      // -------- 導入 RecognitionLoadingPage --------
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecognitionLoadingPage(
            userId: widget.userId,
            userName: widget.userName,
            token: widget.token,
            imagePath: savedImage.path, // 使用永久路徑
            market: _selectedStore,     // 傳入選擇的賣場
          ),
        ),
      );
    } catch (e) {
      print('拍照或儲存失敗: $e');
    } finally {
      _animationController.repeat(reverse: true);
    }
  }
}

---------------------------------------------------
//recognition_loading_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../services/route_logger.dart';
import 'package:http/http.dart' as http;
import 'recognition_result_page.dart';
import 'dart:io';
import '../services/api_service.dart';

class RecognitionLoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final String? market; // 👈 保留傳入的賣場名稱

  const RecognitionLoadingPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.market,
  });

  @override
  State<RecognitionLoadingPage> createState() => _RecognitionLoadingPageState();
}

class _RecognitionLoadingPageState extends State<RecognitionLoadingPage> {
  // 用於在失敗時更新 UI，顯示錯誤訊息
  String _statusMessage = "請稍待";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // 呼叫實際的 OCR 處理功能
    _processImage();
    saveCurrentRoute('/loading'); 
  }

  // 核心功能：處理圖片上傳和 OCR 請求
  Future<void> _processImage() async {
    try {
      // 確保 imagePath 不為 null
      if (widget.imagePath == null) {
        throw Exception("Image path is null.");
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ocr'),
      );

      // 1. 上傳圖片檔案
      request.files.add(
        await http.MultipartFile.fromPath('image', widget.imagePath!),
      );
      
      // 2. 帶入 market 欄位
      request.fields['market'] = widget.market ?? '未知賣場';

      // 3. 帶入 JWT Token
      if (widget.token != null) {
        request.headers['Authorization'] = 'Bearer ${widget.token}';
      }

      // 4. 發送請求並等待回應
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final productInfo = json.decode(respStr);
      print(productInfo);
      
      // 5. 處理成功或失敗
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        // 成功，導航到結果頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecognitionResultPage(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: productInfo,
            ),
          ),
        );
      } else {
        // 伺服器回傳錯誤狀態碼
        _handleError("伺服器回應失敗: ${response.statusCode}");
      }

    } catch (e) {
      // 網路連線或其他例外錯誤
      _handleError("❌ OCR 處理失敗: $e");
    }
  }
  
  // 錯誤處理函式
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isError = true;
        _statusMessage = message;
      });
      // 失敗後，延遲幾秒讓使用者看到錯誤，然後返回上一頁 (可選)
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO (使用新樣式的圖片)
            Image.asset(
              'assets/logo.png',
              height: 140,
            ),
            const SizedBox(height: 40),

            // 狀態文字
            Text(
              _isError ? '辨識失敗' : '辨識進行中...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isError ? Colors.red : const Color.fromARGB(255, 0, 0, 0), // 失敗時變紅
              ),
            ),
            const SizedBox(height: 10),
            
            // 進度或錯誤訊息
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // loading indicator
            _isError
                ? const Icon(Icons.error_outline, color: Colors.red, size: 50) // 失敗時顯示錯誤圖示
                : const CircularProgressIndicator(color: Color(0xFF388E3C)), // 正常時顯示綠色進度條
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//recognition_result_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/route_logger.dart';
import 'counting.dart'; // ✅ 導向目標
import 'scanning_picture_page.dart';
import 'recognition_edit_page.dart';
import 'recognition_loading_page.dart'; 

class RecognitionResultPage extends StatelessWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  static const Color _lightGreenBackground = Color(0xFFE8F5E9);

  const RecognitionResultPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  Widget build(BuildContext context) {
    saveCurrentRoute('/resultCheck');

    final name = productInfo?["ProName"] ?? "未知商品";
    final date = productInfo?["ExpireDate"] ?? "未知日期";
    final price = productInfo?["Price"] ?? "未知價格";
    final proprice = productInfo?["ProPrice"] ?? "未知優惠";
    final market = productInfo?["Market"] ?? "未知賣場";

    return Scaffold(
      backgroundColor: _lightGreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // 拍攝的圖片 (如果有)
            if (imagePath != null)
              Image.file(File(imagePath!), height: 200, fit: BoxFit.contain)
            else
              Image.asset('assets/milk.jpg', height: 200, fit: BoxFit.contain),
            const SizedBox(height: 20),

            // 商品資訊
            Text("商品名稱：$name",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("有效期限：$date",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("原價：$price",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("即期價格：$proprice",
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text("賣場：$market",
                style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 驗證文字
            const Text(
              '產品名稱及有效期限是否正確？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 「正確」按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoadingPage( // or CountingPage
                      userId: userId,
                      userName: userName,
                      token: token,
                      imagePath: imagePath,
                      productInfo: productInfo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('正確', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「手動修改」按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognitionEditPage(
                      userId: userId,
                      userName: userName,
                      token: token,
                      imagePath: imagePath,
                      productInfo: productInfo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 157, 92),
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  const Text('手動修改', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // 「重新掃描」按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanningPicturePage(
                      userId: userId,
                      userName: userName,
                      token: token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 138, 179),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('重新掃描',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//recognition_edit_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'recognition_result_page.dart';
import '../services/api_service.dart';

// 注意：原程式碼中引用了 RecognitionLoadingPage，
// 但在 RecognitionEditPage 類別中並未導入。
// 為了程式碼的完整性，我會暫時使用 RecognitionResultPage 替換，
// 但建議您檢查並確認 RecognitionLoadingPage 的路徑。
// 為了遵循原程式碼邏輯，我將其改為 _updateProduct 方法中正確的導航邏輯。

class RecognitionEditPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const RecognitionEditPage({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  State<RecognitionEditPage> createState() => _RecognitionEditPageState();
}

class _RecognitionEditPageState extends State<RecognitionEditPage> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  static const Color _primaryGreen = Colors.green;

  late TextEditingController nameController;
  late TextEditingController dateController;
  // 注意：原程式碼中這裡有 priceController, proPriceController, marketController
  // 您的需求程式碼中用了 originalPriceController, discountPriceController, 但少了 Market。
  // 為保持與 initState 和 _updateProduct 的一致性，我使用原始的名稱。
  late TextEditingController priceController;
  late TextEditingController proPriceController;
  late TextEditingController marketController; 

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/edit');
    nameController = TextEditingController(text: widget.productInfo?["ProName"]);
    dateController = TextEditingController(text: widget.productInfo?["ExpireDate"]);
    priceController = TextEditingController(text: widget.productInfo?["Price"]?.toString());
    proPriceController = TextEditingController(text: widget.productInfo?["ProPrice"]?.toString());
    marketController = TextEditingController(text: widget.productInfo?["Market"]);
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    priceController.dispose();
    proPriceController.dispose();
    marketController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    final productId = widget.productInfo?["ProductID"];
    if (productId == null) return;

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/product/$productId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ProName": nameController.text,
        "ExpireDate": dateController.text,
        "Price": int.tryParse(priceController.text),
        "ProPrice": int.tryParse(proPriceController.text),
        "Market": marketController.text,
      }),
    );

    if (res.statusCode == 200) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecognitionResultPage(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: {
                "ProductID": productId,
                "ProName": nameController.text,
                "ExpireDate": dateController.text,
                "Price": priceController.text,
                "ProPrice": proPriceController.text,
                "Market": marketController.text,
              },
            ),
          ),
        );
      }
    } else {
      // 建議在實際 APP 中使用 ScaffoldMessenger 顯示錯誤
      print("更新失敗: ${res.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _standardBackground,
      // 💡 關鍵修正一：允許 Scaffold 自動調整佈局以避免鍵盤彈出時的溢位
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        // 💡 關鍵修正二：使用 SingleChildScrollView 包裹整個內容
        child: SingleChildScrollView(
          // reverse: true, // reverse: true 較適合聊天應用，對表單來說，預設滾動通常更自然
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
          child: Column(
            // 💡 關鍵修正三：為了讓鍵盤彈出時能看到輸入框，我們需要添加一個空間
            // 這樣即使鍵盤彈出，也不會遮擋住最後一個輸入框和按鈕。
            // 由於 SingleChildScrollView 本身能捲動，這裡不需要 reverse: true
            children: [
              // 返回按鈕靠左，LOGO 居中
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back_ios, color: _primaryGreen),
                    ),
                  ),
                  // Logo 
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 顯示圖片
              if (widget.imagePath != null)
                Image.file(File(widget.imagePath!), height: 200, fit: BoxFit.contain),
              // 注意：原程式碼中使用 Image.file(File(widget.imagePath!))
              // 您提供的範例程式碼中使用 Image.asset('assets/milk.jpg')
              // 這裡以您的原邏輯為主：
              // if (widget.imagePath != null)
              //   Image.file(File(widget.imagePath!), height: 200, fit: BoxFit.contain),

              const SizedBox(height: 20),

              // --- 輸入欄位 ---
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '商品名稱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: '有效期限 (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: priceController, // 使用原始的 priceController
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '原價',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: proPriceController, // 使用原始的 proPriceController
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '優惠價', // 使用原始的 '優惠價'
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: marketController,
                decoration: const InputDecoration(
                  labelText: '賣場',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- 送出按鈕 ---
              ElevatedButton(
                onPressed: _updateProduct, // 點擊送出後執行更新 API
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  '送出',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
---------------------------------------------------
//counting.dart
import 'package:flutter/material.dart';
import 'dart:async'; // 確保引入 dart:async
import '../services/route_logger.dart';
import 'countingresult.dart';
import 'dart:io';

class LoadingPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const LoadingPage({super.key, this.userId, this.userName, this.token, this.imagePath, this.productInfo});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/counting'); // 記錄當前頁面
    
    // 🎯 保持原始邏輯：模擬計算，2秒後跳轉到結果頁
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { 
        // 使用 pushReplacement 較佳，但為保持原邏輯，這裡使用 push
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountingResult(
              userId: widget.userId,
              userName: widget.userName,
              token: widget.token,
              imagePath: widget.imagePath,
              productInfo: widget.productInfo,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // 背景色保持不變
      body: Center( // 🎯 移除 SafeArea，直接使用 Center
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              'assets/logo.png', // 您的 Logo 圖片路徑
              height: 140, // 🎯 調整圖片高度為 140
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40), // 🎯 調整間距為 40

            // 標題文字
            const Text(
              '價格計算中...', // 保持原始文字
              style: TextStyle(
                fontSize: 20, // 🎯 調整字體大小為 20
                fontWeight: FontWeight.bold, // 🎯 調整字體粗細為 bold
                color: Colors.black, // 🎯 調整文字顏色為黑色
              ),
            ),
            const SizedBox(height: 10),
            
            // 副標題文字
            const Text(
              '請稍待',
              style: TextStyle(
                fontSize: 16, // 🎯 調整字體大小為 16
                color: Colors.black54, // 🎯 調整文字顏色為 Colors.black54
              ),
            ),
            const SizedBox(height: 30), // 🎯 調整間距為 30

            // 🎯 loading indicator
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//countingresult.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'adviceproduct.dart';
import '../services/route_logger.dart';
import 'register_login_page.dart';
import 'member_profile_page.dart';
import 'scanning_picture_page.dart';
import '../services/api_service.dart';

class CountingResult extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;
  final String? imagePath;
  final Map<String, dynamic>? productInfo;

  const CountingResult({
    super.key,
    this.userId,
    this.userName,
    this.token,
    this.imagePath,
    this.productInfo,
  });

  @override
  State<CountingResult> createState() => _CountingResultState();
}

class _CountingResultState extends State<CountingResult> {
  static const Color _standardBackground = Color(0xFFE8F5E9);
  bool _hasShownGuestDialog = false;
  double? AiPrice; // <-- 這裡存從 API 拿到的 AI 價格

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/countingResult');

    _fetchAIPrice(); // 初始化時抓 AI 價格
  }

  bool _isGuest() => widget.userId == null || widget.token == null;

  Future<void> _saveScanRecord() async {
    debugPrint('掃描紀錄已儲存（範例）');
  }

  Future<void> _discardScanRecord() async {
    debugPrint('掃描紀錄已捨棄（範例）');
  }

  void _showGuestDialog() {
    if (_hasShownGuestDialog) return;
    _hasShownGuestDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("提示"),
          content: const Text("您目前是訪客身分，要不要保留這筆掃描紀錄？若保留請註冊登入會員"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _discardScanRecord();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanningPicturePage(
                        userId: widget.userId,
                        userName: widget.userName,
                        token: widget.token,
                      ),
                    ),
                  );
                }
              },
              child: const Text("不保留"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterLoginPage()),
                );
                if (result == true) {
                  await _saveScanRecord();
                }
              },
              child: const Text("保留"),
            ),
          ],
        );
      },
    ).then((_) {
      _hasShownGuestDialog = false;
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("需要登入"),
          content: const Text("請先登入或註冊以使用會員功能"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("取消"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterLoginPage()),
                );
              },
              child: const Text("登入/註冊"),
            ),
          ],
        );
      },
    );
  }
  /// -------------------------- 抓 AI 價格 --------------------------
Future<void> _fetchAIPrice() async {
  final productId = widget.productInfo?["ProductID"];
  if (productId == null) return;

  final value = await fetchAIPrice(productId); // API 回傳 AiPrice
  if (mounted && value != null) {
    setState(() {
      AiPrice = value;
    });
  }
}

  /// -------------------------- Build --------------------------
  @override
  Widget build(BuildContext context) {
    final info = widget.productInfo ?? {};
    final name = info["ProName"] ?? "未知商品";
    final expireDate = info["ExpireDate"] ?? "未知日期";
    final price = info["Price"]?.toString() ?? "未知";
    final proPrice = info["ProPrice"]?.toString() ?? "未知";
    //const aiPrice = "300";

    return Scaffold(
      backgroundColor: _standardBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 250),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 左上角會員 / 訪客 icon
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_isGuest()) {
                                _showLoginRequiredDialog();
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/member_profile',
                                  arguments: {
                                    'userId': widget.userId!,
                                    'userName': widget.userName!,
                                    'token': widget.token!,
                                  },
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF388E3C).withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_circle,
                                      color: Colors.white, size: 25),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isGuest() ? "訪客" : (widget.userName ?? "會員"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 中間 LOGO
                        Image.asset(
                          'assets/logo.png',
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                        // 右上角再次掃描 icon
                        Material(
                          color: const Color.fromARGB(0, 0, 0, 0),
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_isGuest()) {
                                _showGuestDialog();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScanningPicturePage(
                                      userId: widget.userId,
                                      userName: widget.userName,
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.fullscreen,
                                  size: 30, color: Color.fromARGB(221, 38, 92, 31)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 商品卡片
                  Container(
                    width: 330,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (widget.imagePath != null)
                          Container(
                            width: 220,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Image.file(
                              File(widget.imagePath!),
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const SizedBox(height: 200),
                        const SizedBox(height: 12),
                        Text("商品名稱：$name",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text("有效期限：$expireDate",
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("原價：\$$price",
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("即期價格：\$$proPrice",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.red)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildPriceBox("即期價格", "\$$proPrice",
                                isDiscount: false),
                            buildPriceBox("AI定價", AiPrice != null
                                    ? "\$${AiPrice!.toInt()}"
                                    : "計算中...",
                                isDiscount: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "‼ 目前價格落於合理範圍 ‼",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // 推薦商品
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: AdviceProductList(scrollController: scrollController),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPriceBox(String title, String price,
      {bool isDiscount = false}) {
    return SizedBox(
      width: 130,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDiscount ? Colors.orange.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isDiscount ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(
                fontSize: isDiscount ? 26 : 24,
                fontWeight: FontWeight.bold,
                color: isDiscount ? Colors.deepOrange : Colors.black,
                decoration:
                    isDiscount ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
---------------------------------------------------
//adviceproduct.dart
import 'package:flutter/material.dart';
import '../services/route_logger.dart';

class AdviceProductList extends StatefulWidget {
  final ScrollController scrollController;
  const AdviceProductList({super.key, required this.scrollController});

  @override
  State<AdviceProductList> createState() => _AdviceProductListState();
}

class _AdviceProductListState extends State<AdviceProductList> {
  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/advice_product'); // 記錄當前頁面
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: Icon(Icons.drag_handle, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          "先別離開！根據掃描的商品，您也能考慮以下商品：",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 30,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 28,
              expiry: "效期剩1天",
            ),
            ProductCard(
              imageUrl: "assets/milk.jpg",
              price: 25,
              expiry: "效期剩5小時",
            ),
          ],
        ),
      ],
    );
  }
}

/// ProductCard 保持不變
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final double price;
  final String expiry;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.price,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFD9EAD3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              "\$$price",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              expiry,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

---------------------------------------------------
//member_pofile_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
import 'scanning_picture_page.dart';
import 'member_history_page.dart';

// 定義顏色常量
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9);
const Color _kCardBg = Color(0xFFF1F8E9);
const Color _kAccentOrange = Color(0xFFFFB300);

class MemberProfilePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String token;

  const MemberProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.token,
  });

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  // 使用 String 而非 TextEditingController
  String _name = '';
  String _phone = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _name = widget.userName; // 預設名稱
    _loadUserData();
    saveCurrentRoute('/member_profile');
  }

  // --- 載入會員資料 ---
  Future<void> _loadUserData() async {
    final userData = await fetchUserData(widget.userId, widget.token);
    if (userData != null && mounted) {
      setState(() {
        _name = userData['name'] ?? widget.userName;
        _phone = userData['phone'] ?? '';
        _email = userData['email'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入會員資料失敗'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimaryGreen))
          : SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10), // 保留頂部間距
                          // 1. LOGO (使用 Padding 控制與下方卡片的間距)
                          Padding(
                            padding: const EdgeInsets.only(top: 60.0, bottom: 20.0), // 統一使用 20.0 的底部間距
                            child: _buildLogo(),
                          ),
                          
                          // 2. 個人資料卡片
                          _buildProfileCard(context),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // LOGO 區塊 (高度調整為 160，與 MemberEditPage 保持一致)
  Widget _buildLogo() {
    return SizedBox(
      height: 160, // 調整為 160
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  // 個人資料卡片
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 頂部操作
          _buildActionButtons(context),
          const SizedBox(height: 10),

          // 頭像
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFDCEDC8),
              child: Icon(Icons.person, size: 50, color: _kPrimaryGreen),
            ),
          ),
          const SizedBox(height: 30),

          // 資料顯示
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  _buildDataRow('姓名', _name),
                  const SizedBox(height: 15),
                  _buildDataRow('電話', _phone),
                  const SizedBox(height: 15),
                  _buildDataRow('Email', _email),
                  const SizedBox(height: 15),
                  _buildDataRow('密碼', '********'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 修改按鈕 → 進入 /member_edit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final bool? needsReload = await Navigator.pushNamed(
                  context,
                  '/member_edit',
                  arguments: {
                    'userId': widget.userId,
                    'userName': _name,
                    'phone': _phone,
                    'email': _email,
                    'token': widget.token,
                  },
                ) as bool?;

                if (needsReload == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('資料已成功修改！'), backgroundColor: Colors.green),
                  );
                  _loadUserData(); // ✅ 重新讀會員資料
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _kAccentOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('修改', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 15),

          // 登出
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // 頂部操作按鈕
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconTextButton(
          context,
          '歷史記錄',
          Icons.description,
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberHistoryPage(
                    userId: widget.userId,
                    userName: widget.userName,
                    token: widget.token,
                  ),
                ),
              ),
        ),
        _buildIconTextButton(
          context,
          '掃描',
          Icons.fullscreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanningPicturePage(
                userId: widget.userId,
                userName: widget.userName,
                token: widget.token,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Icon + 文字按鈕
  Widget _buildIconTextButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _kPrimaryGreen,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kPrimaryGreen),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 16, color: _kPrimaryGreen)),
        ],
      ),
      // 保持原始的邏輯和樣式
    );
  }

  // 資料顯示列
  Widget _buildDataRow(String label, String value) {
    final displayValue = value.isEmpty ? '未填寫' : value;
    final displayColor = value.isEmpty ? Colors.grey[600] : Colors.black;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              color: displayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // 登出按鈕
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
        ),
        child: const Text('登出', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
---------------------------------------------------
//member_history_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/route_logger.dart';
import 'package:intl/intl.dart'; // 💡 新增：用於日期格式化
import 'scanning_picture_page.dart';
import '../services/api_service.dart';
import 'dart:io';



// 定義顏色常量
const Color _kPrimaryGreen = Color(0xFF388E3C);
const Color _kLightGreenBg = Color(0xFFE8F5E9); 
const Color _kCardBg = Color(0xFFF1F8E9); 
const Color _kAccentRed = Color(0xFFD32F2F); 

class MemberHistoryPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? token;

  const MemberHistoryPage({super.key, this.userId, this.userName, this.token});

  @override
  State<MemberHistoryPage> createState() => _MemberHistoryPageState();
}

class _MemberHistoryPageState extends State<MemberHistoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  DateTime? _selectedDate;
  String _searchText = ""; // 搜尋文字

  @override
  void initState() {
    super.initState();
    fetchHistory(); 
    saveCurrentRoute('/member_history'); 
  }

  // 日期選擇器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _kPrimaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      fetchHistory(date: picked, search: _searchText);
    }
  }

  // 抓歷史紀錄 + AI定價
  Future<void> fetchHistory({DateTime? date, String? search}) async {
    setState(() => isLoading = true);

    String baseUrl = "${ApiConfig.baseUrl}/get_products/${widget.userId}";
    Map<String, String> queryParams = {};

    if (date != null) {
      queryParams["date"] = DateFormat('yyyy-MM-dd').format(date);
    } else if (_selectedDate != null) {
      queryParams["date"] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    if (search != null && search.isNotEmpty) {
      queryParams["search"] = search;
    } else if (_searchText.isNotEmpty) {
      queryParams["search"] = _searchText;
    }

    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            products = data['products'] ?? [];
            isLoading = false;
          });
        }
        // ✅ 立即抓一次 AI 價格
        //_refreshAiPrices();
        // ✅ 初次載入後，立即抓取一次最新 AI 定價
        await _refreshAiPrices();

        print("✅ 抓到歷史紀錄，共 ${products.length} 筆");
        for (var p in products) {
          print("Product: ${p['ProName']}, HistoryID=${p['HistoryID']}, AI=${p['AiPrice']}");
        }
      } else {
        throw Exception("載入失敗: ${response.body}");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("❌ Error fetching history: $e");
    }
  }
  // ✅ 抓取 AI 定價（不再定時，只在 fetchHistory() 後跑一次）
  Future<void> _refreshAiPrices() async {
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      double? aiPrice = await fetchAIPrice(product['ProductID']); // 用 ID 抓
      if (aiPrice != null && mounted) {
        setState(() {
          products[i]['AiPrice'] = aiPrice.toInt(); // ✅ 去除 .0
        });
      }
    }
  }

  // 刪除紀錄
  void _deleteHistoryItem(int historyId, int index) async {
    if (historyId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 無效的 HistoryID')),
      );
      return;
    }

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/history/$historyId");
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已刪除紀錄 (ID=$historyId)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 刪除失敗: ${response.body}')),
        );
      }
    } catch (e) {
      print("❌ 刪除發生錯誤: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 刪除發生錯誤: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = _selectedDate == null 
        ? '掃描歷史記錄' 
        : DateFormat('yyyy/MM/dd').format(_selectedDate!);

    return Scaffold(
      backgroundColor: _kLightGreenBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildSearchBar(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: _kPrimaryGreen))
                          : products.isEmpty
                              ? Center(
                                  child: Text(
                                    _selectedDate != null 
                                        ? "當日沒有歷史紀錄"
                                        : (widget.token == null ? "訪客模式無法保存歷史紀錄" : "目前沒有歷史紀錄"),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 15.0),
                                      child: _buildHistoryCard(context, product, index),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      color: _kLightGreenBg, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _kPrimaryGreen),
            onPressed: () => Navigator.pop(context), 
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: _kPrimaryGreen), 
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanningPicturePage(
                  userId: widget.userId!,
                  userName: widget.userName!,
                  token: widget.token!,
                ),
              ),
            ), 
          ),
        ],
      ),
    );
  }
  
  // 搜尋欄位 (含日曆)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '請輸入商品名稱',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchText = value;
                });
                fetchHistory(search: value);
              },
            ),
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.calendar_today, color: _kPrimaryGreen), 
            ),
          ),
        ],
      ),
    );
  }

  // 單一卡片
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> product, int index) {
    final marketParts = (product['Market'] as String? ?? '未知超市|未知分店').split('|');
    final market = marketParts[0];
    final branch = marketParts.length > 1 ? marketParts[1] : '分店';
    
    final originalPrice = product['ProPrice'] ?? 0;
    final suggestedPrice = (product['AiPrice'] ?? 0).toInt(); 

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖片
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                    image: DecorationImage(
                      image: product['ImagePath'] != null
                        ? NetworkImage("${ApiConfig.baseUrl}${product['ImagePath']}")
                        : const AssetImage('assets/milk.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(market, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(branch, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // 文字資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['ProName'] ?? '未知商品',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                _buildInfoRow('掃描時間', product['ScanDate'] ?? '-'),
                _buildInfoRow('有效期限', product['ExpireDate'] ?? '-'),
                _buildPriceRow('即期價格', '\$${originalPrice}', isOriginal: true),
                _buildPriceRow('AI定價', '\$${suggestedPrice}', isOriginal: true),
              ],
            ),
          ),

          // 刪除按鈕
          GestureDetector(
            onTap: () => _deleteHistoryItem(product['HistoryID'] ?? -1, index),
            child: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.delete_outline, color: _kAccentRed, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {required bool isOriginal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isOriginal ? Colors.black54 : _kAccentRed,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isOriginal ? Colors.black87 : _kAccentRed,
              fontWeight: isOriginal ? FontWeight.normal : FontWeight.bold,
              fontSize: isOriginal ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

---------------------------------------------------
//member_edit_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/route_logger.dart';
import 'member_profile_page.dart';

class MemberEditPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phone;
  final String email;
  final String token;

  const MemberEditPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.email,
    required this.token,
  });

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    saveCurrentRoute('/member_edit');

    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final success = await updateUserData(
      userId: widget.userId,
      token: widget.token,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料已成功修改！'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // ✅ 通知 Profile 要 reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.red),
      );
    }
  }

  // 🎯 LOGO 區塊 (從原始碼複製過來)
  Widget _buildLogo() {
    return const SizedBox(
      height: 160, // 保持 Profile Page 的高度
      width: double.infinity,
      child: Center(
        child: Image(
          image: AssetImage('assets/logo.png'), // 使用 Image.asset
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF388E3C)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // 🎯 替換為圖片 Logo
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0), // 調整間距以適應 Logo 高度
                            child: _buildLogo(), // 使用新的 Logo Widget
                          ),
                          _buildFormCard(),
                          const SizedBox(height: 20), // 調整底部間距
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('編輯個人資料', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextFieldRow('姓名', _nameController, hintText: '請輸入姓名'),
          const SizedBox(height: 15),
          _buildTextFieldRow('電話', _phoneController, hintText: '請輸入電話'),
          const SizedBox(height: 15),
          _buildTextFieldRow('帳號', _emailController, hintText: '請輸入Email'),
          const SizedBox(height: 15),
          _buildTextFieldRow('密碼', _passwordController, hintText: '請輸入新密碼', obscureText: true),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFFFB300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('修改', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(String label, TextEditingController controller,
      {String hintText = '', bool obscureText = false}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}