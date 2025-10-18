# from flask_mysqldb import MySQL
# from flask_cors import CORS
# from ml_model import predict_price,prepare_features
# from flask import Flask, jsonify
# import pandas as pd
# from db_config import db_config
# import os
# import joblib
# import pytz
# import traceback

# app = Flask(__name__)
# CORS(app, supports_credentials=True)

# # MySQL 設定
# app.config['MYSQL_HOST'] = db_config['host']
# app.config['MYSQL_USER'] = db_config['user']
# app.config['MYSQL_PASSWORD'] = db_config['password']
# app.config['MYSQL_DB'] = db_config['database']

# mysql = MySQL(app)  # 🔹 一定要加

# # ---------------------- AI 預測價格 API ----------------------
# @app.route("/predict_price_check", methods=["GET"])
# def predict_price_check_api():
#     try:
#         cur = mysql.connection.cursor()
#         cur.execute("SELECT ProductID, ProName, ProPrice, price, ExpireDate FROM product")
#         rows = cur.fetchall()
#         df = pd.DataFrame(rows, columns=['ProductID','ProName','ProPrice','price','ExpireDate'])
#         cur.close()

#         # 🔹 debug 印欄位
#         print("===== 原始資料 =====")
#         print(df.head())
#         print(df.dtypes)
#         print(df.isnull().sum())

#         # 🔹 預測
#         df_result = predict_price(df, update_db=False, mysql=mysql)
#         print("===== 商品 AI 折扣 =====")
#         print(df_result[['ProName', 'AI折扣', 'AiPrice']].to_string(index=False))
#         print("===== ml_model 計算結果 =====")
#         print(df_result.head())

#         return jsonify({
#             "raw_data": df.to_dict(orient="records"),
#             "ai_result": df_result.to_dict(orient="records")
#         }), 200

#     except Exception as e:
#         print(traceback.format_exc())
#         return jsonify({"error": str(e)}), 500


# # ---------------------- 測試剩餘時間 ----------------------
# if __name__ == "__main__":
#     print("🧪 測試剩餘時間邏輯...\n")
#     with app.app_context():
#         try:
#             cur = mysql.connection.cursor()
#             cur.execute("SELECT ProductID, ProName, ProPrice, price, ExpireDate FROM product")
#             rows = cur.fetchall()
#             cur.close()

#             df = pd.DataFrame(rows, columns=['ProductID', 'ProName', 'ProPrice', 'price', 'ExpireDate'])

#             # 🔹 使用 prepare_features 計算剩餘時間
#             df_full = prepare_features(df)

#             print("\n===== 全部商品剩餘時間對照表 =====")
#             print(df_full[['ProName','ExpireDate','剩餘保存期限_小時','剩餘時間_可讀']].to_string(index=False))

#         except Exception as e:
#             print("❌ 測試失敗：", e)
#             print(traceback.format_exc())

#     app.run(debug=True, host="0.0.0.0", port=5000)
