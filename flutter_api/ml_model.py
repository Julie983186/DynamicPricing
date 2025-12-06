import pandas as pd
import joblib
import numpy as np
import pytz
import random

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

# ===== 在 prepare_features 開頭或 top of file 做欄位清理 helper =====
def clean_column_names(df):
    # 移除所有 whitespace（含全形、半形等）
    df = df.copy()
    df.columns = df.columns.str.replace(r'\s+', '', regex=True)
    return df
# ----------------- feature_cols 現在是全域變數 -----------------

def prepare_features(df):
    df = df.copy()
    
    # 商品名稱與價格
    df['ProName'] = df.get('ProName', '未知商品')
    # 確認 price 與 ProPrice 來源正確
    df['price'] = pd.to_numeric(df.get('price', 0), errors='coerce').fillna(0).astype(float)
    df['ProPrice'] = pd.to_numeric(df.get('ProPrice', 0), errors='coerce').fillna(0).astype(float)

    df['原價'] = df['price']  # 原價欄位保留 price 的值

    # ----------------- ExpireDate 處理（台北時區 -> UTC） -----------------
    local_tz = 'Asia/Taipei'

    # 取得當下時間（UTC）
    now_utc = pd.Timestamp.now(tz='UTC')

    # 先解析日期（可能 tz-naive）
    expire = pd.to_datetime(df.get('ExpireDate'), errors='coerce')

    # 整日 00:00:00 → 23:59:59
    expire = expire.apply(
        lambda x: x + pd.Timedelta(hours=23, minutes=59, seconds=59)
        if pd.notna(x) and x.hour == 0 and x.minute == 0 and x.second == 0
        else x
    )

    # 安全 localize：tz-naive → 台北時間；tz-aware → 轉台北時間
    def localize_to_taipei(ts):
        if pd.isna(ts):
            return pd.NaT
        try:
            if ts.tzinfo is None:
                return ts.tz_localize(local_tz, ambiguous='NaT', nonexistent='NaT')
            return ts.tz_convert(local_tz)
        except Exception:
            return pd.NaT

    expire = expire.apply(localize_to_taipei)

    # fallback：若仍有 NaT，直接用 tz_localize
    mask_nat = expire.isna()
    if mask_nat.any():
        fallback = pd.to_datetime(df.loc[mask_nat, 'ExpireDate'], errors='coerce')
        fallback = fallback.dt.tz_localize(local_tz, ambiguous='NaT', nonexistent='NaT')
        expire = expire.combine_first(fallback)

    # 統一轉成 UTC
    expire = expire.dt.tz_convert('UTC')

    # 計算剩餘小時
    delta_hours = (expire - now_utc).dt.total_seconds() / 3600
    df['剩餘保存期限_小時'] = delta_hours.clip(lower=0).fillna(0)

    # 可讀格式
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

    df['剩餘時間_可讀'] = expire.apply(lambda x: format_remaining_time(x, now_utc))

    print("🕒 剩餘時間檢查（台北時區）:")
    print(df[['ProName', 'ExpireDate', '剩餘保存期限_小時', '剩餘時間_可讀']])




    # 模擬不同人流、天氣、停車狀況（使模型有變化）
    df['人流量'] = [random.choice(['少', '一般', '多']) for _ in range(len(df))]
    df['天氣'] = [random.choice(['晴天', '陰天', '雨天']) for _ in range(len(df))]
    df['停車狀況'] = [random.choice(['少', '一般', '多']) for _ in range(len(df))]
    df['當下溫度'] = np.random.randint(20, 33, size=len(df))  # 溫度 20~32 度
    df['貨架上庫存量'] = np.random.randint(5, 20, size=len(df))  # 庫存 5~20 件

    
    # --- ProductType 若不存在要嘗試使用 ProductType 欄或預設 '其他' ---
    if '商品大類' not in df.columns:
        if 'ProductType' in df.columns:
            df['商品大類'] = df['ProductType']
        else:
            # 若 DB 沒有 ProductType，請改 SQL 把它抓回來（下方示例會說明）
            df['商品大類'] = '其他'
    
    # one-hot encode
    df = pd.get_dummies(df, columns=['人流量','天氣','停車狀況','商品大類'], dtype=int)
    
    # 統一欄位名稱格式（移除空格）
    #df.columns = df.columns.str.replace(' ', '')
    # 再次清理欄位名稱（避免 dummies 產生空格）
    df.columns = df.columns.str.replace(r'\s+', '', regex=True)

    # 補上模型要求的欄位
    for col in feature_cols:
        if col not in df.columns:
            df[col] = 0

    # 最後：確保所有輸入數值型別正確（把 bool -> int）
    df = df.copy()
    for c in df.columns:
        if df[c].dtype == 'bool':
            df[c] = df[c].astype(int)
            
    return df

