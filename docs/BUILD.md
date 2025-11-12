````markdown
# Podman 建置與執行指南

## 📦 檔案說明

- **Dockerfile**: Podman/Docker 映像建置檔案
- **docker-compose.yml**: Podman Compose 配置檔案
- **.dockerignore**: 忽略不需要複製到映像的檔案

## 🚀 使用方式

### 方法 1: 使用 Podman 直接建置和執行

#### 1. 建置 Podman 映像

```bash
# 使用預設學號建置
podman build -t http-basic-auth-server .

# 或使用自訂學號建置
podman build --build-arg STU_ID=CSIE-NPU -t http-basic-auth-server .
```

#### 2. 執行容器

```bash
# 基本執行
podman run -d -p 3128:3128 --name http-auth-server http-basic-auth-server

# 或使用環境變數覆蓋學號
podman run -d -p 3128:3128 -e STU_ID=CSIE-NPU --name http-auth-server http-basic-auth-server

# 如果需要掛載本地 assets 目錄（方便測試）
podman run -d -p 3128:3128 -v $(pwd)/assets:/app/assets:ro --name http-auth-server http-basic-auth-server
```

#### 3. 查看日誌

```bash
podman logs http-auth-server
```

#### 4. 停止和移除容器

```bash
podman stop http-auth-server
podman rm http-auth-server
```

### 方法 2: 使用 Podman Compose（推薦）

#### 1. 啟動服務

```bash
# 建置並啟動
podman-compose up -d

# 重新建置後啟動
podman-compose up -d --build
```

#### 2. 查看日誌

```bash
# 查看即時日誌
podman-compose logs -f

# 查看最後 50 行日誌
podman-compose logs --tail=50
```

#### 3. 停止服務

```bash
podman-compose down
```

#### 4. 停止並移除所有資源

```bash
podman-compose down -v
```

## 🧪 測試

### 使用 curl 測試

```bash
# 測試未認證（應返回 401）
curl http://localhost:3128/

# 測試使用認證（使用從容器日誌中看到的密碼）
curl -u admin:<從日誌中看到的密碼> http://localhost:3128/

# 範例：假設密碼是 "secret"
curl -u admin:secret http://localhost:3128/
```

### 使用 Python 客戶端測試

先查看容器日誌取得實際密碼：

```bash
podman logs http-auth-server | grep "選擇的密碼"
```

然後在本地執行客戶端：

```bash
python http_basic_auth_client.py
```

## 🔧 自訂學號

### 建置時設定

編輯 `docker-compose.yml` 中的 `STU_ID`：

```yaml
services:
  http-basic-auth-server:
    build:
      args:
        STU_ID: "你的學號"
    environment:
      - STU_ID=你的學號
```

### 或使用環境變數

```bash
# 使用 podman
podman run -d -p 3128:3128 -e STU_ID=你的學號 --name http-auth-server http-basic-auth-server

# 使用 podman-compose
STU_ID=你的學號 podman-compose up -d
```

## 📊 檢查容器狀態

```bash
# 查看運行中的容器
podman ps

# 查看容器詳細資訊
podman inspect http-auth-server

# 進入容器 shell
podman exec -it http-auth-server /bin/bash
```

## 🐛 除錯

### 查看完整日誌

```bash
podman logs http-auth-server
```

### 進入容器檢查

```bash
podman exec -it http-auth-server /bin/bash

# 在容器內檢查檔案
ls -la /app
cat /app/assets/password.txt
env | grep STU_ID
```

### 重新建置映像

```bash
# 清除快取重新建置
podman build --no-cache -t http-basic-auth-server .

# 或使用 podman-compose
podman-compose build --no-cache
```

## 🧹 清理資源

```bash
# 停止並移除容器
podman stop http-auth-server && podman rm http-auth-server

# 移除映像
podman rmi http-basic-auth-server

# 使用 podman-compose 清理
podman-compose down --rmi all -v
```

## 📝 注意事項

1. **Port 3128**: 確保本地 port 3128 沒有被占用
2. **密碼**: 容器啟動時會在日誌中顯示選擇的密碼
3. **學號**: STU_ID 會影響密碼的選擇，相同學號會選擇相同密碼
4. **assets 目錄**: 確保 assets/password.txt 存在且可讀

## 🌐 訪問服務

容器啟動後，可通過以下方式訪問：

- **本地**: http://localhost:3128/
- **容器內**: http://0.0.0.0:3128/

記得使用正確的帳號密碼進行認證！
