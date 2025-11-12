#!/usr/bin/env python3
"""
HTTP Basic Authentication Client 範例
展示如何使用 requests 庫發送 HTTP Basic Auth 請求
"""

import requests
from requests.auth import HTTPBasicAuth
import base64
import random
import os

# 學號變數 - 從環境變數讀取，如果沒有則使用預設值
STU_ID = os.environ.get('STU_ID', 'CSIE-NPU')

# 從 assets/password.txt 讀取密碼並根據學號隨機選擇
def get_password_from_file():
    """根據學號從 password.txt 中選擇一個密碼"""
    password_file = os.path.join('assets', 'password.txt')
    
    try:
        with open(password_file, 'r', encoding='utf-8') as f:
            passwords = [line.strip() for line in f if line.strip()]
        
        # 使用學號作為隨機種子，確保每次執行選擇相同的密碼
        random.seed(int(STU_ID))
        selected_password = random.choice(passwords).lower()  # 轉換為小寫
        
        return selected_password
    except FileNotFoundError:
        print(f"警告: 找不到 {password_file}，使用預設密碼")
        return 'admin123'

# 取得 admin 密碼
ADMIN_PASSWORD = get_password_from_file()


def test_without_auth():
    """測試未提供認證"""
    print("\n" + "=" * 50)
    print("1. 測試未提供認證（應返回 401）")
    print("=" * 50)
    
    url = "http://localhost:3128/"
    response = requests.get(url)
    
    print(f"狀態碼: {response.status_code}")
    print(f"回應內容: {response.text}")


def test_with_correct_auth():
    """測試使用正確認證（方法 1: HTTPBasicAuth）"""
    print("\n" + "=" * 50)
    print("2. 測試使用正確認證（學號帳號）")
    print("=" * 50)
    
    url = "http://localhost:3128/"
    response = requests.get(url, auth=HTTPBasicAuth(STU_ID, ADMIN_PASSWORD))
    
    print(f"使用帳號: {STU_ID}")
    print(f"使用密碼: [已隱藏]")
    print(f"狀態碼: {response.status_code}")
    if response.status_code == 200:
        print(f"回應內容類型: {response.headers.get('Content-Type')}")
        if 'html' in response.headers.get('Content-Type', ''):
            print("成功！收到 HTML 頁面")
        else:
            print(f"回應內容: {response.text[:200]}")
    else:
        print(f"回應內容: {response.text}")


def test_with_manual_header():
    """測試手動設置 Authorization header"""
    print("\n" + "=" * 50)
    print("3. 測試手動設置 Authorization header（學號帳號）")
    print("=" * 50)
    
    url = "http://localhost:3128/"
    
    # 手動編碼並設置 Authorization header
    credentials_str = f'{STU_ID}:{ADMIN_PASSWORD}'
    credentials = base64.b64encode(credentials_str.encode('utf-8')).decode('utf-8')
    headers = {
        'Authorization': f'Basic {credentials}'
    }
    
    response = requests.get(url, headers=headers)
    
    print(f"使用帳號: {STU_ID}")
    print(f"使用密碼: [已隱藏]")
    print(f"Authorization Header: Basic [已隱藏]")
    print(f"狀態碼: {response.status_code}")
    if response.status_code == 200:
        print(f"回應內容類型: {response.headers.get('Content-Type')}")
        if 'html' in response.headers.get('Content-Type', ''):
            print("成功！收到 HTML 頁面")
        else:
            print(f"回應內容: {response.text[:200]}")
    else:
        print(f"回應內容: {response.text}")


def test_with_wrong_credentials():
    """測試錯誤的認證資訊"""
    print("\n" + "=" * 50)
    print("4. 測試錯誤的認證資訊")
    print("=" * 50)
    
    url = "http://localhost:3128/"
    response = requests.get(url, auth=HTTPBasicAuth(STU_ID, 'wrongpassword'))
    
    print(f"使用帳號: {STU_ID}")
    print(f"使用密碼: wrongpassword")
    print(f"狀態碼: {response.status_code}")
    print(f"回應內容: {response.text}")


def main():
    """主函數：執行所有測試"""
    print("=" * 50)
    print("HTTP Basic Auth Client 測試開始")
    print("請確保伺服器已在 http://localhost:3128 運行")
    print("=" * 50)
    print(f"\n學號: {STU_ID}")
    print(f"帳號: {STU_ID}")
    print(f"密碼: [已隱藏 - 請自行猜測]")
    
    try:
        # 測試各種情況
        test_without_auth()
        test_with_correct_auth()
        test_with_manual_header()
        test_with_wrong_credentials()
        
        print("\n" + "=" * 50)
        print("所有測試完成！")
        print("=" * 50)
        
    except requests.exceptions.ConnectionError:
        print("\n錯誤：無法連接到伺服器")
        print("請先執行 http_basic_auth_server.py")


if __name__ == '__main__':
    main()
