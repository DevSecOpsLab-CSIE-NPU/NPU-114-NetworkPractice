````markdown
# Podman 建置與匯出腳本說明

## 📝 腳本說明

### 1. build_and_export.sh
自動化建置 Podman 容器並匯出壓縮檔案的腳本。

**功能：**
- 清理舊的容器和映像
- 建置新的 Podman 映像（包含 STU_ID）
- 啟動容器進行測試
- 匯出 Podman 映像為 tar 檔案
- 使用 pbzip2 進行多核心並行壓縮
- 將壓縮檔案儲存到 `assets/` 目錄

### 2. load_and_run.sh
從壓縮檔案載入並執行容器的腳本。

**功能：**
- 解壓縮映像檔案
- 載入 Podman 映像
- 清理舊容器
- 啟動新容器

## 🚀 使用方式

### 安裝 pbzip2

**macOS:**
```bash
brew install pbzip2
```

**Ubuntu/Debian:**
```bash
sudo apt-get install pbzip2
```

**CentOS/RHEL:**
```bash
sudo yum install pbzip2
```

### 建置並匯出容器

```bash
# 確保腳本有執行權限
chmod +x build_and_export.sh

# 執行建置腳本
./build_and_export.sh
```

**腳本執行步驟：**
1. ✓ 清理舊的容器
2. ✓ 清理舊的映像
3. ✓ 建置 Podman 映像（傳入 STU_ID=CSIE-NPU）
4. ✓ 啟動容器測試
5. ✓ 匯出映像為 tar 檔案
6. ✓ 使用 pbzip2 壓縮
7. ✓ 儲存到 `assets/http-basic-auth-server.tar.bz2`

### 從壓縮檔案載入並執行

```bash
# 確保腳本有執行權限
chmod +x load_and_run.sh

# 執行載入腳本
./load_and_run.sh
```

**腳本執行步驟：**
1. ✓ 解壓縮映像檔案
2. ✓ 載入 Podman 映像
3. ✓ 清理舊容器
4. ✓ 啟動新容器

## 📦 輸出檔案

執行 `build_and_export.sh` 後會產生：

```
assets/
└── http-basic-auth-server.tar.bz2  (壓縮後的 Podman 映像)
```

## 🔧 手動操作

### 手動解壓縮並載入

```bash
# 1. 解壓縮
pbzip2 -d -k assets/http-basic-auth-server.tar.bz2

# 2. 載入映像
podman load -i assets/http-basic-auth-server.tar

# 3. 執行容器
podman run -d -p 3128:3128 --name http-auth-server http-basic-auth-server

# 4. 查看日誌
podman logs http-auth-server
```

### 手動建置

```bash
# 1. 建置映像
podman build --build-arg STU_ID=CSIE-NPU -t http-basic-auth-server .

# 2. 匯出映像
podman save http-basic-auth-server -o http-basic-auth-server.tar

# 3. 壓縮
pbzip2 -f http-basic-auth-server.tar

# 4. 移動到 assets
mv http-basic-auth-server.tar.bz2 assets/
```

## 🧪 測試

容器啟動後：

```bash
# 查看容器狀態
podman ps

# 查看日誌（會顯示學號和密碼）
podman logs http-auth-server

# 測試連線
curl http://localhost:3128/

# 使用認證測試（從日誌中取得密碼）
curl -u CSIE-NPU:<密碼> http://localhost:3128/

# 或在瀏覽器中開啟
open http://localhost:3128/  # macOS
```

## 📊 檔案大小比較

一般來說：
- 原始映像大小：~200-300 MB
- tar 檔案：~200-300 MB
- bz2 壓縮後：~50-80 MB（壓縮率約 70-75%）

使用 pbzip2 的優勢：
- 多核心並行處理，速度比 bzip2 快 2-8 倍
- 壓縮率與 bzip2 相同
- 向後相容於 bzip2

## 🐛 問題排除

### pbzip2 未安裝
```bash
# macOS
brew install pbzip2

# Linux
sudo apt-get install pbzip2  # Debian/Ubuntu
sudo yum install pbzip2      # CentOS/RHEL
```

### Podman 未啟動
```bash
# 檢查 Podman 狀態
podman ps

# Linux - 啟動 Podman 服務（如果需要）
systemctl --user start podman
```

### Port 3128 被占用
```bash
# 查看占用的程序
lsof -i :3128

# 或使用其他 port
podman run -d -p 8080:3128 --name http-auth-server http-basic-auth-server
```

## 🧹 清理

```bash
# 停止並移除容器
podman stop http-auth-server
podman rm http-auth-server

# 移除映像
podman rmi http-basic-auth-server

# 清理系統（謹慎使用）
podman system prune -a
```

## 📝 注意事項

1. **儲存空間**：確保有足夠的磁碟空間（至少 500MB）
2. **網路連線**：首次建置需要下載 Python 基礎映像
3. **權限**：Podman 可以無需 root 執行（rootless mode）
4. **STU_ID**：學號會影響密碼選擇，確保一致性

## 🎯 快速參考

```bash
# 完整流程
./build_and_export.sh          # 建置並匯出
./load_and_run.sh              # 載入並執行

# 查看資訊
podman logs http-auth-server   # 查看學號和密碼
podman ps                      # 查看運行狀態

# 訪問服務
curl -u CSIE-NPU:<密碼> http://localhost:3128/
```

````

## 🧹 清理

```bash
# 停止並移除容器
docker stop http-auth-server
docker rm http-auth-server

# 移除映像
docker rmi http-basic-auth-server

# 清理系統（謹慎使用）
docker system prune -a
```

## 📝 注意事項

1. **儲存空間**：確保有足夠的磁碟空間（至少 500MB）
2. **網路連線**：首次建置需要下載 Python 基礎映像
3. **權限**：某些系統可能需要 sudo 執行 Docker 指令
4. **STU_ID**：學號會影響密碼選擇，確保一致性

## 🎯 快速參考

```bash
# 完整流程
./build_and_export.sh          # 建置並匯出
./load_and_run.sh              # 載入並執行

# 查看資訊
docker logs http-auth-server   # 查看學號和密碼
docker ps                      # 查看運行狀態

# 訪問服務
curl -u CSIE-NPU:<密碼> http://localhost:3128/
```
