#!/usr/bin/env python3
"""
GitHub Project Item 監聽器
持續監聽 easylive1989/ai_todo_app 的 GitHub Project #5 是否有新的 Item 被創建
"""

import os
import time
import subprocess
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
        
        # Claude Code CLI 設定
        self.claude_cli = os.getenv('CLAUDE_CLI_PATH', 'claude')
        self.project_dir = os.getenv('PROJECT_DIR', os.getcwd())
        
        # Claude Code CLI 是否要求 commit
        self.request_commit = os.getenv('REQUEST_COMMIT', 'true').lower() == 'true'
        
        # Discord webhook URL
        self.discord_webhook_url = 'https://discord.com/api/webhooks/1404465505888108664/GBq0HXWkrAOwGPE2yEprpZxiAbj6D3oaHs9qQTSSYNhDXLrS06CS2HErQojYj1nE8ozt'
        
        # Project 欄位資訊（將在初始化時獲取）
        self.project_id = None
        self.status_field_id = None
        self.review_option_id = None
        self.backlog_option_id = None
        
        # 初始化時獲取 Project 欄位資訊
        self._initialize_project_fields()
    
    def _initialize_project_fields(self):
        """
        初始化 Project 欄位資訊，獲取 Status 欄位和各狀態選項的 ID
        """
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
                print(f"   📋 Project ID: {self.project_id[:10]}...")
                print(f"   📊 Status Field ID: {self.status_field_id[:10]}...")
                print(f"   🔍 Review Option ID: {self.review_option_id[:10]}...")
                print(f"   📝 Backlog Option ID: {self.backlog_option_id[:10]}...")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法找到 Status 欄位或必要的選項 (Review/Backlog)")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 初始化 Project 欄位時發生錯誤: {str(e)}")
    
    def update_item_status(self, item_id: str, status: str = 'Review') -> bool:
        """
        更新 Project Item 的狀態
        
        Args:
            item_id: Project Item 的 ID
            status: 要設定的狀態（預設為 'Review'）
        
        Returns:
            bool: 更新是否成功
        """
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
        """
        檢查 item 是否處於 Backlog 狀態
        
        Args:
            item: Project Item 數據
        
        Returns:
            bool: 是否為 Backlog 狀態
        """
        if not self.backlog_option_id:
            # 如果沒有 Backlog ID，預設允許所有 item（向後相容）
            return True
        
        field_values = item.get('fieldValues', {}).get('nodes', [])
        for field in field_values:
            if field and field.get('field', {}).get('name') == 'Status':
                # 檢查選項 ID 是否匹配
                option_id = field.get('optionId')
                return option_id == self.backlog_option_id
        
        # 如果沒有找到狀態欄位，預設為 True（可能是新創建的 item）
        return True
    
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
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🎯 只監聽 Backlog 狀態的新任務")
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⏰ 每 60 秒檢查一次新的 items")
                print("-" * 50)
                self.first_run = False
                return
            
            # 檢查新的 items
            new_item_ids = set(current_items.keys()) - self.known_items
            
            # 過濾出只有 Backlog 狀態的新 items
            backlog_new_items = []
            for item_id in new_item_ids:
                item = current_items[item_id]
                if self._is_item_in_backlog(item):
                    backlog_new_items.append(item_id)
            
            if backlog_new_items:
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🆕 發現 {len(backlog_new_items)} 個新的 Backlog Item!")
                if len(new_item_ids) > len(backlog_new_items):
                    print(f"   ℹ️ （忽略了 {len(new_item_ids) - len(backlog_new_items)} 個非 Backlog 狀態的 items）")
                print("=" * 50)
                
                for item_id in backlog_new_items:
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
                        
                        # 執行 Claude Code CLI
                        task_content = self.extract_task_content(item)
                        if task_content and task_content != "無法提取任務內容":
                            print(f"\n🚀 開始執行任務...")
                            
                            # 執行 Claude Code (包含自動 commit/push 和 Discord 通知)
                            claude_success = self.run_claude_cli(task_content, item_id, item)
                            
                            if claude_success:
                                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🎉 任務執行完成")
                            else:
                                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 😞 任務執行失敗")
                        else:
                            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法提取有效的任務內容，跳過執行")
                
                # 更新已知的 items（包括所有新 items，不只是 Backlog）
                self.known_items.update(new_item_ids)
                print("=" * 50)
            else:
                # 簡潔的狀態顯示
                if new_item_ids:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ 發現 {len(new_item_ids)} 個新 items，但都不是 Backlog 狀態")
                else:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ 無新 items (共 {len(current_items)} 個)")
        
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 錯誤: {str(e)}")
    
    def send_discord_notification(self, item: Dict[str, Any], success: bool, execution_time: str = None, status_updated: bool = False):
        """
        發送 Discord 通知
        
        Args:
            item: Project Item 數據
            success: 執行是否成功
            execution_time: 執行時間（可選）
            status_updated: 狀態是否已更新為 Review
        """
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
            embed_title = f"✅ 任務執行{'成功' if success else '失敗'}"
            if success and status_updated:
                embed_title += " (狀態已更新為 Review)"
            
            embed = {
                "title": embed_title,
                "description": f"**{item_type}:** {title}",
                "color": 0x00ff00 if success else 0xff0000,  # 綠色(成功) 或 紅色(失敗)
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
            
            if execution_time:
                embed["fields"].append({
                    "name": "執行時間",
                    "value": execution_time,
                    "inline": True
                })
            
            # 如果狀態已更新
            if success and status_updated:
                embed["fields"].append({
                    "name": "Project 狀態",
                    "value": "🔍 已更新為 Review",
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
    
    def run_claude_cli(self, prompt: str, item_id: str, item: Dict[str, Any] = None) -> bool:
        """
        執行 Claude Code CLI
        
        Args:
            prompt: 要執行的提示詞/任務內容
            item_id: Item ID 用於 log
            item: Project Item 數據（用於發送通知）
        
        Returns:
            bool: 執行是否成功
        """
        start_time = datetime.now()
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🤖 啟動 Claude Code CLI...")
            print(f"   📝 執行內容: {prompt[:100]}{'...' if len(prompt) > 100 else ''}")
            
            # 切換到專案目錄
            original_dir = os.getcwd()
            os.chdir(self.project_dir)
            
            # 如果需要 commit，在提示詞中加入 commit 指令
            full_prompt = prompt
            if self.request_commit:
                full_prompt = f"{prompt}\n\n完成後請自動 commit 並 push 變更到 Git 倉庫。"
            
            # 建立 Claude CLI 指令
            cmd = [self.claude_cli, '--dangerously-skip-permissions', full_prompt]
            
            # 執行 Claude CLI
            process = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600  # 10 分鐘超時（給 commit/push 更多時間）
            )
            
            # 回到原目錄
            os.chdir(original_dir)
            
            # 計算執行時間
            execution_time = str(datetime.now() - start_time).split('.')[0]
            
            if process.returncode == 0:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ✅ Claude Code 執行成功")
                if process.stdout:
                    print(f"   📤 輸出: {process.stdout.strip()[:200]}{'...' if len(process.stdout.strip()) > 200 else ''}")
                
                # 更新 Project Item 狀態為 Review
                status_updated = False
                if item_id:
                    status_updated = self.update_item_status(item_id)
                    if not status_updated:
                        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ 無法更新 Item 狀態")
                
                # 發送 Discord 通知（成功）
                if item:
                    self.send_discord_notification(item, success=True, execution_time=execution_time, status_updated=status_updated)
                
                return True
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ Claude Code 執行失敗 (exit code: {process.returncode})")
                if process.stderr:
                    print(f"   📥 錯誤: {process.stderr.strip()}")
                
                # 發送 Discord 通知（失敗）
                if item:
                    self.send_discord_notification(item, success=False, execution_time=execution_time)
                
                return False
                
        except subprocess.TimeoutExpired:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⏰ Claude Code 執行超時")
            
            # 發送 Discord 通知（超時/失敗）
            if item:
                execution_time = "超過 10 分鐘（超時）"
                self.send_discord_notification(item, success=False, execution_time=execution_time)
            
            return False
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ❌ 執行 Claude Code 時發生錯誤: {str(e)}")
            
            # 發送 Discord 通知（錯誤/失敗）
            if item:
                self.send_discord_notification(item, success=False, execution_time="執行時發生錯誤")
            
            return False
    
    
    def extract_task_content(self, item: Dict[str, Any]) -> str:
        """
        提取 Item 的任務內容
        
        Args:
            item: Project Item 數據
        
        Returns:
            str: 任務內容
        """
        content = item.get('content', {})
        
        # 優先使用 title
        title = content.get('title', '')
        
        # 如果有 body 內容，也加入
        body = content.get('body', '')
        
        # 組合任務內容
        if title and body:
            return f"{title}\n\n{body}"
        elif title:
            return title
        elif body:
            return body
        else:
            return "無法提取任務內容"
    
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