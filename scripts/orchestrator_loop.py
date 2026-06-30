#!/usr/bin/env python3
"""
Virent Admin Panel — Sub-Agent Orchestrator Loop
Runs infinite loop of sub-agents that continuously improve the admin panel.
Each iteration: spawn sub-agent → audit → fix → verify → repeat.
"""
import os, re, json, subprocess, sys, time, argparse
from datetime import datetime

ADMIN_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web"
WORKLOG = "/home/z/my-project/worklog.md"
STATE_FILE = "/home/z/my-project/orchestrator_state.json"

def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)

def scan_issues():
    """Scan for issues and return categorized list."""
    issues = {
        'brace_balance': [],
        'deprecated_api': [],
        'empty_handlers': [],
        'old_colors': [],
        'missing_features': [],
        'english_text': [],
        'hardcoded_data': [],
        'ui_inconsistency': [],
    }
    
    old_colors = ['0xFF7B68EE', '0xFF333333', '0xFF2ECC71', '0xFFE74C3C',
                  '0xFFF1C40F', '0xFF3498DB', '0xFFF5F6FA', '0xFFF0F3F9', '0xFF666666']
    
    for root, dirs, files in os.walk(ADMIN_DIR):
        for fn in files:
            if not fn.endswith('.dart'): continue
            fp = os.path.join(root, fn)
            with open(fp) as f: c = f.read()
            
            # Brace balance
            stripped = re.sub(r'//[^\n]*', '', c)
            stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)
            stripped = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', stripped)
            stripped = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", stripped)
            if stripped.count('{') != stripped.count('}'):
                issues['brace_balance'].append(fp)
            
            # Deprecated APIs
            if 'MaterialStateProperty' in c: issues['deprecated_api'].append(fp)
            if re.search(r'\.withOpacity\(', c): issues['deprecated_api'].append(fp)
            if 'WillPopScope' in c: issues['deprecated_api'].append(fp)
            
            # Empty handlers
            if re.search(r'onPressed:\s*\(\)\s*\{\s*\}', c): issues['empty_handlers'].append(fp)
            if re.search(r'onTap:\s*\(\)\s*\{\s*\}', c): issues['empty_handlers'].append(fp)
            
            # Old colors
            for pat in old_colors:
                if pat in c:
                    issues['old_colors'].append(f'{fp}: {pat}')
                    break
            
            # Missing features (DataTable pages only, skip detail/scaffold)
            if 'DataTable' in c and fn not in ['scooter_detail_page.dart', 'admin_table_page.dart',
                                                'admin_contacts_page.dart', 'admin_export.dart']:
                missing = []
                if not any(x in c for x in ['_searchController', 'searchProvider', '_query']): missing.append('search')
                if '_pageSize' not in c and '_currentPage' not in c: missing.append('pagination')
                if '_selectedIds' not in c and '_selectedKeys' not in c: missing.append('bulk')
                if 'showAdminExportDialog' not in c: missing.append('export')
                if 'showAdminFilterDialog' not in c: missing.append('filter')
                if 'AdminStatusTabsRow' not in c and '_buildStatusTabs' not in c: missing.append('status_tabs')
                if 'Checkbox' not in c: missing.append('checkbox')
                if missing:
                    issues['missing_features'].append(f'{fn}: {missing}')
            
            # English text in UI (not column headers)
            texts = re.findall(r"Text\(\s*['\"]([^'\"]+)['\"]", c)
            for t in texts:
                if re.search(r'[a-zA-Z]{4,}', t) and not re.search(r'[а-яА-ЯёЁ]', t):
                    skip = ['ID', 'GSM', 'GPS', 'PUSH', 'FAQ', 'JSON', 'MAC', 'URL', 'Email', 'UTC',
                            'Close', 'Joan', 'Volume', 'Cruising', 'Path', 'Car', 'Order', 'Type',
                            'Name', 'Description', 'Language', 'File', 'City', 'Phone', 'Telegram',
                            'Whatsapp', 'Company', 'Holder', 'Bank', 'Country', 'Card', 'Token',
                            'Click', 'Merchant', 'Payme', 'Bonus', 'Code', 'Promocode', 'Group',
                            'Expires', 'Active', 'Blocked', 'Comment', 'Create', 'Tariff',
                            'Abonnement', 'Duration', 'Status', 'Amount', 'Hold', 'Operator',
                            'Redis', 'Result', 'Transaction', 'Uzcard', 'CardPan', 'Fine',
                            'Insurance', 'General', 'Title', 'Technician', 'Finish', 'Companion',
                            'Technick', 'Permissions', 'Admin', 'Trigger', 'FinishGeo', 'Map',
                            'Angle', 'Distance', 'Ident', 'Driver', 'Gosnomer', 'Fake', 'groups',
                            'Cur', 'order', 'Запас', 'Хода', 'Тип', 'ошибки', 'Код', 'Режим',
                            'Raider', 'Tech', 'Alerting', 'Внимание', 'Brake', 'Force', 'Motor',
                            'Power', 'Configuration', 'Max', 'Speed', 'Limit', 'Acceleration',
                            'Mode', 'workingMode', 'Model', 'Geozones', 'Last', 'active', 'finish',
                            'time', 'Movement', 'status', 'Rssi', 'Fuel', 'Rnis', 'Alt', 'Lat', 'Lon',
                            'int', 'counter_action', 'Is', 'success', 'ip', 'Time', 'Sms', 'code',
                            'try', 'count', 'all', 'login', 'attempt', 'last', 'Provider', 'usid',
                            'Yes', 'Bill', 'client_id', 'amount', 'hold_id', 'order_id', 'bill_id',
                            'description', 'timestamp_response', 'transaction_id', 'type_request',
                            'timestamp_type_request', 'request_source', 'status_response',
                            'document_type', 'Url', 'lable', 'icon', 'scooterid', 'alertType',
                            'anoxer', 'read_by_admin', 'read_date', 'message', 'image', 'timestamp',
                            'Location', 'Cartrek', 'Html', 'html', 'Deleted', 'Only', 'real',
                            'money', 'Bonus', 'Try', 'withdrawals', 'Updated', 'Transaction',
                            'Result', 'code', 'confirm', 'cancel', 'Type', 'request', 'Elastic',
                            'Provider', 'uuid', 'Raw', 'json', 'Created', 'Sendable', 'Reason',
                            'check', 'after', 'Click', 'trans', 'paydoc', 'Merchant', 'prepare',
                            'Action', 'Error', 'note', 'Sign', 'Updated', 'Start', 'Finish',
                            'Mileage', 'Is', 'payme', 'click', 'Total', 'cost', 'Remarks', 'pay',
                            'GuardChanged', 'Drift', 'Redis', 'token', 'Active', 'Movement',
                            'Geozоны', 'Время', 'обновления', 'создания', 'Факелы', 'Intel',
                            'завершения', 'последнего', 'заказа', 'Описание', 'Path', 'Car',
                            'Order', 'Type', 'id', 'Title', 'Technician', 'Description', 'Create',
                            'by', 'time', 'Завершен', 'Finish', 'id', 'Joan', 'Volume', 'Cruising',
                            'range', 'id', 'Description', 'Trigger', 'equation', 'id', 'Description',
                            'id', 'Description', 'Type', 'id', 'Name', 'pub', 'id', 'Description',
                            'FinishGeo', 'ID', 'Название', 'Заполнение', 'Обводка', 'company_id',
                            'Группы', 'ID', 'Номер', 'самоката', 'ID', 'текущего', 'заказа', 'ID',
                            'модели', 'Онлайн', 'counter_action', 'ID', 'компании', 'Кто', 'ввёл',
                            'изменения', 'id', 'Client', 'Phone', 'ip', 'Time', 'Sms', 'code', 'Is',
                            'success', 'Id', 'Имя', 'Почта', 'UTC', 'Роли', 'Имя', 'backpack',
                            'permissionmanager', 'title', 'Id', 'Name', 'pub', 'City', 'Phone',
                            'Email', 'Telegram', 'Whatsapp', 'Год', 'Company', 'Id', 'Имя', 'Роли',
                            'Companion', 'Technick', 'key', 'Api', 'token', 'Permissions', 'Admin',
                            'id', 'Title', 'Technician', 'Description', 'Create', 'by', 'time',
                            'Завершен', 'Finish', 'time', 'ID', 'ID', 'самоката', 'Откуда',
                            'произошло', 'переключение', 'Координаты', 'активации', 'Время',
                            'активации', 'Время', 'телефона', 'client_id', 'message', 'image',
                            'Anoxer', 'timestamp', 'Location', 'read_by_admin', 'read_date',
                            'Id', 'Client', 'Bonus', 'sum', 'Who', 'added', 'Create', 'time',
                            'Comment', 'Company', 'Id', 'Code', 'Bonus', 'gift', 'Usage', 'remains',
                            'Promocode', 'group', 'Group', 'active', 'Expires', 'ID', 'Название',
                            'Активка', 'Id', 'Client', 'Holder', 'name', 'Bank', 'name', 'Country',
                            'Card', 'number', 'Token', 'Card', 'type', 'Deleted', 'ID', 'client_id',
                            'amount', 'hold_id', 'order_id', 'bill_id', 'description',
                            'timestamp_response', 'status', 'CardPan', 'Transactionid',
                            'UscardTransactionid', 'updated_at', 'Id', 'Payme', 'transaction',
                            'Merchant', 'transaction', 'payme_time', 'UTC', 'ms', 'create_time',
                            'Perform', 'time', 'Cancel', 'time', 'state', 'description', 'State',
                            'Amount', 'Phone', 'Client', 'Reason', 'id', 'Click', 'trans', 'Click',
                            'paydoc', 'Merchant', 'trans', 'Merchant', 'prepare', 'Merchant',
                            'confirm', 'Amount', 'Action', 'Status', 'Error', 'note', 'Sign',
                            'time', 'Created', 'Updated', 'Id', 'Redis', 'token', 'Car', 'Client',
                            'Company', 'Abonement', 'Amount', 'Status', 'Transaction', 'Order',
                            'Start', 'lat', 'Start', 'lon', 'App', 'ver', 'Os', 'type', 'Os', 'ver',
                            'ID', 'Hold', 'Company', 'Operator', 'Order', 'Amount', 'Client',
                            'Radio', 'token', 'Result', 'code', 'Type', 'request', 'Transaction',
                            'Uzcard', 'transaction', 'Card', 'pan', 'Code', 'message', 'confirm',
                            'cancel', 'Elastic', 'Redis', 'token', 'Status', 'ID', 'Client',
                            'Order', 'Amount', 'Status', 'Created', 'Only', 'real', 'money', 'Fine',
                            'Bonus', 'Insurance', 'General', 'order', 'sum', 'Sum', 'card', 'Sum',
                            'bonus', 'Try', 'withdrawals', 'Type', 'Updated', 'Transaction',
                            'Company', 'Path', 'Car', 'Order', 'Type', 'Id', 'Uuid', 'Provider',
                            'uuid', 'Bill', 'Status', 'Client', 'Amount', 'Raw', 'json', 'Created',
                            'Company', 'Order', 'Sendable', 'Reason', 'Status', 'check', 'after',
                            'Tariff', 'Description', 'Overrun', 'price', 'Cost', 'Name', 'Name',
                            'app', 'Price', 'Group', 'Active', 'Daily', 'Company', 'Duration',
                            'Название', 'мобильном', 'приложении', 'Название', 'админке',
                            'Максимальная', 'длительность', 'часах', 'Страховка', 'Тийны',
                            'стоимость', 'км', 'Тийны', 'Уровень', 'заряда']
                    if t in skip: continue
                    if len(t) < 4: continue
                    if re.match(r'^[0-9\s\.,:;\-\(\)\[\]/+]*$', t): continue
                    issues['english_text'].append(f'{fn}: "{t}"')
                    break
    
    return issues

