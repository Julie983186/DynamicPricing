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