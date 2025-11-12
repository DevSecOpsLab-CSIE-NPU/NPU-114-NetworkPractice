#!/bin/bash

## 安裝考試環境
# 1) `export GIST_URL=`  <- 老師給的網址 
# 2) `wget -qO- $GIST_URL |sudo bash `

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定變數
IMAGE_NAME="http-basic-auth-server"
CONTAINER_NAME="http-auth-server"
DOWNLOAD_URL="https://github.com/DevSecOpsLab-CSIE-NPU/NPU-114-NetworkPractice/raw/refs/heads/main/assets/http-basic-auth-server.tar.bz2"
COMPRESSED_FILE="./assets/http-basic-auth-server.tar.bz2"
EXPORT_FILE="http-basic-auth-server.tar"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Podman 映像載入與執行腳本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 步驟 1: 下載壓縮檔案
echo -e "${YELLOW}[1/6] 下載映像檔案...${NC}"
# 確保 assets 目錄存在
mkdir -p ./assets

if [ -f "$COMPRESSED_FILE" ]; then
    echo -e "${YELLOW}  檔案已存在,是否重新下載? (y/N)${NC}"
    read -r REDOWNLOAD
    if [[ "$REDOWNLOAD" =~ ^[Yy]$ ]]; then
        rm -f "$COMPRESSED_FILE"
    else
        echo -e "${GREEN}  ✓ 使用現有檔案${NC}"
    fi
fi

if [ ! -f "$COMPRESSED_FILE" ]; then
    echo -e "${YELLOW}  正在從 GitHub 下載...${NC}"
    if curl -L -o "$COMPRESSED_FILE" "$DOWNLOAD_URL"; then
        echo -e "${GREEN}  ✓ 下載成功${NC}"
    else
        echo -e "${RED}  ✗ 下載失敗${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✓ 檔案已存在${NC}"
fi

# 步驟 2: 檢查 pbzip2 是否已安裝
echo -e "${YELLOW}[2/6] 檢查必要工具...${NC}"
if ! command -v pbzip2 &> /dev/null; then
    echo -e "${YELLOW}  pbzip2 未安裝,正在安裝...${NC}"
    
    # 檢測作業系統
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux 系統
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}  使用 apt-get 安裝 pbzip2...${NC}"
            sudo apt-get update && sudo apt-get install -y pbzip2
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            echo -e "${YELLOW}  使用 yum 安裝 pbzip2...${NC}"
            sudo yum install -y pbzip2
        else
            echo -e "${RED}錯誤: 無法識別的 Linux 發行版${NC}"
            echo -e "${YELLOW}請手動安裝 pbzip2${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${YELLOW}  使用 Homebrew 安裝 pbzip2...${NC}"
            brew install pbzip2
        else
            echo -e "${RED}錯誤: 未安裝 Homebrew${NC}"
            echo -e "${YELLOW}請先安裝 Homebrew: https://brew.sh${NC}"
            exit 1
        fi
    else
        echo -e "${RED}錯誤: 不支援的作業系統${NC}"
        exit 1
    fi
    
    # 再次檢查是否安裝成功
    if command -v pbzip2 &> /dev/null; then
        echo -e "${GREEN}  ✓ pbzip2 安裝成功${NC}"
    else
        echo -e "${RED}  ✗ pbzip2 安裝失敗${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✓ pbzip2 已安裝${NC}"
fi

# 檢查 uidmap 是否已安裝 (Podman rootless mode 所需)
if ! command -v newuidmap &> /dev/null || ! command -v newgidmap &> /dev/null; then
    echo -e "${YELLOW}  uidmap 未安裝,正在安裝 (Podman rootless mode 所需)...${NC}"
    
    # 檢測作業系統
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux 系統
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}  使用 apt-get 安裝 uidmap...${NC}"
            sudo apt-get update && sudo apt-get install -y uidmap
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            echo -e "${YELLOW}  使用 yum 安裝 shadow-utils...${NC}"
            sudo yum install -y shadow-utils
        else
            echo -e "${RED}錯誤: 無法識別的 Linux 發行版${NC}"
            echo -e "${YELLOW}請手動安裝 uidmap${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 不需要 uidmap
        echo -e "${YELLOW}  macOS 不需要 uidmap${NC}"
    else
        echo -e "${RED}錯誤: 不支援的作業系統${NC}"
        exit 1
    fi
    
    # 再次檢查是否安裝成功 (僅在 Linux 上)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v newuidmap &> /dev/null && command -v newgidmap &> /dev/null; then
            echo -e "${GREEN}  ✓ uidmap 安裝成功${NC}"
        else
            echo -e "${RED}  ✗ uidmap 安裝失敗${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}  ✓ uidmap 已安裝${NC}"
fi

# 檢查 slirp4netns 是否已安裝 (Podman 網路配置所需)
if ! command -v slirp4netns &> /dev/null; then
    echo -e "${YELLOW}  slirp4netns 未安裝,正在安裝 (Podman 網路配置所需)...${NC}"
    
    # 檢測作業系統
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux 系統
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}  使用 apt-get 安裝 slirp4netns...${NC}"
            sudo apt-get update && sudo apt-get install -y slirp4netns
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            echo -e "${YELLOW}  使用 yum 安裝 slirp4netns...${NC}"
            sudo yum install -y slirp4netns
        else
            echo -e "${RED}錯誤: 無法識別的 Linux 發行版${NC}"
            echo -e "${YELLOW}請手動安裝 slirp4netns${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 不需要 slirp4netns
        echo -e "${YELLOW}  macOS 不需要 slirp4netns${NC}"
    else
        echo -e "${RED}錯誤: 不支援的作業系統${NC}"
        exit 1
    fi
    
    # 再次檢查是否安裝成功 (僅在 Linux 上)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v slirp4netns &> /dev/null; then
            echo -e "${GREEN}  ✓ slirp4netns 安裝成功${NC}"
        else
            echo -e "${RED}  ✗ slirp4netns 安裝失敗${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}  ✓ slirp4netns 已安裝${NC}"