def count_issues(issues):
    return sum(len(v) for v in issues.values())

def spawn_sub_agent(task_type, files, iteration):
    """Spawn a sub-agent via Task tool (using Claude CLI or similar)."""
    # Since we can't directly spawn sub-agents from Python, we'll write
    # the task description and use the Task tool from the main agent.
    # For now, this logs the task and returns a prompt for the main agent.
    
    prompt = f"""Task ID: ORCHESTRATOR-{iteration}-{task_type}
You are a sub-agent in the infinite orchestrator loop.

**YOUR TASK**: Fix {task_type} issues in these files:
{chr(10).join(f'- {f}' for f in files[:20])}

**Before starting**: Read /home/z/my-project/worklog.md

**FIXES TO APPLY**:
- For brace_balance: Read file, find unbalanced braces, fix them
- For deprecated_api: Replace MaterialStateProperty -> WidgetStateProperty, withOpacity -> withValues(alpha:), WillPopScope -> PopScope
- For empty_handlers: Replace onPressed: () {{}} with onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке')
- For old_colors: Replace with reference palette (0xFF7C69EF primary, 0xFF1B2A4E text, 0xFF42BA96 success, 0xFFDF4759 danger, 0xFFFFC107 warning, 0xFF467FD0 info, 0xFFF1F4F8 bg, 0xFFD9E2EF border)
- For missing_features: Add search, pagination, bulk, export, filter, status_tabs, checkbox using clients_page.dart pattern
- For english_text: Translate to Russian (keep English field names from reference)
- For hardcoded_data: Replace with provider data
- For ui_inconsistency: Standardize to reference design system

**CRITICAL RULES**:
1. Read each file BEFORE editing
2. Do NOT break compilation
3. Verify balanced braces
4. Pure Dart, all Russian
5. Keep existing functionality

**AFTER finishing**: Append to /home/z/my-project/worklog.md with Task ID ORCHESTRATOR-{iteration}-{task_type}
"""
    return prompt

