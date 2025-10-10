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
