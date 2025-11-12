# HTTP Basic Authentication 範例

這個專案展示如何在 Python 中實作 HTTP Basic Authentication（基本認證）。

## 📁 檔案說明

- **http_basic_auth_server.py**: Flask 伺服器實作，包含受保護的端點
- **http_basic_auth_client.py**: 客戶端範例，展示如何發送認證請求
- **requirements.txt**: 所需的 Python 套件

## 🔐 HTTP Basic Authentication 原理

HTTP Basic Authentication 是一種簡單的認證機制：

1. 客戶端發送請求時，在 HTTP header 中包含 `Authorization` 欄位
2. 格式為：`Authorization: Basic base64(username:password)`
3. 伺服器解碼並驗證用戶名和密碼
4. 驗證成功則返回請求的資源，失敗則返回 401 Unauthorized

### 範例

假設用戶名是 `admin`，密碼是 `admin123`：

```
原始字串: admin:admin123
Base64 編碼: YWRtaW46YWRtaW4xMjM=
Authorization Header: Basic YWRtaW46YWRtaW4xMjM=
```

## 🚀 安裝與執行

### 1. 安裝依賴套件

```bash
pip install -r requirements.txt
```

或手動安裝：

```bash
pip install flask requests
```

### 2. 啟動伺服器

```bash
python http_basic_auth_server.py
```

伺服器將在 `http://localhost:5000` 啟動。

### 3. 執行客戶端測試（開啟另一個終端）

```bash
python http_basic_auth_client.py
```

## 🔑 測試帳號

伺服器預設包含以下測試帳號：

| 用戶名 | 密碼 | 角色 |
|--------|------|------|
| admin | admin123 | 管理員 |
| user | password | 一般用戶 |
| test | test123 | 一般用戶 |

## 🌐 API 端點

### 公開端點

- **GET /** - 首頁（無需認證）
  ```bash
  curl http://localhost:5000/
  ```

### 受保護端點（需要認證）

- **GET /protected** - 受保護的頁面
  ```bash
  curl -u user:password http://localhost:5000/protected
  ```

- **GET /user-info** - 獲取當前用戶資訊
  ```bash
  curl -u test:test123 http://localhost:5000/user-info
  ```

- **GET /admin** - 管理員頁面（僅 admin 可訪問）
  ```bash
  curl -u admin:admin123 http://localhost:5000/admin
  ```

## 💻 使用範例

### 使用 curl 測試

```bash
# 未提供認證（會返回 401）
curl http://localhost:5000/protected

# 使用 -u 選項提供認證
curl -u user:password http://localhost:5000/protected

# 手動設置 Authorization header
curl -H "Authorization: Basic dXNlcjpwYXNzd29yZA==" http://localhost:5000/protected
```

### 使用 Python requests

```python
import requests
from requests.auth import HTTPBasicAuth

# 方法 1: 使用 HTTPBasicAuth
response = requests.get(
    'http://localhost:5000/protected',
    auth=HTTPBasicAuth('user', 'password')
)

# 方法 2: 使用 tuple（簡寫）
response = requests.get(
    'http://localhost:5000/protected',
    auth=('user', 'password')
)

# 方法 3: 手動設置 header
import base64
credentials = base64.b64encode(b'user:password').decode('utf-8')
headers = {'Authorization': f'Basic {credentials}'}
response = requests.get('http://localhost:5000/protected', headers=headers)
```

### 使用瀏覽器測試

直接在瀏覽器中訪問 `http://localhost:5000/protected`，瀏覽器會彈出認證對話框。

## ⚠️ 安全注意事項

1. **使用 HTTPS**：Basic Auth 使用 Base64 編碼（非加密），容易被攔截。務必在生產環境中使用 HTTPS。

2. **密碼雜湊**：範例中密碼以明文儲存，實際應用應使用 bcrypt、scrypt 等進行雜湊。

3. **Token 替代方案**：對於 API，建議使用 JWT 或 OAuth 2.0 等更安全的認證方式。

4. **速率限制**：實作登入失敗次數限制，防止暴力破解。

## 🔧 進階改進建議

```python
# 使用 bcrypt 進行密碼雜湊
import bcrypt

# 雜湊密碼
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

# 驗證密碼
if bcrypt.checkpw(password.encode('utf-8'), hashed):
    print("密碼正確")
```

## 📚 相關資源

- [RFC 7617 - HTTP Basic Authentication](https://tools.ietf.org/html/rfc7617)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Requests Documentation](https://requests.readthedocs.io/)

## 📝 授權

此範例專案僅供學習使用。
