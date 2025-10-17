# ml_model.py
import pandas as pd
import joblib
import numpy as np

try:
    model = joblib.load("random_forest_model.pkl")
    feature_cols = model.feature_names_in_
    print("✅ 已載入真實模型")
except Exception as e:
    print("⚠️ 無法載入模型，改用 FakeModel:", e)
    feature_cols = ['剩餘保存期限_小時','原價',
                    '人流量_少', '人流量_一般', '人流量_多',
                    '天氣_晴天', '天氣_陰天', '天氣_雨天',
                    '停車狀況_少', '停車狀況_一般', '停車狀況_多',
                    '商品大類_肉類','商品大類_魚類','商品大類_蔬果類','商品大類_其他']
    class FakeModel:
        def predict(self, X):
            values = np.random.rand(len(X)) * 0.5
            print("🔍 FakeModel 輸出:", values)
            return values
    model = FakeModel()

def prepare_features(df):
    df = df.copy()
    
    # 商品名稱與價格
    df['ProName'] = df.get('ProName', '未知商品')
    # 確認 price 與 ProPrice 來源正確
    df['price'] = pd.to_numeric(df.get('price', 0), errors='coerce').fillna(0).astype(float)
    df['ProPrice'] = pd.to_numeric(df.get('ProPrice', 0), errors='coerce').fillna(0).astype(float)

    df['原價'] = df['price']  # 原價欄位保留 price 的值

    
    # 剩餘保存期限（分鐘）
    now = pd.Timestamp.now()
    df['剩餘保存期限_小時'] = (
        pd.to_datetime(df.get('ExpireDate'), errors='coerce') - now
    ).dt.total_seconds().div(3600).clip(lower=0).fillna(0)
    
    # 預設欄位
    df['人流量'] = '一般'
    df['天氣'] = '晴天'
    df['停車狀況'] = '一般'
    df['當下溫度'] = 25
    df['貨架上庫存量'] = 10
    
    # 商品大類
    if '商品大類' not in df.columns and 'ProductType' in df.columns:
        df['商品大類'] = df['ProductType']
    elif '商品大類' not in df.columns:
        df['商品大類'] = '其他'
    
    # one-hot encode
    df = pd.get_dummies(df, columns=['人流量','天氣','停車狀況','商品大類'])
    
    # 統一欄位名稱格式（移除空格）
    df.columns = df.columns.str.replace(' ', '')

    # 補上模型要求的欄位
    for col in feature_cols:
        if col not in df.columns:
            df[col] = 0
            
    return df[feature_cols]

def predict_price(df, update_db=True, mysql=None):
    print("📌 price 與 ProPrice 對照檢查：")
    print(df[['ProductID','ProName','price','ProPrice']])

    """
    df: pandas DataFrame, 至少需包含 ProPrice
    update_db: 是否直接更新 MySQL product 表的 AiPrice 與 Reason
    mysql: 若 update_db=True，需傳入 mysql 連線物件
    """
    df = df.copy()
    X = prepare_features(df)
    print("🧩 輸入給模型的欄位：", list(X.columns))
    print("📊 前幾筆輸入數據：")
    print(X.head())

    # AI 折扣
    df['AI折扣'] = model.predict(X).round(2)
    
    # 確保數值型別正確
    df['ProPrice'] = pd.to_numeric(df['ProPrice'], errors='coerce').fillna(0).astype(float)
    df['price'] = pd.to_numeric(df['price'], errors='coerce').fillna(0).astype(float)
    df['AiPrice'] = (df['price'] * (1 - df['AI折扣'])).round(0).astype(float)

    df['差異'] = df['AiPrice'] - df['ProPrice']
    print("🛠 AiPrice 與 ProPrice 差異檢查：")
    print(df[['ProductID','ProName','AiPrice','ProPrice','差異']])

    # 判斷合理性（允許誤差 ±1）
    df['Reason'] = df.apply(
        lambda r: "合理" if np.isclose(r['AiPrice'], r['ProPrice'], atol=1) or r['AiPrice'] >= r['ProPrice']
        else "不合理",
        axis=1
    )

    # # 確保 ProPrice 是數字
    # df['ProPrice'] = pd.to_numeric(df['ProPrice'], errors='coerce').fillna(0)
    # # 確保 price 是數字
    # df['price'] = pd.to_numeric(df['price'], errors='coerce').fillna(0)
    
    # # 計算 AiPrice
    # df['AiPrice'] = (df['price'] * (1 - df['AI折扣'])).round(0).astype(int)
    # df['AiPrice'] = pd.to_numeric(df['AiPrice'], errors='coerce').fillna(0)
    # # 判斷合理性
    # df['Reason'] = df.apply(lambda r: "合理" if r['AiPrice'] >= r['ProPrice'] else "不合理", axis=1)
    
    # 若需要直接更新資料庫
    if update_db and mysql is not None:
        try:
            cur = mysql.connection.cursor()
            for _, row in df.iterrows():
                cur.execute(
                    "UPDATE product SET AiPrice=%s, Reason=%s WHERE ProductID=%s",
                    (row['AiPrice'], row['Reason'], row['ProductID'])
                )
            mysql.connection.commit()
            cur.close()
        except Exception as e:
            print("❌ 更新 AiPrice 失敗:", e)
    
    return df[['ProductID','ProName','ProPrice','AI折扣','AiPrice','Reason']]

# === ✅ 測試區 ===
if __name__ == "__main__":
    test_df = pd.DataFrame([
        {
            'ProductID': 1,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-18 20:00',
            'ProductType': '肉類'
        },
        {
            'ProductID': 2,
            'ProName': '鮭魚',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-17 23:00',
            'ProductType': '魚類'
        }
    ])

    result = predict_price(test_df, update_db=False)
    print("模型特徵欄位:", feature_cols)
    print(result)