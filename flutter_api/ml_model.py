import pandas as pd
import joblib
import numpy as np
import pytz

# ----------------- 模型載入 -----------------
try:
    model = joblib.load("random_forest_model.pkl")
    feature_cols = model.feature_names_in_  # ⚡ 全域
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
# ----------------- feature_cols 現在是全域變數 -----------------

def prepare_features(df):
    df = df.copy()
    
    # 商品名稱與價格
    df['ProName'] = df.get('ProName', '未知商品')
    # 確認 price 與 ProPrice 來源正確
    df['price'] = pd.to_numeric(df.get('price', 0), errors='coerce').fillna(0).astype(float)
    df['ProPrice'] = pd.to_numeric(df.get('ProPrice', 0), errors='coerce').fillna(0).astype(float)

    df['原價'] = df['price']  # 原價欄位保留 price 的值

    # 取得「本地」當下時間（指定時區為台北）
    local_tz = 'Asia/Taipei'
    now = pd.Timestamp.now(tz=local_tz)
    
    # 修正後
    expire = pd.to_datetime(df.get('ExpireDate'), errors='coerce')
    expire = expire.dt.tz_localize('Asia/Taipei', ambiguous='NaT', nonexistent='NaT')
    
    # fallback：若無法解析，嘗試視為本地時間
    mask_nat = expire.isna()
    if mask_nat.any():
        fallback = pd.to_datetime(df.loc[mask_nat, 'ExpireDate'], errors='coerce')
        fallback = fallback.dt.tz_localize(local_tz, ambiguous='NaT', nonexistent='NaT')
        expire.loc[mask_nat] = fallback

    # 🕓 若時間為「整日」（例如 2025-10-18 00:00:00），視為當日 23:59:59
    expire = expire.apply(
        lambda x: x + pd.Timedelta(hours=23, minutes=59, seconds=59)
        if (not pd.isna(x) and x.hour == 0 and x.minute == 0 and x.second == 0)
        else x
    )

    # 計算剩餘時間（小時）
    delta_hours = (expire - now).dt.total_seconds().div(3600)
    df['剩餘保存期限_小時'] = delta_hours.clip(lower=0).fillna(0)

    # 轉成可讀格式
    def format_remaining_time(expire_ts, now_ts):
        if pd.isna(expire_ts):
            return "未知"
        delta = expire_ts - now_ts
        if delta.total_seconds() <= 0:
            return "已過期"
        days = delta.days
        hours, remainder = divmod(delta.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{days}天 {hours}小時 {minutes}分 {seconds}秒"

    df['剩餘時間_可讀'] = expire.apply(lambda x: format_remaining_time(x, now))

    # ✅ debug 印出確認
    print("🕒 剩餘時間檢查（台北時區）:")
    print(df[['ProName', 'ExpireDate', '剩餘保存期限_小時', '剩餘時間_可讀']])

    
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
            
    return df


def predict_price(df, update_db=True, mysql=None, show_features_only=True):
    df = df.copy()

    # 計算特徵欄位（包含 one-hot 類別）
    df_full = prepare_features(df)

    # 🔍 檢查 one-hot
    category_cols = [c for c in df_full.columns if c.startswith("商品大類_")]
    print("🔍 商品大類 one-hot 欄位 head：")
    print(df_full[category_cols].head())

    # 模型輸入
    X = df_full[feature_cols]

    # AI 折扣
    df['AI折扣'] = model.predict(X).round(2)

    # 確保數值型別正確
    df['ProPrice'] = pd.to_numeric(df['ProPrice'], errors='coerce').fillna(0).astype(float)
    df['price'] = pd.to_numeric(df['price'], errors='coerce').fillna(0).astype(float)
    df['AiPrice'] = (df['price'] * (1 - df['AI折扣'])).round(0).astype(float)

    # 判斷合理性（允許誤差 ±1）
    df['Reason'] = df.apply(
        lambda r: "合理" if np.isclose(r['AiPrice'], r['ProPrice'], atol=1) or r['AiPrice'] >= r['ProPrice']
        else "不合理",
        axis=1
    )

    # 將商品大類 one-hot 轉成單一欄位 Category
    category_cols = [c for c in df_full.columns if c.startswith("商品大類_")]
    df_full[category_cols] = df_full[category_cols].astype(bool)

    def one_hot_to_category(row):
        for c in category_cols:
            if row[c]:
                return c.replace("商品大類_", "")
        return "其他"

    # ⚡ 注意 axis=1
    df['Category'] = df_full.apply(one_hot_to_category, axis=1)



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

    # 回傳只包含主要欄位 + Category
    df_final = df[['ProductID','ProName','Category','ProPrice','AI折扣','AiPrice','Reason']]

    # 若 show_features_only，打印前 10 筆
    if show_features_only:
        print(df_final.head(10))

    return df_final





'''
# === ✅ 測試區 ===
if __name__ == "__main__":
    test_df = pd.DataFrame([
        {
            'ProductID': 1,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-20 19:00',
            'ProductType': '肉類'
        },
        {
            'ProductID': 2,
            'ProName': '鮭魚',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-19 23:59',
            'ProductType': '魚類'
        },
        {
            'ProductID': 3,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-19 07:00',
            'ProductType': '肉類'
        },
        {
            'ProductID': 4,
            'ProName': '鮭魚',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-20 00:00:00',
            'ProductType': '魚類'
        },
        {
            'ProductID': 5,
            'ProName': '水果',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-19 00:00:00',
            'ProductType': '蔬果類'
        },
        {
            'ProductID': 6,
            'ProName': '水果',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-20 00:14:00',
            'ProductType': '蔬果類'
        }
    ])

    result = predict_price(test_df, update_db=False)
    print("模型特徵欄位:", feature_cols)
    print(result)
'''