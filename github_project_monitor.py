#!/usr/bin/env python3
"""
GitHub Project Item 監聽器
持續監聽 easylive1989/ai_todo_app 的 GitHub Project #5 是否有新的 Item 被創建
"""

import os
import time
from datetime import datetime
from typing import Set, Dict, Any
import requests
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()


class GitHubProjectMonitor:
    def __init__(self, owner: str, repo: str, project_number: int, token: str = None):
        """
        初始化 GitHub Project 監聽器
        
        Args:
            owner: GitHub 組織或用戶名 (easylive1989)
            repo: 儲存庫名稱 (ai_todo_app)
            project_number: Project 編號 (5)
            token: GitHub Personal Access Token
        """
        self.owner = owner
        self.repo = repo
        self.project_number = project_number
        self.token = token or os.getenv('GITHUB_TOKEN')
        
        if not self.token:
            raise ValueError("GitHub token 必須設置在 .env 檔案的 GITHUB_TOKEN 環境變數中")
        
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Accept': 'application/vnd.github.v3+json',
            'X-GitHub-Api-Version': '2022-11-28'
        }
        
        # GraphQL API endpoint
        self.graphql_url = 'https://api.github.com/graphql'
        
        # 儲存已知的 item IDs
        self.known_items: Set[str] = set()
        self.first_run = True
    
    def get_project_items(self) -> Dict[str, Any]:
        """
        透過 GraphQL API 獲取 Project 的所有 Items
        """
        query = """
        query($owner: String!, $repo: String!, $projectNumber: Int!) {
          repository(owner: $owner, name: $repo) {
            projectV2(number: $projectNumber) {
              title
              items(first: 100) {
                nodes {
                  id
                  createdAt
                  updatedAt
                  content {
                    ... on Issue {
                      title
                      number
                      state
                      url
                    }
                    ... on PullRequest {
                      title
                      number
                      state
                      url
                    }
                    ... on DraftIssue {
                      title
                      body
                    }
                  }
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldTextValue {
                        text
                        field {
                          ... on ProjectV2Field {
                            name
                          }
                        }
                      }
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        name
                        field {
                          ... on ProjectV2SingleSelectField {
                            name
                          }
                        }
                      }
                    }
                  }
                }
                totalCount
              }
            }
          }
        }
        """
        
        variables = {
            'owner': self.owner,
            'repo': self.repo,
            'projectNumber': self.project_number
        }
        
        response = requests.post(
            self.graphql_url,
            headers=self.headers,
            json={'query': query, 'variables': variables}
        )
        
        if response.status_code != 200:
            raise Exception(f"GraphQL query failed: {response.status_code} - {response.text}")
        
        data = response.json()
        
        if 'errors' in data:
            raise Exception(f"GraphQL errors: {data['errors']}")
        
        return data.get('data', {}).get('repository', {}).get('projectV2', {})
    
    def check_for_new_items(self):
        """
        檢查是否有新的 Items 被創建
        """
        try:
            project_data = self.get_project_items()
            
            if not project_data:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 無法獲取 Project 數據")
                return
            
            items = project_data.get('items', {}).get('nodes', [])
            current_items = {item['id']: item for item in items if item}
            
            # 第一次執行時，記錄所有現有的 items
            if self.first_run:
                self.known_items = set(current_items.keys())
                project_title = project_data.get('title', 'Unknown')
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🚀 開始監聽 Project: {project_title}")
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📊 目前有 {len(self.known_items)} 個 items")
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⏰ 每 60 秒檢查一次新的 items")
                print("-" * 50)
                self.first_run = False
                return
            
            # 檢查新的 items
            new_item_ids = set(current_items.keys()) - self.known_items
            
            if new_item_ids:
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🆕 發現 {len(new_item_ids)} 個新的 Item!")
                print("=" * 50)
                
                for item_id in new_item_ids:
                    item = current_items[item_id]
                    content = item.get('content', {})
                    
                    if content:
                        # 判斷 item 類型
                        if 'number' in content:
                            item_type = 'Issue' if 'pull_request' not in content.get('url', '') else 'Pull Request'
                        else:
                            item_type = 'Draft Issue'
                        
                        title = content.get('title', 'No title')
                        
                        print(f"\n📌 新 {item_type}: {title}")
                        
                        if 'number' in content:
                            print(f"   🔢 編號: #{content.get('number')}")
                            print(f"   📈 狀態: {content.get('state', 'unknown')}")
                            print(f"   🔗 URL: {content.get('url', 'N/A')}")
                        
                        if 'body' in content and content.get('body'):
                            body_preview = content.get('body', '')[:150]
                            print(f"   📝 內容預覽: {body_preview}...")
                        
                        # 顯示自定義字段
                        field_values = item.get('fieldValues', {}).get('nodes', [])
                        custom_fields = []
                        for field in field_values:
                            if field:
                                field_name = field.get('field', {}).get('name', '')
                                field_value = field.get('text') or field.get('name', '')
                                if field_name and field_value:
                                    custom_fields.append(f"{field_name}: {field_value}")
                        
                        if custom_fields:
                            print("   🏷️  自定義字段:")
                            for field_info in custom_fields:
                                print(f"      - {field_info}")
                        
                        print(f"   📅 創建時間: {item.get('createdAt', 'Unknown')}")
                        print("-" * 30)
                
                # 更新已知的 items
                self.known_items.update(new_item_ids)
                print("=" * 50)
            else:
                # 簡潔的狀態顯示
                print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ 無新 items (共 {len(current_items)} 個)")
        
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 錯誤: {str(e)}")
    
    def start_monitoring(self, interval: int = 60):
        """
        開始監聽 Project
        
        Args:
            interval: 檢查間隔（秒）
        """
        print("🔍 GitHub Project 監聽器")
        print(f"📂 Repository: {self.owner}/{self.repo}")
        print(f"📋 Project: #{self.project_number}")
        print(f"⏱️  檢查間隔: {interval} 秒")
        print("❌ 按 Ctrl+C 停止監聽")
        print("=" * 50)
        
        try:
            while True:
                self.check_for_new_items()
                time.sleep(interval)
        except KeyboardInterrupt:
            print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🛑 監聽已停止")
            print("👋 再見！")


def main():
    """
    主函數 - 配置為監聽 easylive1989/ai_todo_app 的 Project #5
    """
    # 固定配置
    owner = 'easylive1989'
    repo = 'ai_todo_app'
    project_number = 5
    check_interval = 60
    
    try:
        # 創建監聽器實例
        monitor = GitHubProjectMonitor(
            owner=owner,
            repo=repo,
            project_number=project_number
        )
        
        # 開始監聽
        monitor.start_monitoring(interval=check_interval)
        
    except ValueError as e:
        print(f"❌ 配置錯誤: {e}")
        print("💡 請確認 .env 檔案中有設置 GITHUB_TOKEN")
    except Exception as e:
        print(f"❌ 執行錯誤: {e}")


if __name__ == '__main__':
    main()