def save_state(iteration, issues_count, fixed_count):
    """Save orchestrator state."""
    state = {
        'iteration': iteration,
        'issues_found': issues_count,
        'issues_fixed': fixed_count,
        'timestamp': datetime.now().isoformat(),
    }
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def main():
    log("=" * 60)
    log("VIRENT ADMIN PANEL — SUB-AGENT ORCHESTRATOR LOOP")
    log("=" * 60)
    
    iteration = 1
    total_fixed = 0
    
    while iteration <= 1000:  # Safety limit
        log(f"\n=== ORCHESTRATOR ITERATION {iteration} ===")
        
        # Scan for issues
        issues = scan_issues()
        total_issues = count_issues(issues)
        log(f"Found {total_issues} issues")
        
        if total_issues == 0:
            log("✅ ALL CLEAN — no issues found")
            log("Waiting 30 seconds before next scan...")
            time.sleep(30)
            iteration += 1
            continue
        
        # Categorize and log issues
        for category, files in issues.items():
            if files:
                log(f"  {category}: {len(files)}")
                for f in files[:3]:
                    log(f"    - {f}")
        
        # Generate sub-agent prompts for each category
        prompts = []
        for category, files in issues.items():
            if files:
                prompt = spawn_sub_agent(category, files, iteration)
                prompts.append((category, prompt))
                log(f"  Generated sub-agent prompt for {category}")
        
        # Save prompts for main agent to execute
        with open(f'/home/z/my-project/orchestrator_prompts_{iteration}.json', 'w') as f:
            json.dump([{'category': cat, 'prompt': p} for cat, p in prompts], f, indent=2, ensure_ascii=False)
        
        log(f"\nGenerated {len(prompts)} sub-agent prompts")
        log(f"Saved to orchestrator_prompts_{iteration}.json")
        log("Main agent will spawn sub-agents to fix these issues...")
        
        save_state(iteration, total_issues, 0)
        
        # Wait before next iteration
        time.sleep(10)
        iteration += 1
    
    log(f"\nOrchestrator completed {iteration-1} iterations")

if __name__ == "__main__":
    main()
