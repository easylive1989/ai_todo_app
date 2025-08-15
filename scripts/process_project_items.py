#!/usr/bin/env python3
"""
GitHub Project Items 處理器
用於 GitHub Actions，單次執行版本的 Project 監聽器
"""

import os
import json
import requests
from datetime import datetime, timedelta
from typing import Set, Dict, Any, List


class GitHubProjectProcessor:
    def __init__(self, owner: str, repo: str, project_number: int, token: str = None):
        """
        初始化 GitHub Project 處理器
        
        Args:
            owner: GitHub 組織或用戶名
            repo: 儲存庫名稱
            project_number: Project 編號
            token: GitHub Token
        """
        self.owner = owner
        self.repo = repo
        self.project_number = project_number
        self.token = token or os.getenv('GITHUB_TOKEN')
        
        if not self.token:
            raise ValueError("GitHub token 必須設置在 GITHUB_TOKEN 環境變數中")
        
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Accept': 'application/vnd.github.v3+json',
            'X-GitHub-Api-Version': '2022-11-28'
        }
        
        # GraphQL API endpoint
        self.graphql_url = 'https://api.github.com/graphql'
        
        # Discord webhook URL
        self.discord_webhook_url = os.getenv('DISCORD_WEBHOOK_URL')
        
        # Project 欄位資訊
        self.project_id = None
        self.status_field_id = None
        self.review_option_id = None
        self.backlog_option_id = None
        
        # 已處理的 items 檔案路徑
        self.processed_items_file = 'processed_items.json'
        
        # 初始化時獲取 Project 欄位資訊
        self._initialize_project_fields()
    
    def _initialize_project_fields(self):
        """初始化 Project 欄位資訊，獲取 Status 欄位和各狀態選項的 ID"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🔄 正在獲取 Project 欄位資訊...")
            
            query = """
            query($owner: String!, $repo: String!, $projectNumber: Int!) {
              repository(owner: $owner, name: $repo) {
                projectV2(number: $projectNumber) {
                  id
                  fields(first: 20) {
                    nodes {
                      ... on ProjectV2Field {
                        id
                        name
                      }
                      ... on ProjectV2SingleSelectField {
                        id
                        name
                        options {
                          id
                          name
                        }
                      }
                    }
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
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法獲取 Project 欄位資訊: {response.status_code}")
                return
            
            data = response.json()
            
            if 'errors' in data:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 獲取欄位資訊時發生錯誤: {data['errors']}")
                return
            
            project = data.get('data', {}).get('repository', {}).get('projectV2', {})
            self.project_id = project.get('id')
            
            # 尋找 Status 欄位和選項
            for field in project.get('fields', {}).get('nodes', []):
                if field and field.get('name') == 'Status':
                    self.status_field_id = field.get('id')
                    options = field.get('options', [])
                    for option in options:
                        if option.get('name') == 'Review':
                            self.review_option_id = option.get('id')
                        elif option.get('name') == 'Backlog':
                            self.backlog_option_id = option.get('id')
            
            if self.project_id and self.status_field_id and self.review_option_id and self.backlog_option_id:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ✅ 成功獲取 Project 欄位資訊")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法找到 Status 欄位或必要的選項 (Review/Backlog)")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 初始化 Project 欄位時發生錯誤: {str(e)}")
    
    def load_processed_items(self) -> Dict[str, datetime]:
        """載入已處理的 items 清單"""
        try:
            if os.path.exists(self.processed_items_file):
                with open(self.processed_items_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    # 將字串時間戳轉換為 datetime 物件
                    processed_items = {}
                    for item_id, timestamp_str in data.items():
                        try:
                            processed_items[item_id] = datetime.fromisoformat(timestamp_str)
                        except ValueError:
                            # 如果時間格式有問題，跳過這個項目
                            continue
                    return processed_items
            return {}
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 載入已處理項目時發生錯誤: {str(e)}")
            return {}
    
    def save_processed_items(self, processed_items: Dict[str, datetime]):
        """儲存已處理的 items 清單"""
        try:
            # 清理超過 30 天的記錄
            cutoff_date = datetime.now() - timedelta(days=30)
            cleaned_items = {
                item_id: timestamp 
                for item_id, timestamp in processed_items.items() 
                if timestamp > cutoff_date
            }
            
            # 將 datetime 物件轉換為字串
            data = {
                item_id: timestamp.isoformat() 
                for item_id, timestamp in cleaned_items.items()
            }
            
            with open(self.processed_items_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 💾 已儲存 {len(data)} 個處理記錄")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 儲存已處理項目時發生錯誤: {str(e)}")
    
    def get_project_items(self) -> Dict[str, Any]:
        """透過 GraphQL API 獲取 Project 的所有 Items"""
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
                        optionId
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
    
    def _is_item_in_backlog(self, item: Dict[str, Any]) -> bool:
        """檢查 item 是否處於 Backlog 狀態"""
        if not self.backlog_option_id:
            return True
        
        field_values = item.get('fieldValues', {}).get('nodes', [])
        for field in field_values:
            if field and field.get('field', {}).get('name') == 'Status':
                option_id = field.get('optionId')
                return option_id == self.backlog_option_id
        
        return True
    
    def update_item_status(self, item_id: str, status: str = 'Review') -> bool:
        """更新 Project Item 的狀態"""
        if not all([self.project_id, self.status_field_id, self.review_option_id]):
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 缺少必要的 Project 欄位資訊，無法更新狀態")
            return False
        
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📝 正在更新 Item 狀態為 {status}...")
            
            mutation = """
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
              updateProjectV2ItemFieldValue(
                input: {
                  projectId: $projectId
                  itemId: $itemId
                  fieldId: $fieldId
                  value: {
                    singleSelectOptionId: $optionId
                  }
                }
              ) {
                projectV2Item {
                  id
                }
              }
            }
            """
            
            variables = {
                'projectId': self.project_id,
                'itemId': item_id,
                'fieldId': self.status_field_id,
                'optionId': self.review_option_id
            }
            
            response = requests.post(
                self.graphql_url,
                headers=self.headers,
                json={'query': mutation, 'variables': variables}
            )
            
            if response.status_code != 200:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 更新狀態失敗: {response.status_code}")
                return False
            
            data = response.json()
            
            if 'errors' in data:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 更新狀態時發生錯誤: {data['errors']}")
                return False
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ✅ 成功將 Item 狀態更新為 {status}")
            return True
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 更新狀態時發生錯誤: {str(e)}")
            return False
    
    def send_discord_notification(self, item: Dict[str, Any], new_item: bool = True, status_updated: bool = False):
        """發送 Discord 通知"""
        if not self.discord_webhook_url:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 未設置 Discord webhook URL，跳過通知")
            return
            
        try:
            content = item.get('content', {})
            title = content.get('title', '無標題')
            item_type = 'Issue'
            
            if content:
                if 'number' in content:
                    item_type = 'Issue' if 'pull_request' not in content.get('url', '') else 'Pull Request'
                else:
                    item_type = 'Draft Issue'
            
            # 建立 Discord Embed
            if new_item:
                embed_title = f"🆕 發現新的 Backlog 任務"
                if status_updated:
                    embed_title += " (已加入處理佇列)"
            else:
                embed_title = f"🔄 任務狀態更新"
            
            embed = {
                "title": embed_title,
                "description": f"**{item_type}:** {title}",
                "color": 0x00ff00,
                "fields": [],
                "timestamp": datetime.utcnow().isoformat(),
                "footer": {
                    "text": f"GitHub Project Monitor - {self.owner}/{self.repo}"
                }
            }
            
            # 加入額外資訊
            if 'number' in content:
                embed["fields"].append({
                    "name": "編號",
                    "value": f"#{content.get('number')}",
                    "inline": True
                })
                embed["fields"].append({
                    "name": "狀態",
                    "value": content.get('state', 'unknown'),
                    "inline": True
                })
                if content.get('url'):
                    embed["fields"].append({
                        "name": "連結",
                        "value": f"[查看 {item_type}]({content.get('url')})",
                        "inline": False
                    })
            
            # 如果狀態已更新
            if status_updated:
                embed["fields"].append({
                    "name": "Project 狀態",
                    "value": "🔍 已準備進行 Claude 處理",
                    "inline": True
                })
            
            # 如果有 body，加入預覽
            if 'body' in content and content.get('body'):
                body_preview = content.get('body', '')[:200]
                embed["fields"].append({
                    "name": "內容預覽",
                    "value": f"{body_preview}{'...' if len(content.get('body', '')) > 200 else ''}",
                    "inline": False
                })
            
            # 準備 Discord webhook payload
            payload = {
                "embeds": [embed],
                "username": "GitHub Project Monitor",
                "avatar_url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"
            }
            
            # 發送到 Discord
            response = requests.post(
                self.discord_webhook_url,
                json=payload,
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code in [200, 204]:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📨 Discord 通知已發送")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ Discord 通知發送失敗: {response.status_code}")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 發送 Discord 通知時發生錯誤: {str(e)}")
    
    def extract_task_content(self, item: Dict[str, Any]) -> str:
        """提取 Item 的任務內容"""
        content = item.get('content', {})
        
        title = content.get('title', '')
        body = content.get('body', '')
        
        if title and body:
            return f"{title}\n\n{body}"
        elif title:
            return title
        elif body:
            return body
        else:
            return "無法提取任務內容"
    
    def process_new_items(self) -> List[Dict[str, Any]]:
        """處理新的 items，回傳需要由 Claude 處理的任務清單"""
        try:
            # 載入已處理的 items
            processed_items = self.load_processed_items()
            
            # 獲取 Project 數據
            project_data = self.get_project_items()
            
            if not project_data:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 無法獲取 Project 數據")
                return []
            
            items = project_data.get('items', {}).get('nodes', [])
            current_items = {item['id']: item for item in items if item}
            
            # 尋找新的 Backlog items
            new_backlog_items = []
            
            for item_id, item in current_items.items():
                # 跳過已處理的 items
                if item_id in processed_items:
                    continue
                
                # 只處理 Backlog 狀態的 items
                if not self._is_item_in_backlog(item):
                    # 標記為已處理但不執行任務
                    processed_items[item_id] = datetime.now()
                    continue
                
                content = item.get('content', {})
                title = content.get('title', 'No title')
                
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🆕 發現新的 Backlog Item: {title}")
                
                # 提取任務內容
                task_content = self.extract_task_content(item)
                if task_content and task_content != "無法提取任務內容":
                    new_backlog_items.append({
                        'item_id': item_id,
                        'item_data': item,
                        'task_content': task_content
                    })
                    
                    # 發送 Discord 通知
                    self.send_discord_notification(item, new_item=True)
                else:
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法提取有效的任務內容，跳過處理")
                
                # 標記為已處理
                processed_items[item_id] = datetime.now()
            
            # 儲存處理狀態
            self.save_processed_items(processed_items)
            
            if new_backlog_items:
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📋 共找到 {len(new_backlog_items)} 個新的待處理任務")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ✅ 沒有新的 Backlog 任務需要處理")
            
            return new_backlog_items
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 處理新項目時發生錯誤: {str(e)}")
            return []
    
    def create_task_output(self, tasks: List[Dict[str, Any]]) -> str:
        """建立任務輸出檔案供 GitHub Actions 使用"""
        if not tasks:
            return ""
        
        # 建立任務摘要
        task_summaries = []
        for i, task in enumerate(tasks, 1):
            content = task['task_content']
            # 限制內容長度用於輸出
            summary = content[:100] + "..." if len(content) > 100 else content
            task_summaries.append(f"Task {i}: {summary}")
        
        # 合併所有任務內容
        all_tasks_content = "\n\n".join([
            f"## Task {i}: {task['item_data'].get('content', {}).get('title', 'Untitled')}\n{task['task_content']}"
            for i, task in enumerate(tasks, 1)
        ])
        
        return all_tasks_content


def main():
    """主函數"""
    # GitHub 設定
    owner = 'easylive1989'
    repo = 'ai_todo_app'
    project_number = 5
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🚀 開始處理 GitHub Project Items")
        print(f"   📂 Repository: {owner}/{repo}")
        print(f"   📋 Project: #{project_number}")
        print("=" * 50)
        
        # 創建處理器實例
        processor = GitHubProjectProcessor(
            owner=owner,
            repo=repo,
            project_number=project_number
        )
        
        # 處理新的 items
        new_tasks = processor.process_new_items()
        
        # 如果有新任務，建立輸出檔案給 GitHub Actions
        if new_tasks:
            task_content = processor.create_task_output(new_tasks)
            
            # 寫入檔案供後續步驟使用
            with open('claude_tasks.txt', 'w', encoding='utf-8') as f:
                f.write(task_content)
            
            print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📝 已建立 claude_tasks.txt，包含 {len(new_tasks)} 個任務")
            
            # 設定 GitHub Actions 輸出
            github_output = os.getenv('GITHUB_OUTPUT')
            if github_output:
                with open(github_output, 'a', encoding='utf-8') as f:
                    f.write(f"has_tasks=true\n")
                    f.write(f"task_count={len(new_tasks)}\n")
            
            # 更新所有任務的狀態為 Review（表示已加入處理佇列）
            for task in new_tasks:
                success = processor.update_item_status(task['item_id'])
                if success:
                    # 發送狀態更新通知
                    processor.send_discord_notification(
                        task['item_data'], 
                        new_item=False, 
                        status_updated=True
                    )
        else:
            # 設定 GitHub Actions 輸出
            github_output = os.getenv('GITHUB_OUTPUT')
            if github_output:
                with open(github_output, 'a', encoding='utf-8') as f:
                    f.write(f"has_tasks=false\n")
                    f.write(f"task_count=0\n")
        
        print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ✅ 處理完成")
        
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 執行錯誤: {str(e)}")
        
        # 設定 GitHub Actions 輸出（錯誤狀態）
        github_output = os.getenv('GITHUB_OUTPUT')
        if github_output:
            with open(github_output, 'a', encoding='utf-8') as f:
                f.write(f"has_tasks=false\n")
                f.write(f"task_count=0\n")
        
        exit(1)


if __name__ == '__main__':
    main()