#這裡有些不一樣
def predict_price(df, update_db=True, mysql=None):
    print("📌 price 與 ProPrice 對照檢查：")
    print(df[['ProductID','ProName','price','ProPrice']])

    """
    df: pandas DataFrame, 至少需包含 ProPrice
    update_db: 是否直接更新 MySQL product 表的 AiPrice 與 Reason
    mysql: 若 update_db=True，需傳入 mysql 連線物件
    """
    df = df.copy()

    # 先用 prepare_features 計算欄位、剩餘時間、one-hot 等
    df_full = prepare_features(df)

    # ⚡ 只取模型訓練過的欄位
    X = df_full[feature_cols]
    #X = prepare_features(df)

    # debug start
    print("🔍 model type:", type(model))
    try:
        print("🔍 model.feature_names_in_ length:", len(model.feature_names_in_))
    except Exception:
        print("🔍 model has no feature_names_in_")

    print("==== DEBUG X summary ====")
    print("🧾 X shape:", X.shape)
    print("nonzero counts:\n", (X != 0).sum().sort_values(ascending=False).head(30))
    if '剩餘保存期限_小時' in X.columns:
        print("剩餘保存期限 describe:\n", X['剩餘保存期限_小時'].describe())
    print("missing features:", [c for c in feature_cols if c not in X.columns])
    # 各特徵非零數量（看哪些 one-hot 實際有值）
    nz = (X != 0).sum().sort_values(ascending=False)
    print("🧩 非零欄位計數 (top 20):")
    print(nz.head(20).to_string())

    # 查看剩餘時間分布（最關鍵）
    if '剩餘保存期限_小時' in X.columns:
        print("⏱ 剩餘保存期限_小時 describe:")
        print(X['剩餘保存期限_小時'].describe())
        print("⏱ 剩餘保存期限_小時 unique count:", X['剩餘保存期限_小時'].nunique())
    # debug end


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
    print(df[['ProductID','ProName','AiPrice','ProPrice','差異', 'AI折扣']])

    # 判斷合理性（允許誤差 ±1）
    df['Reason'] = df.apply(
        lambda r: "合理" if np.isclose(r['AiPrice'], r['ProPrice'], atol=1) or r['AiPrice'] >= r['ProPrice']
        else "不合理",
        axis=1
    )


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
'''
if __name__ == "__main__":
    test_df = pd.DataFrame([
        {
            'ProductID': 1,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-23 20:00:00 GMT',
            'ProductType': '肉類'
        },
        {
            'ProductID': 2,
            'ProName': '鮭魚',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-23 23:00:00 GMT',
            'ProductType': '魚類'
        },
        {
            'ProductID': 3,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-24 00:00:00 GMT',
            'ProductType': '肉類'
        },
        {
            'ProductID': 4,
            'ProName': '鮭魚',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-24 00:00:00 GMT',
            'ProductType': '魚類'
        }
        ,
        {
            'ProductID': 5,
            'ProName': '水果',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-24 19:00:00 GMT',
            'ProductType': '蔬果類'
        }
        ,
        {
            'ProductID': 6,
            'ProName': '水果',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-24 14:00:00 GMT',
            'ProductType': '蔬果類'
        },
        {
            'ProductID': 7,
            'ProName': '吐司',
            'price': 200,
            'ProPrice': 180,
            'ExpireDate': '2025-10-24 14:00:00 GMT',
            'ProductType': '麵包甜點類'
        },
        {
            'ProductID': 8,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-24 9:00:00 GMT',
            'ProductType': '肉類'
        },
        {
            'ProductID': 9,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-24 12:00:00 GMT',
            'ProductType': '肉類'
        },
        {
            'ProductID': 10,
            'ProName': '雞三節翅',
            'price': 120,
            'ProPrice': 90,
            'ExpireDate': '2025-10-24 20:00:00 GMT',
            'ProductType': '肉類'
        }
    ])

    result = predict_price(test_df, update_db=False)
    print("模型特徵欄位:", feature_cols)
    print(result)
'''