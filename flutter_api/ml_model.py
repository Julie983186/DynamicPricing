# ml_model.py
import pandas as pd
import joblib
import numpy as np

try:
    model = joblib.load("random_forest_model.pkl")
    feature_cols = model.feature_names_in_
except:
    feature_cols = ['剩餘保存期限_小時','原價',
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
    
    # 商品名稱
    if 'ProName' not in df.columns:
        df['ProName'] = '未知商品'
    
    # 原價
    if 'ProPrice' not in df.columns:
        df['ProPrice'] = df.get('price', 0)
    df['原價'] = df['ProPrice']
    
    # 剩餘保存期限（分鐘）
    if 'ExpireDate' in df.columns:
        now = pd.Timestamp.now()
        df['剩餘保存期限_小時'] = (
            pd.to_datetime(df['ExpireDate'], errors='coerce') - now
        ).dt.total_seconds().div(60).clip(lower=0)
    else:
        df['剩餘保存期限_小時'] = 0
    
    # 預設欄位
    df['人流量'] = '一般'
    df['天氣'] = '晴天'
    df['停車狀況'] = '一般'
    
    # 商品大類
    if '商品大類' not in df.columns and 'ProductType' in df.columns:
        df['商品大類'] = df['ProductType']
    elif '商品大類' not in df.columns:
        df['商品大類'] = '其他'
    
    # one-hot encode
    df = pd.get_dummies(df, columns=['人流量','天氣','停車狀況','商品大類'])
    
    # 補上模型要求的欄位
    for col in feature_cols:
        if col not in df.columns:
            df[col] = 0
            
    return df[feature_cols]

def predict_price(df, update_db=True, mysql=None):
    """
    df: pandas DataFrame, 至少需包含 ProPrice
    update_db: 是否直接更新 MySQL product 表的 AiPrice 與 Reason
    mysql: 若 update_db=True，需傳入 mysql 連線物件
    """
    df = df.copy()
    X = prepare_features(df)
    
    # AI 折扣
    df['AI折扣'] = model.predict(X).round(2)
    
    # 確保 ProPrice 是數字
    df['ProPrice'] = pd.to_numeric(df['ProPrice'], errors='coerce').fillna(0)
    
    # 計算 AiPrice
    df['AiPrice'] = (df['ProPrice'] * (1 - df['AI折扣'])).round(0).astype(int)
    
    # 判斷合理性
    df['Reason'] = df.apply(lambda r: "合理" if r['AiPrice'] > r['ProPrice'] else "不合理", axis=1)
    
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