fi

# 檢查 podman 是否已安裝
if ! command -v podman &> /dev/null; then
    echo -e "${YELLOW}  podman 未安裝,正在安裝...${NC}"
    
    # 檢測作業系統
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux 系統
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}  使用 apt-get 安裝 podman...${NC}"
            sudo apt-get update && sudo apt-get install -y podman
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            echo -e "${YELLOW}  使用 yum 安裝 podman...${NC}"
            sudo yum install -y podman
        else
            echo -e "${RED}錯誤: 無法識別的 Linux 發行版${NC}"
            echo -e "${YELLOW}請手動安裝 podman${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${YELLOW}  使用 Homebrew 安裝 podman...${NC}"
            brew install podman
        else
            echo -e "${RED}錯誤: 未安裝 Homebrew${NC}"
            echo -e "${YELLOW}請先安裝 Homebrew: https://brew.sh${NC}"
            exit 1
        fi
    else
        echo -e "${RED}錯誤: 不支援的作業系統${NC}"
        exit 1
    fi
    
    # 再次檢查是否安裝成功
    if command -v podman &> /dev/null; then
        echo -e "${GREEN}  ✓ podman 安裝成功${NC}"
    else
        echo -e "${RED}  ✗ podman 安裝失敗${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✓ podman 已安裝${NC}"
fi

# 步驟 3: 解壓縮
echo -e "${YELLOW}[3/6] 解壓縮映像檔案...${NC}"
# 步驟 3: 解壓縮
echo -e "${YELLOW}[3/6] 解壓縮映像檔案...${NC}"
if pbzip2 -d -k -f "$COMPRESSED_FILE"; then
    echo -e "${GREEN}  ✓ 解壓縮成功${NC}"
    # pbzip2 會將檔案解壓到同目錄,移動到當前目錄
    mv "./assets/${EXPORT_FILE}" "./${EXPORT_FILE}"
else
    echo -e "${RED}  ✗ 解壓縮失敗${NC}"
    exit 1
fi

# 步驟 4: 載入 Podman 映像
echo -e "${YELLOW}[4/6] 載入 Podman 映像...${NC}"
if podman load -i "$EXPORT_FILE"; then
    echo -e "${GREEN}  ✓ 映像載入成功${NC}"
    # 清理解壓後的 tar 檔案
    rm "$EXPORT_FILE"
else
    echo -e "${RED}  ✗ 映像載入失敗${NC}"
    exit 1
fi

# 步驟 5: 詢問學生學號
# 註解: 成績以此登錄為主
echo ""
echo -e "${YELLOW}[5/6] 請輸入學生學號 (成績以此登錄為主):${NC}"

# 確保從終端讀取輸入
STU_ID=""
while [ -z "$STU_ID" ]; do
    echo -n "學號: "
    read -r STU_ID < /dev/tty
    
    # 去除前後空白
    STU_ID=$(echo "$STU_ID" | xargs)
    
    if [ -z "$STU_ID" ]; then
        echo -e "${RED}  ✗ 學號不能為空!請重新輸入。${NC}"
    fi
done

echo -e "${GREEN}  ✓ 學號已登錄: ${STU_ID}${NC}"

# 步驟 6: 停止並移除舊容器
echo -e "${YELLOW}[6/6] 清理舊容器...${NC}"
if podman ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    podman stop "$CONTAINER_NAME" 2>/dev/null || true
    podman rm "$CONTAINER_NAME" 2>/dev/null || true
    echo -e "${GREEN}  ✓ 舊容器已清理${NC}"
fi

# 步驟 7: 啟動新容器 (使用學號作為環境變數)
echo -e "${YELLOW}[7/7] 啟動容器...${NC}"
if podman run -d -p 80:3128 -e STU_ID="$STU_ID" --name "$CONTAINER_NAME" "$IMAGE_NAME"; then
    echo -e "${GREEN}  ✓ 容器啟動成功${NC}"
    sleep 2
    
    # 顯示容器資訊
    echo ""
    echo -e "${BLUE}容器資訊:${NC}"
    podman ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo -e "${BLUE}環境變數:${NC}"
    echo "  STU_ID=${STU_ID}"
    
    echo ""
    echo -e "${BLUE}容器日誌:${NC}"
    podman logs "$CONTAINER_NAME" 2>&1 | head -n 15
else
    echo -e "${RED}  ✗ 容器啟動失敗${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 容器已成功啟動！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}學生資訊:${NC}"
echo "  學號: ${STU_ID}"
echo ""
# 自動偵測主機 IP
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
    HOST_IP="localhost"
fi
echo -e "${BLUE}訪問服務:${NC}"
echo "  URL: http://${HOST_IP}/"
echo ""
echo -e "${BLUE}常用指令:${NC}"
echo "  查看日誌: podman logs -f ${CONTAINER_NAME}"
echo "  停止容器: podman stop ${CONTAINER_NAME}"
echo "  啟動容器: podman start ${CONTAINER_NAME}"
echo "  移除容器: podman rm -f ${CONTAINER_NAME}"
echo ""
