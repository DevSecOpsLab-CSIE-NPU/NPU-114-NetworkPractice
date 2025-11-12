#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定變數
IMAGE_NAME="http-basic-auth-server"
CONTAINER_NAME="http-auth-server"
# 從命令列參數讀取學號，如果沒有提供則使用預設值 "CSIE-NPU"
STU_ID="${1:-CSIE-NPU}"
EXPORT_FILE="http-basic-auth-server.tar"
COMPRESSED_FILE="http-basic-auth-server.tar.bz2"
ASSETS_DIR="./assets"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker 容器建置與匯出腳本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 顯示使用的學號
echo -e "${YELLOW}使用學號: ${STU_ID}${NC}"
if [ "$STU_ID" = "CSIE-NPU" ]; then
    echo -e "${YELLOW}提示: 可以使用 ./build_and_export.sh <學號> 來指定其他學號${NC}"
fi
echo ""

# 檢查 Docker 是否已安裝
if ! command -v docker &> /dev/null; then
    echo -e "${RED}錯誤: Docker 未安裝！${NC}"
    exit 1
fi

# 檢查 pbzip2 是否已安裝
if ! command -v pbzip2 &> /dev/null; then
    echo -e "${YELLOW}警告: pbzip2 未安裝，正在嘗試安裝...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install pbzip2
        else
            echo -e "${RED}錯誤: Homebrew 未安裝，無法自動安裝 pbzip2${NC}"
            echo -e "${YELLOW}請執行: brew install pbzip2${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y pbzip2
        elif command -v yum &> /dev/null; then
            sudo yum install -y pbzip2
        else
            echo -e "${RED}錯誤: 無法自動安裝 pbzip2${NC}"
            exit 1
        fi
    fi
fi

# 建立 assets 目錄
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}建立 assets 目錄...${NC}"
    mkdir -p "$ASSETS_DIR"
fi

# 步驟 1: 停止並移除舊的容器（如果存在）
echo -e "${YELLOW}[1/6] 清理舊的容器...${NC}"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "  停止容器 ${CONTAINER_NAME}..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    echo "  移除容器 ${CONTAINER_NAME}..."
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# 步驟 2: 移除舊的映像（如果存在）
echo -e "${YELLOW}[2/6] 清理舊的映像...${NC}"
if docker images --format '{{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "  移除映像 ${IMAGE_NAME}..."
    docker rmi "$IMAGE_NAME" 2>/dev/null || true
fi

# 步驟 3: 建置 Docker 映像
echo -e "${YELLOW}[3/6] 建置 Docker 映像...${NC}"
echo "  使用學號: ${STU_ID}"
if docker build --build-arg STU_ID="$STU_ID" -t "$IMAGE_NAME" .; then
    echo -e "${GREEN}  ✓ 映像建置成功${NC}"
else
    echo -e "${RED}  ✗ 映像建置失敗${NC}"
    exit 1
fi

# 步驟 4: 啟動容器（測試）
echo -e "${YELLOW}[4/6] 啟動容器進行測試...${NC}"
if docker run -d -p 3128:3128 --name "$CONTAINER_NAME" "$IMAGE_NAME"; then
    echo -e "${GREEN}  ✓ 容器啟動成功${NC}"
    echo "  等待容器初始化..."
    sleep 3
    
    # 顯示容器日誌
    echo -e "${BLUE}  容器日誌:${NC}"
    docker logs "$CONTAINER_NAME" 2>&1 | head -n 20
    
    # 停止容器
    echo "  停止測試容器..."
    docker stop "$CONTAINER_NAME" > /dev/null
else
    echo -e "${RED}  ✗ 容器啟動失敗${NC}"
    exit 1
fi

# 步驟 5: 匯出 Docker 映像
echo -e "${YELLOW}[5/6] 匯出 Docker 映像...${NC}"
echo "  匯出映像到 ${EXPORT_FILE}..."
if docker save "$IMAGE_NAME" -o "$EXPORT_FILE"; then
    echo -e "${GREEN}  ✓ 映像匯出成功${NC}"
    EXPORT_SIZE=$(du -h "$EXPORT_FILE" | cut -f1)
    echo "  檔案大小: ${EXPORT_SIZE}"
else
    echo -e "${RED}  ✗ 映像匯出失敗${NC}"
    exit 1
fi

# 步驟 6: 使用 pbzip2 壓縮
echo -e "${YELLOW}[6/6] 使用 pbzip2 壓縮映像...${NC}"
echo "  壓縮中（使用多核心並行處理）..."
if pbzip2 -f -v "$EXPORT_FILE"; then
    echo -e "${GREEN}  ✓ 壓縮成功${NC}"
    
    # 移動到 assets 目錄
    mv "${EXPORT_FILE}.bz2" "${ASSETS_DIR}/${COMPRESSED_FILE}"
    
    COMPRESSED_SIZE=$(du -h "${ASSETS_DIR}/${COMPRESSED_FILE}" | cut -f1)
    echo "  壓縮後檔案: ${ASSETS_DIR}/${COMPRESSED_FILE}"
    echo "  壓縮後大小: ${COMPRESSED_SIZE}"
else
    echo -e "${RED}  ✗ 壓縮失敗${NC}"
    exit 1
fi

# 清理測試容器
echo -e "${YELLOW}清理測試容器...${NC}"
docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 所有步驟完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}摘要資訊:${NC}"
echo "  映像名稱: ${IMAGE_NAME}"
echo "  學號: ${STU_ID}"
echo "  壓縮檔案: ${ASSETS_DIR}/${COMPRESSED_FILE}"
echo "  壓縮檔案大小: ${COMPRESSED_SIZE}"
echo ""
echo -e "${BLUE}如何使用壓縮檔案:${NC}"
echo "  1. 解壓縮: pbzip2 -d -k ${ASSETS_DIR}/${COMPRESSED_FILE}"
echo "  2. 載入映像: docker load -i ${ASSETS_DIR}/${EXPORT_FILE}"
echo "  3. 執行容器: docker run -d -p 3128:3128 --name ${CONTAINER_NAME} ${IMAGE_NAME}"
echo ""
