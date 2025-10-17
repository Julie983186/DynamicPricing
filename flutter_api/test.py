from flask_mysqldb import MySQL
from flask_cors import CORS
from ml_model import predict_price
from flask import Flask, jsonify
import pandas as pd
from db_config import db_config
import os
import joblib



model_path = os.path.join(os.path.dirname(__file__), "random_forest_model.pkl")
model = joblib.load(model_path)


app = Flask(__name__)
CORS(app, supports_credentials=True)

# MySQL 設定
app.config['MYSQL_HOST'] = db_config['host']
app.config['MYSQL_USER'] = db_config['user']
app.config['MYSQL_PASSWORD'] = db_config['password']
app.config['MYSQL_DB'] = db_config['database']

mysql = MySQL(app)  # 🔹 一定要加

# ---------------------- AI 預測價格 API (檢查版本) ----------------------
@app.route("/predict_price_check", methods=["GET"])
def predict_price_check_api():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT ProductID, ProName, ProPrice, price, ExpireDate FROM product")
        rows = cur.fetchall()
        df = pd.DataFrame(rows, columns=['ProductID','ProName','price','ProPrice','ExpireDate'])
        
        # 🔹 檢查資料
        print("===== 資料庫抓出的原始資料 =====")
        print(df.head())
        print("欄位型別：")
        print(df.dtypes)
        print("是否有空值：")
        print(df.isnull().sum())

        # 🔹 送入 ml_model 預測
        df_result = predict_price(df, update_db=False)  # 先不更新資料庫
        print("===== ml_model 計算結果 =====")
        print(df_result.head())
        
        cur.close()
        return jsonify({
            "raw_data": df.to_dict(orient="records"),
            "ai_result": df_result.to_dict(orient="records")
        }), 200
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500

