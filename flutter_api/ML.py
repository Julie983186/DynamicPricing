import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
import re
import joblib

df = pd.read_csv("畢業專題田野調查.csv", encoding="utf-8-sig")

def compute_remaining_hours(row):
    hours = row['剩餘保存期限'] * 24
    time_str = str(row['時間'])
    match = re.search(r'(\d{1,2}):\d{2}-(\d{1,2}):\d{2}', time_str)
    if match:
        end_hour = int(match.group(2))
    else:
        end_hour = 0  # 防呆

    remaining_today = 24 - end_hour
    total_hours = hours + remaining_today
    return total_hours

df['剩餘保存期限_小時'] = df.apply(compute_remaining_hours, axis=1)

print(df[['時間', '剩餘保存期限', '剩餘保存期限_小時']].head())


df = pd.get_dummies(df, columns=['商品大類', '停車狀況', '人流量', '天氣'])
df.fillna(0, inplace=True)
cols = [c for c in df.columns if '_' in c]
#df[cols] = df[cols].fillna(0).astype(int)
df['售價'] = df['原價']*(1-df['折扣(off)']/100)
df['折扣實際'] = 1 - df['售價'] / df['原價']

# 特徵欄位
feature_cols = ['剩餘保存期限_小時','原價','當下溫度','貨架上庫存量'] \
               + [c for c in df.columns if c.startswith('商品大類_')] \
               + [c for c in df.columns if c.startswith('停車狀況_')] \
               + [c for c in df.columns if c.startswith('人流量_')] \
               + [c for c in df.columns if c.startswith('天氣_')]

X = df[feature_cols]
y = df['折扣實際']


X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 建立模型
model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# 誤差值
y_pred = model.predict(X_test)
print("MSE:", mean_squared_error(y_test, y_pred))


df['折扣預測'] = model.predict(X[feature_cols])
df['售價預測'] = df['原價'] * (1 - df['折扣預測'])


print(df[['商品品項','剩餘保存期限_小時','折扣預測','售價預測']])


output_path = "dynamic_pricing_result.csv"
df.to_csv(output_path, index=False, encoding="utf-8-sig")
print("已存檔：dynamic_pricing_result.csv")

# 儲存模型
model_path = "random_forest_model.pkl"
joblib.dump(model, model_path)
print("模型已儲存：", model_path)
