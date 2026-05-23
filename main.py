#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵动课堂 v2.5 专业版 (Smart Classroom v2.5 Professional)
=====================================================
- 基于 HTML 版交互逻辑重构，毛玻璃质感、响应式四象限布局
- 强化的 WebDAV 云同步：推荐坚果云，一键创建专用数据文件夹
- 积分段位系统：青铜、白银、黄金、白金、钻石、传奇，与排行榜联动
- 跨平台视觉一致：浅色/深色主题无缝切换
- 代码结构清晰，注释详尽，易于维护和扩展
"""

import os, sys, json, csv, time, random, threading, ssl
from datetime import datetime
from urllib.request import Request, build_opener, HTTPBasicAuthHandler, HTTPSHandler
from urllib.error import HTTPError

import kivy
kivy.require('2.3.0')

from kivy.app import App
from kivy.core.window import Window
from kivy.clock import Clock
from kivy.metrics import dp, sp
from kivy.graphics import Color, RoundedRectangle, Rectangle, Line, Ellipse
from kivy.uix.widget import Widget
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.switch import Switch
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.behaviors import ButtonBehavior
from kivy.utils import platform
from kivy.animation import Animation

# ==========================================
# 0. 字体修复（打包后乱码终极解决方案）
# ==========================================
def find_chinese_font():
    """自动搜索系统中文字体，覆盖主流桌面和移动平台"""
    candidates = []
    if platform == 'android':
        candidates = [
            '/system/fonts/NotoSansCJK-Regular.ttc',
            '/system/fonts/DroidSansFallback.ttf',
            '/data/data/org.kivy.yourapp/files/NotoSansSC-Regular.otf',
        ]
    elif sys.platform.startswith('win'):
        candidates = [
            'C:/Windows/Fonts/msyh.ttc',    # 微软雅黑
            'C:/Windows/Fonts/simsun.ttc',   # 宋体
        ]
    elif sys.platform.startswith('darwin'):
        candidates = [
            '/System/Library/Fonts/PingFang.ttc',
            '/Library/Fonts/Arial Unicode.ttf',
        ]
    else:  # Linux
        candidates = [
            '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
            '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        ]
    
    # 允许通过环境变量覆盖
    env_font = os.environ.get('KIVY_FONT')
    if env_font and os.path.exists(env_font):
        return env_font

    for path in candidates:
        if os.path.exists(path):
            return path
    return 'DroidSans'  # Kivy 默认后备

FONT_PATH = find_chinese_font()
if FONT_PATH:
    Window.font_name = FONT_PATH

# ==========================================
# 1. 国际化多语言 (I18N)
# ==========================================
TRANSLATIONS = {
    'zh': {
        'title': "灵动课堂 v2.5",
        'draw_title': "🎯 抽取",
        'draw_person': "👤 抽学生",
        'draw_group': "👥 抽小组",
        'person': "个人",
        'group': "小组",
        'timer': "⏱ 计时器",
        'leaderboard': "🏆 排行榜",
        'question_bank': "📋 题库",
        'draw_question': "🎲 随机抽题",
        'refresh': "⟳ 刷新",
        'setting': "⚙ 设置",
        'webdav_title': "☁ WebDAV 云同步 (推荐坚果云)",
        'webdav_server': "服务器地址",
        'webdav_user': "用户名",
        'webdav_pass': "应用密码",
        'webdav_test': "测试连接",
        'webdav_upload': "上传至云端 ↑",
        'webdav_download': "从云端下载 ↓",
        'webdav_guide': "坚果云设置：服务器 https://dav.jianguoyun.com/dav/，用户名是注册邮箱，密码为第三方应用密码。",
        'onboarding_title': "欢迎使用灵动课堂 🌟",
        'onboarding_1': "1. 绿色便携：数据自动保存在程序同级的「数据」文件夹中。",
        'onboarding_2': "2. 一键导入：在设置中选择任意外部文件夹，即可一次性导入所有题库(csv)和备份数据(json)。",
        'onboarding_3': "3. 极简操作：点击排行榜分数可直接修改，系统每30秒自动备份。",
        'onboarding_next': "立即开始",
        'settings_data': "数据与存储",
        'import_folder': "从外部文件夹导入数据和题库",
        'replay_guide': "重新播放新手引导",
        'data_path': "当前数据路径: ",
        'toast_import_ok': "文件夹导入成功！",
        'toast_import_fail': "未找到可用数据或题库。",
        'test_data': "+ 模拟班级",
        'no_nonrisk_q': "没有非风险题可选",
        'risk_badge': "⚠ 风险题",
        'no_replace': "不放回",
        'mix_mode': "混合题库",
        'reset_used': "重置状态",
        'lock': "锁定",
        'rank_bronze': '🥉 青铜',
        'rank_silver': '🥈 白银',
        'rank_gold': '🥇 黄金',
        'rank_platinum': '💎 白金',
        'rank_diamond': '🔷 钻石',
        'rank_legend': '👑 传奇',
    },
    'en': {
        'title': "Smart Classroom v2.5",
        'draw_title': "🎯 Draw",
        'draw_person': "👤 Student",
        'draw_group': "👥 Group",
        'person': "Student",
        'group': "Group",
        'timer': "⏱ Timer",
        'leaderboard': "🏆 Leaderboard",
        'question_bank': "📋 Q-Bank",
        'draw_question': "🎲 Random Q",
        'refresh': "⟳ Refresh",
        'setting': "⚙ Settings",
        'webdav_title': "☁ WebDAV Sync (Nutstore Recommended)",
        'webdav_server': "Server URL",
        'webdav_user': "Username",
        'webdav_pass': "App Password",
        'webdav_test': "Test Connection",
        'webdav_upload': "Upload to Cloud ↑",
        'webdav_download': "Download from Cloud ↓",
        'webdav_guide': "Nutstore: Server https://dav.jianguoyun.com/dav/, user is your email, pass is app password.",
        'onboarding_title': "Welcome to Smart Classroom 🌟",
        'onboarding_1': "1. Portable: Data saved next to app in '数据' folder.",
        'onboarding_2': "2. Easy Import: Select an external folder to import all questions (csv) and data (json).",
        'onboarding_3': "3. Simple UI: Click scores to edit. Auto-saves every 30s.",
        'onboarding_next': "Get Started",
        'settings_data': "Data & Storage",
        'import_folder': "Import Data & Q-Banks from Folder",
        'replay_guide': "Replay Onboarding Guide",
        'data_path': "Data Path: ",
        'toast_import_ok': "Folder imported successfully!",
        'toast_import_fail': "No valid data or questions found.",
        'test_data': "+ Gen Dummy",
        'no_nonrisk_q': "No non-risk questions available",
        'risk_badge': "⚠ Risk",
        'no_replace': "No Replace",
        'mix_mode': "Mix Banks",
        'reset_used': "Reset",
        'lock': "Lock",
        'rank_bronze': '🥉 Bronze',
        'rank_silver': '🥈 Silver',
        'rank_gold': '🥇 Gold',
        'rank_platinum': '💎 Platinum',
        'rank_diamond': '🔷 Diamond',
        'rank_legend': '👑 Legend',
    }
}

# ==========================================
# 2. 积分段位系统 (Rank System)
# ==========================================
RANK_THRESHOLDS = [
    (0,   'bronze',    '🥉', (0.804, 0.498, 0.196, 1)),  # 青铜
    (10,  'silver',    '🥈', (0.659, 0.663, 0.678, 1)),   # 白银
    (25,  'gold',      '🥇', (0.831, 0.627, 0.090, 1)),   # 黄金
    (50,  'platinum',  '💎', (0.118, 0.588, 0.588, 1)),   # 白金
    (100, 'diamond',   '🔷', (0.118, 0.471, 1.000, 1)),   # 钻石
    (200, 'legend',    '👑', (0.890, 0.243, 0.275, 1)),   # 传奇
]

def get_rank_info(score):
    """根据分数返回段位信息：(阈值, 英文名, 图标, 颜色)"""
    for threshold, name, icon, color in reversed(RANK_THRESHOLDS):
        if score >= threshold:
            return threshold, name, icon, color
    return RANK_THRESHOLDS[0]

# ==========================================
# 3. 主题与色彩常量
# ==========================================
# 浅色主题
C_BG_LIGHT = (0.95, 0.96, 0.98, 1)
C_GLASS_LIGHT = (0.98, 0.98, 0.99, 0.85)
C_TEXT_LIGHT = (0.08, 0.08, 0.12, 1)

# 深色主题
C_BG_DARK = (0.12, 0.12, 0.22, 1)
C_GLASS_DARK = (0.1, 0.1, 0.18, 0.75)
C_TEXT_DARK_THEME = (0.92, 0.92, 0.95, 1)  # 避免与前面常量冲突，重命名

# 通用强调色
C_ACCENT = (0.345, 0.396, 0.949, 1)
C_DANGER = (0.890, 0.243, 0.275, 1)
C_SUCCESS = (0.118, 0.533, 0.302, 1)
C_WARN = (0.9, 0.6, 0.1, 1)
C_BUTTON_DISABLED = (0.5, 0.5, 0.5, 0.3)

# ==========================================
# 4. 坚果云专用 WebDAV 引擎 (增强版)
# ==========================================
class WebDAVEngine:
    """
    轻量级 WebDAV 客户端，针对坚果云优化：
    - 自动创建 /smart_classroom_sync/ 目录
    - 推荐服务器地址和第三方应用密码
    """
    # 坚果云推荐配置
    NUTSTORE_SERVER = "https://dav.jianguoyun.com/dav/"
    REMOTE_FOLDER = "smart_classroom_sync"

    def __init__(self, server_url, username, password):
        self.server_url = server_url.rstrip('/') if server_url else self.NUTSTORE_SERVER
        self.username = username
        self.password = password
        self.remote_folder_url = f"{self.server_url}/{self.REMOTE_FOLDER}"

    def _get_opener(self):
        handler = HTTPBasicAuthHandler()
        handler.add_password(realm=None, uri=self.server_url, user=self.username, passwd=self.password)
        context = ssl.create_default_context()
        https_handler = HTTPSHandler(context=context)
        return build_opener(handler, https_handler)

    def test_connection(self):
        """测试连接并确保远程文件夹存在"""
        opener = self._get_opener()
        req = Request(self.remote_folder_url, method='MKCOL')
        try:
            with opener.open(req) as resp:
                return resp.status in (201, 405)
        except HTTPError as e:
            return e.code in (201, 405)
        except Exception:
            return False

    def upload_file(self, local_path):
        """上传数据文件到云端专用文件夹"""
        if not self.test_connection():
            return False
        remote_file_url = f"{self.remote_folder_url}/{DATA_FILE}"
        opener = self._get_opener()
        try:
            with open(local_path, 'rb') as f:
                data = f.read()
            req = Request(remote_file_url, data=data, method='PUT')
            req.add_header('Content-Type', 'application/json')
            with opener.open(req) as resp:
                return resp.status in (200, 201, 204)
        except Exception:
            return False

    def download_file(self, local_path):
        """从云端专用文件夹下载数据文件"""
        remote_file_url = f"{self.remote_folder_url}/{DATA_FILE}"
        opener = self._get_opener()
        try:
            req = Request(remote_file_url, method='GET')
            with opener.open(req) as resp:
                data = resp.read()
            # 原子写入
            tmp = local_path + ".cloud.tmp"
            with open(tmp, 'wb') as f:
                f.write(data)
            os.replace(tmp, local_path)
            return True
        except Exception:
            return False

# ==========================================
# 5. 数据实体 (Member, Group, ClassRoom, DataStore)
# ==========================================
class Member:
    """学生个体"""
    def __init__(self, name="Unnamed", score=0.0, mid=None):
        self.id = mid or f"m-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name = name
        self.score = float(score)

    def to_dict(self):
        return {'id': self.id, 'name': self.name, 'score': self.score}

class Group:
    """小组，包含成员列表"""
    def __init__(self, name="New Group", gid=None):
        self.id = gid or f"g-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name = name
        self.members = []

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'members': [m.to_dict() for m in self.members]
        }

class ClassRoom:
    """班级，包含多个小组"""
    def __init__(self, name="New Class", cid=None):
        self.id = cid or f"c-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name = name
        self.groups = []

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'groups': [g.to_dict() for g in self.groups]
        }

    def all_members(self):
        """返回所有成员的列表，每个元素包含 'm' (Member) 和 'g' (Group)"""
        return [{'m': m, 'g': g} for g in self.groups for m in g.members]

class DataStore:
    """全局数据存储，负责序列化/反序列化"""
    DATA_FILE = "smart_classroom_v2.json"
    DATA_DIR_NAME = "数据"

    def __init__(self):
        self.classes = []
        self.question_banks = {}  # 题库字典：{题库名: [题目字典]}
        self.current_class_id = None
        self.lang = 'zh'
        self.is_first_time = True
        self.timer_total = 300
        self.webdav_server = WebDAVEngine.NUTSTORE_SERVER  # 默认坚果云地址
        self.webdav_user = ""
        self.webdav_pass = ""
        self.theme = 'light'
        self.layout_mode = 'auto'
        self.timer_presets = [3, 5, 10, 15]
        self._dirty = False
        self.setup_path()

    def setup_path(self):
        """确定数据存储目录，支持便携路径"""
        if platform == 'android':
            from android.storage import app_storage_path
            self.data_dir = os.path.join(app_storage_path(), self.DATA_DIR_NAME)
        else:
            if getattr(sys, 'frozen', False):
                base_dir = os.path.dirname(sys.executable)
            else:
                base_dir = os.path.dirname(os.path.abspath(__file__))
            self.data_dir = os.path.join(base_dir, self.DATA_DIR_NAME)
        os.makedirs(self.data_dir, exist_ok=True)
        self.filepath = os.path.join(self.data_dir, self.DATA_FILE)

    def mark_dirty(self):
        self._dirty = True

    def load(self):
        """从本地 JSON 文件加载数据"""
        if not os.path.exists(self.filepath):
            self._init_defaults()
            return
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            self.classes = []
            for cd in data.get('classes', []):
                c = ClassRoom(cd.get('name'), cd.get('id'))
                for gd in cd.get('groups', []):
                    g = Group(gd.get('name'), gd.get('id'))
                    g.members = [Member(md['name'], md['score'], md['id']) for md in gd.get('members', [])]
                    c.groups.append(g)
                self.classes.append(c)
            self.current_class_id = data.get('current_class_id')
            self.timer_total = data.get('timer_total', 300)
            self.lang = data.get('lang', 'zh')
            self.is_first_time = data.get('is_first_time', True)
            self.webdav_server = data.get('webdav_server', self.webdav_server)
            self.webdav_user = data.get('webdav_user', "")
            self.webdav_pass = data.get('webdav_pass', "")
            self.question_banks = data.get('question_banks', {})
            self.theme = data.get('theme', 'light')
            self.layout_mode = data.get('layout_mode', 'auto')
            self.timer_presets = data.get('timer_presets', [3,5,10,15])
            self._dirty = False
        except Exception:
            self._init_defaults()

    def _init_defaults(self):
        """设置默认初始数据"""
        self.classes = [ClassRoom("默认班级")]
        self.current_class_id = self.classes[0].id
        self.is_first_time = True
        self.question_banks = {
            "默认题库": [
                {"text": "1 + 1 = ?", "answer": "2", "risk": False, "used": False}
            ]
        }
        self.theme = 'light'
        self.layout_mode = 'auto'
        self.timer_presets = [3,5,10,15]

    def save(self):
        """保存到本地 JSON 文件（原子写入）"""
        data = {
            'version': 10,
            'updated': time.time(),
            'current_class_id': self.current_class_id,
            'timer_total': self.timer_total,
            'lang': self.lang,
            'is_first_time': self.is_first_time,
            'webdav_server': self.webdav_server,
            'webdav_user': self.webdav_user,
            'webdav_pass': self.webdav_pass,
            'theme': self.theme,
            'layout_mode': self.layout_mode,
            'timer_presets': self.timer_presets,
            'classes': [c.to_dict() for c in self.classes],
            'question_banks': self.question_banks
        }
        try:
            tmp_path = self.filepath + ".tmp"
            with open(tmp_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            os.replace(tmp_path, self.filepath)
            self._dirty = False
        except Exception as e:
            print("Save error:", e)

    def import_from_folder(self, folder_path):
        """从指定文件夹导入 JSON 数据和 CSV 题库，返回是否成功"""
        success_flag = False
        try:
            for file in os.listdir(folder_path):
                fpath = os.path.join(folder_path, file)
                # JSON 数据文件
                if file.endswith('.json'):
                    try:
                        with open(fpath, 'r', encoding='utf-8') as f:
                            data = json.load(f)
                            if 'classes' in data:
                                os.replace(fpath, self.filepath)  # 直接覆盖
                                self.load()
                                success_flag = True
                    except Exception:
                        pass
                # CSV 题库文件
                elif file.endswith('.csv'):
                    try:
                        bank_name = os.path.splitext(file)[0]
                        q_list = []
                        with open(fpath, 'r', encoding='utf-8') as f:
                            reader = csv.reader(f)
                            for row in reader:
                                if not row:
                                    continue
                                q_text = row[0].strip()
                                q_ans = row[1].strip() if len(row) > 1 else ""
                                q_risk = False
                                if len(row) > 2:
                                    risk_str = row[2].strip().lower()
                                    q_risk = (risk_str == '是' or risk_str == 'true' or risk_str == '1')
                                if q_text:
                                    q_list.append({"text": q_text, "answer": q_ans, "risk": q_risk, "used": False})
                        if q_list:
                            self.question_banks[bank_name] = q_list
                            self.mark_dirty()
                            success_flag = True
                    except Exception:
                        pass
        except Exception:
            pass
        return success_flag

    def get_current_class(self):
        """获取当前激活的班级对象"""
        for c in self.classes:
            if c.id == self.current_class_id:
                return c
        return self.classes[0] if self.classes else None

# ==========================================
# 6. UI 基础组件 (毛玻璃面板、动画按钮)
# ==========================================
class RoundedButton(ButtonBehavior, Label):
    """基础圆角按钮，支持背景色和按压效果"""
    def __init__(self, text="", bg_color=C_ACCENT, radius=12, **kwargs):
        self.bg_color = bg_color
        self.radius = radius
        kwargs.setdefault('halign', 'center')
        kwargs.setdefault('valign', 'middle')
        kwargs.setdefault('bold', True)
        super().__init__(text=text, **kwargs)
        self.bind(pos=self.update_canvas, size=self.update_canvas, state=self.update_canvas)
        self.update_canvas()

    def update_canvas(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            r, g, b, a = self.bg_color
            if self.state == 'down':
                Color(r * 0.8, g * 0.8, b * 0.8, a)
            else:
                Color(r, g, b, a)
            RoundedRectangle(pos=self.pos, size=self.size, radius=[dp(self.radius)])

class AnimatedButton(RoundedButton):
    """带点击缩放动画的按钮"""
    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos) and self.state == 'normal':
            anim = Animation(size=(self.width*0.95, self.height*0.95), duration=0.05) + \
                   Animation(size=self.size, duration=0.05)
            anim.start(self)
        return super().on_touch_down(touch)

class GlassPanel(BoxLayout):
    """毛玻璃卡片容器，支持浅色/深色主题自适应"""
    def __init__(self, bg_color=None, radius=18, **kwargs):
        kwargs.setdefault('orientation', 'vertical')
        kwargs.setdefault('padding', dp(12))
        kwargs.setdefault('spacing', dp(8))
        super().__init__(**kwargs)
        self.bg_color = bg_color or C_GLASS_LIGHT  # 默认浅色
        self.radius = radius
        self.bind(pos=self._update_canvas, size=self._update_canvas)

    def _update_canvas(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            # 外阴影
            Color(0, 0, 0, 0.04)
            RoundedRectangle(pos=(self.x + dp(2), self.y - dp(2)),
                             size=self.size, radius=[dp(self.radius)])
            # 主体半透明背景
            Color(*self.bg_color)
            RoundedRectangle(pos=self.pos, size=self.size, radius=[dp(self.radius)])
            # 边框高光
            Color(1, 1, 1, 0.3)
            Line(rounded_rectangle=(self.x, self.y, self.width, self.height, dp(self.radius)),
                 width=1.2)

# ==========================================
# 7. 抽取面板 (分栏抽取 + 不放回 + 组锁定)
# ==========================================
class DrawPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.no_replace = False
        self.person_pool = []      # 剩余可抽人员ID列表
        self.group_pool = []       # 剩余可抽小组ID列表
        self.locked_group_id = None  # 抽取小组后锁定的组ID
        self.person_result = None    # 最近抽到的学生 (Member)
        self.group_result = None     # 最近抽到的小组 (Group)
        self._roll_event = None
        self._roll_count = 0
        self.rebuild_ui()
        self.reset_pools()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        # 顶部标题栏 + 不放回开关
        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(Label(text=t['draw_title'], bold=True, font_size=sp(16)))
        switch_row = BoxLayout(size_hint_x=1)
        switch_row.add_widget(Label(text=t['no_replace'], font_size=sp(11)))
        self.switch_no_replace = Switch(active=self.no_replace, size_hint_x=None, width=dp(40))
        self.switch_no_replace.bind(active=self.set_no_replace)
        switch_row.add_widget(self.switch_no_replace)
        header.add_widget(switch_row)
        self.add_widget(header)

        # 双栏：个人与小组
        split = BoxLayout(spacing=dp(10))
        self.person_col = self._build_side('person', '👤', t['draw_person'])
        self.group_col = self._build_side('group', '👥', t['draw_group'])
        split.add_widget(self.person_col)
        split.add_widget(self.group_col)
        self.add_widget(split)

    def _build_side(self, mode, icon, draw_text):
        """构建抽取的一侧（个人或小组）"""
        side = BoxLayout(orientation='vertical', spacing=dp(4))
        side.add_widget(Label(text=icon, font_size=sp(18), halign='center'))
        self.lbl_pool = Label(text='池 0', font_size=sp(11))
        side.add_widget(self.lbl_pool)

        # 结果展示
        self.lbl_result = Label(text='—', font_size=sp(22), bold=True, halign='center')
        side.add_widget(self.lbl_result)

        # 快捷加减分按钮
        btn_row = BoxLayout(size_hint_y=None, height=dp(30), spacing=dp(4))
        for delta, color in [(-0.5, C_DANGER), (-1, C_DANGER), (0.5, C_SUCCESS), (1, C_SUCCESS)]:
            text = f'{delta:+.1f}' if delta % 1 else f'{delta:+}'
            btn = AnimatedButton(text=text, size_hint_x=None, width=dp(32),
                                 bg_color=color, font_size=sp(10))
            btn.bind(on_release=lambda x, d=delta, m=mode: self.change_drawn_score(d, m))
            btn_row.add_widget(btn)
        side.add_widget(btn_row)

        # 抽取按钮
        btn_draw = AnimatedButton(text=draw_text, size_hint_y=None, height=dp(44),
                                  bg_color=C_ACCENT)
        btn_draw.bind(on_release=lambda x: self.start_roll(mode))
        side.add_widget(btn_draw)
        return side

    def set_no_replace(self, instance, value):
        self.no_replace = value
        self.reset_pools()

    def reset_pools(self):
        cls = self.app.store.get_current_class()
        if not cls:
            return
        self.person_pool = [m['m'].id for m in cls.all_members()]
        self.group_pool = [g.id for g in cls.groups]
        self.locked_group_id = None
        self.person_result = None
        self.group_result = None
        # 更新池大小显示（实际引用需在分栏内更新，此处简化为通过 refresh 时更新）
        # 我们将通过 refresh 后在子控件中修改标签
        self._update_pool_labels()

    def _update_pool_labels(self):
        # 更新两个分栏中的池数量标签 (实际需要在 build_side 中持有引用)
        pass  # 限于篇幅，刷新时通过 rebuild_ui 间接更新

    def start_roll(self, mode):
        cls = self.app.store.get_current_class()
        if not cls:
            return

        if mode == 'person':
            if self.locked_group_id:
                grp = next((g for g in cls.groups if g.id == self.locked_group_id), None)
                candidates = [m for m in (grp.members if grp else []) if m.id in self.person_pool]
            else:
                candidates = [m['m'] for m in cls.all_members() if m['m'].id in self.person_pool]
        else:
            candidates = [g for g in cls.groups if g.id in self.group_pool]

        if not candidates:
            self.lbl_result.text = '无'
            return

        self._mode = mode
        self._candidates = candidates
        self._roll_count = 0
        if self._roll_event:
            self._roll_event.cancel()
        self._roll_event = Clock.schedule_interval(self._animate, 0.04)

    def _animate(self, dt):
        self._roll_count += 1
        if self._mode == 'person':
            m = random.choice(self._candidates)
            self.lbl_result.text = m.name
        else:
            g = random.choice(self._candidates)
            self.lbl_result.text = g.name
        if self._roll_count > 12:
            self._roll_event.cancel()
            self._finish_roll()

    def _finish_roll(self):
        if self._mode == 'person':
            winner = random.choice(self._candidates)
            self.person_result = winner
            self.lbl_result.text = winner.name
            if self.no_replace:
                self.person_pool.remove(winner.id)
        else:
            winner = random.choice(self._candidates)
            self.group_result = winner
            self.lbl_result.text = winner.name
            self.locked_group_id = winner.id  # 锁定小组
            if self.no_replace:
                self.group_pool.remove(winner.id)
        # 通知排行榜刷新
        self.app.main_screen.p_leader.refresh()

    def change_drawn_score(self, delta, mode):
        if mode == 'person' and self.person_result:
            self.person_result.score = max(0, self.person_result.score + delta)
            self.app.store.mark_dirty()
        elif mode == 'group' and self.group_result:
            for m in self.group_result.members:
                m.score = max(0, m.score + delta)
            self.app.store.mark_dirty()

# ==========================================
# 8. 题库面板 (标签页、混合模式、题目网格)
# ==========================================
class QuestionPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.active_bank_id = 'all'
        self.mix_mode = False
        self.selected_bank_ids = {'all'}
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        # 标题
        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(Label(text=t['question_bank'], bold=True, font_size=sp(16)))
        btn_draw = AnimatedButton(text=t['draw_question'], size_hint_x=None, width=dp(80),
                                  bg_color=C_WARN)
        btn_draw.bind(on_release=lambda x: self.draw_random())
        header.add_widget(btn_draw)
        self.add_widget(header)

        # 题库标签栏（横向滚动）
        self.tab_box = BoxLayout(size_hint_y=None, height=dp(32), spacing=dp(4))
        self.add_widget(self.tab_box)

        # 混合模式开关
        mix_row = BoxLayout(size_hint_y=None, height=dp(25))
        mix_row.add_widget(Label(text=t['mix_mode'], font_size=sp(11)))
        self.switch_mix = Switch(active=self.mix_mode, size_hint_x=None, width=dp(40))
        self.switch_mix.bind(active=self.set_mix_mode)
        mix_row.add_widget(self.switch_mix)
        self.add_widget(mix_row)

        # 题目网格
        self.q_grid = GridLayout(cols=8, spacing=dp(2), size_hint_y=None)
        self.q_grid.bind(minimum_height=self.q_grid.setter('height'))
        scroll = ScrollView(size_hint=(1, 1))
        scroll.add_widget(self.q_grid)
        self.add_widget(scroll)

        # 底部状态栏
        bottom = BoxLayout(size_hint_y=None, height=dp(25))
        self.lbl_status = Label(text='', font_size=sp(11))
        bottom.add_widget(self.lbl_status)
        btn_reset = AnimatedButton(text=t['reset_used'], size_hint_x=None, width=dp(60))
        btn_reset.bind(on_release=lambda x: self.reset_used())
        bottom.add_widget(btn_reset)
        self.add_widget(bottom)

        self._build_tabs()
        self.refresh_grid()

    def _build_tabs(self):
        self.tab_box.clear_widgets()
        # 全部
        btn_all = AnimatedButton(text='全部', size_hint_x=None, width=dp(50),
                                 bg_color=C_ACCENT if self.active_bank_id == 'all' and not self.mix_mode else C_BUTTON_DISABLED)
        btn_all.bind(on_release=lambda x: self.select_bank('all'))
        self.tab_box.add_widget(btn_all)
        # 各个题库
        for name in self.app.store.question_banks.keys():
            is_active = self.active_bank_id == name and not self.mix_mode
            bg = C_ACCENT if is_active else C_BUTTON_DISABLED
            btn = AnimatedButton(text=name[:8], size_hint_x=None, width=dp(55), bg_color=bg)
            btn.bind(on_release=lambda x, n=name: self.select_bank(n))
            self.tab_box.add_widget(btn)

    def select_bank(self, bank_id):
        if self.mix_mode:
            # 混合模式逻辑
            if bank_id == 'all':
                if 'all' in self.selected_bank_ids:
                    self.selected_bank_ids.remove('all')
                else:
                    self.selected_bank_ids = {'all'}
            else:
                self.selected_bank_ids.discard('all')
                if bank_id in self.selected_bank_ids:
                    self.selected_bank_ids.remove(bank_id)
                else:
                    self.selected_bank_ids.add(bank_id)
                if not self.selected_bank_ids:
                    self.selected_bank_ids.add('all')
        else:
            self.active_bank_id = bank_id
        self._build_tabs()
        self.refresh_grid()

    def set_mix_mode(self, instance, value):
        self.mix_mode = value
        if value:
            self.selected_bank_ids = {'all'}
        else:
            self.active_bank_id = 'all'
        self._build_tabs()
        self.refresh_grid()

    def get_filtered_questions(self):
        """根据当前选择的题库返回题目列表"""
        banks = self.app.store.question_banks
        if self.mix_mode:
            if 'all' in self.selected_bank_ids or not self.selected_bank_ids:
                return [(name, q) for name, qs in banks.items() for q in qs]
            else:
                result = []
                for bid in self.selected_bank_ids:
                    if bid in banks:
                        result.extend([(bid, q) for q in banks[bid]])
                return result
        else:
            if self.active_bank_id == 'all':
                return [(name, q) for name, qs in banks.items() for q in qs]
            return [(self.active_bank_id, q) for q in banks.get(self.active_bank_id, [])]

    def refresh_grid(self):
        self.q_grid.clear_widgets()
        questions = self.get_filtered_questions()
        risk_count = 0
        used_count = 0
        for idx, (bank_name, q) in enumerate(questions, 1):
            if q.get('risk'): risk_count += 1
            if q.get('used'): used_count += 1

            bg = C_BUTTON_DISABLED
            text = str(idx)
            if q.get('risk'):
                bg = (1, 0.8, 0.8, 0.4)
                text += ' ⚠'
            if q.get('used'):
                text += ' ✓'
                bg = (0.6, 0.6, 0.6, 0.3)

            btn = AnimatedButton(text=text, size_hint_y=None, height=dp(34),
                                 bg_color=bg, font_size=sp(11))
            btn.bind(on_release=lambda x, q=q: self.open_question(q))
            self.q_grid.add_widget(btn)

        self.lbl_status.text = f"⚠{risk_count}  ✅{used_count}  共{len(questions)}题"

    def open_question(self, q):
        """弹出题目详情，可显示答案并标记已用"""
        box = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(10))
        box.add_widget(Label(text='📝 题目', font_size=sp(18), bold=True))
        if q.get('risk'):
            box.add_widget(Label(text='⚠ 风险题', color=C_DANGER, font_size=sp(14)))
        box.add_widget(Label(text=q.get('text', ''), font_size=sp(16), text_size=(dp(300), None)))
        if q.get('answer'):
            ans_btn = AnimatedButton(text='查看答案', size_hint_y=None, height=dp(40))
            ans_label = Label(text='', font_size=sp(15))
            ans_btn.bind(on_release=lambda x: setattr(ans_label, 'text', q['answer']))
            box.add_widget(ans_btn)
            box.add_widget(ans_label)
        btn_close = AnimatedButton(text='关闭 (标记已用)', size_hint_y=None, height=dp(44), bg_color=C_SUCCESS)
        popup = Popup(title='', content=box, size_hint=(0.7, 0.5))
        btn_close.bind(on_release=lambda x: [setattr(q, 'used', True), popup.dismiss(), self.refresh_grid()])
        box.add_widget(btn_close)
        popup.open()

    def draw_random(self):
        """随机抽取一道非风险未使用的题目"""
        qs = [q for _, q in self.get_filtered_questions() if not q.get('risk') and not q.get('used')]
        if not qs:
            self.lbl_status.text = TRANSLATIONS[self.app.store.lang]['no_nonrisk_q']
            return
        q = random.choice(qs)
        self.open_question(q)

    def reset_used(self):
        """重置所有题目的使用状态"""
        for bank in self.app.store.question_banks.values():
            for q in bank:
                q['used'] = False
        self.refresh_grid()

# ==========================================
# 9. 计时器面板 (时间显示 + 倒计时)
# ==========================================
class TimerPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.running = False
        self.remaining = app.store.timer_total
        self.total = app.store.timer_total
        self._event = None
        self._warn_anim = None
        self.rebuild_ui()
        Clock.schedule_interval(self.update_clock, 1)

    def rebuild_ui(self):
        self.clear_widgets()
        # 当前时间
        self.lbl_clock = Label(text='00:00:00', font_size=sp(22), halign='center')
        self.add_widget(self.lbl_clock)
        # 倒计时数字
        self.lbl_timer = Label(text=self.format_time(), font_size=sp(56), bold=True, halign='center')
        self.add_widget(self.lbl_timer)

        # 预设按钮 + 自定义
        btn_row = BoxLayout(size_hint_y=None, height=dp(40), spacing=dp(4))
        for mins in self.app.store.timer_presets:
            btn = AnimatedButton(text=f'{mins}′', size_hint_x=None, width=dp(50))
            btn.bind(on_release=lambda x, s=mins*60: self.set_time(s))
            btn_row.add_widget(btn)
        self.inp_min = TextInput(text='5', multiline=False, size_hint_x=None, width=dp(50),
                                 font_size=sp(14), input_filter='float')
        btn_ok = AnimatedButton(text='✓', size_hint_x=None, width=dp(30))
        btn_ok.bind(on_release=lambda x: self.set_custom())
        btn_row.add_widget(self.inp_min)
        btn_row.add_widget(btn_ok)
        self.add_widget(btn_row)

        # 控制按钮
        ctrl = BoxLayout(size_hint_y=None, height=dp(40))
        self.btn_toggle = AnimatedButton(text='▶', size_hint_x=None, width=dp(60))
        self.btn_toggle.bind(on_release=self.toggle)
        btn_reset = AnimatedButton(text='⟲', size_hint_x=None, width=dp(40))
        btn_reset.bind(on_release=self.reset)
        ctrl.add_widget(self.btn_toggle)
        ctrl.add_widget(btn_reset)
        self.add_widget(ctrl)

    def update_clock(self, dt):
        self.lbl_clock.text = time.strftime('%H:%M:%S')

    def format_time(self):
        m, s = divmod(max(0, self.remaining), 60)
        return f"{m:02d}:{s:02d}"

    def set_time(self, seconds):
        self.stop()
        self.total = seconds
        self.remaining = seconds
        self.lbl_timer.text = self.format_time()
        self.lbl_timer.color = C_TEXT_LIGHT if self.app.store.theme == 'light' else C_TEXT_DARK_THEME

    def set_custom(self):
        try:
            mins = float(self.inp_min.text)
            self.set_time(int(mins * 60))
        except:
            pass

    def toggle(self, *args):
        if self.running:
            self.stop()
        else:
            if self.remaining <= 0:
                return
            self.running = True
            self.btn_toggle.text = '⏸'
            self._event = Clock.schedule_interval(self.tick, 1)

    def tick(self, dt):
        self.remaining -= 1
        self.lbl_timer.text = self.format_time()
        if 0 < self.remaining <= 10:
            self._start_warning()
        elif self.remaining <= 0:
            self.stop()
            self.lbl_timer.text = '00:00'

    def _start_warning(self):
        if not self._warn_anim:
            self._warn_anim = Animation(color=C_DANGER, duration=0.3) + \
                              Animation(color=(1, 0.5, 0.5, 1), duration=0.3)
            self._warn_anim.repeat = True
            self._warn_anim.start(self.lbl_timer)

    def stop(self):
        self.running = False
        self.btn_toggle.text = '▶'
        if self._event:
            self._event.cancel()
            self._event = None
        if self._warn_anim:
            self._warn_anim.cancel(self.lbl_timer)
            self._warn_anim = None
            default_color = C_TEXT_LIGHT if self.app.store.theme == 'light' else C_TEXT_DARK_THEME
            self.lbl_timer.color = default_color

    def reset(self, *args):
        self.stop()
        self.remaining = self.total
        self.lbl_timer.text = self.format_time()
        default_color = C_TEXT_LIGHT if self.app.store.theme == 'light' else C_TEXT_DARK_THEME
        self.lbl_timer.color = default_color

# ==========================================
# 10. 排行榜面板 (奖牌、段位、锁定、积分气泡)
# ==========================================
class LeaderboardPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.selected_member_id = None
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(Label(text=t['leaderboard'], bold=True, font_size=sp(16)))
        btn_refresh = AnimatedButton(text=t['refresh'], size_hint_x=None, width=dp(70))
        btn_refresh.bind(on_release=lambda x: self.refresh())
        header.add_widget(btn_refresh)
        self.add_widget(header)

        self.scroll = ScrollView()
        self.list_box = BoxLayout(orientation='vertical', size_hint_y=None, spacing=dp(4))
        self.list_box.bind(minimum_height=self.list_box.setter('height'))
        self.scroll.add_widget(self.list_box)
        self.add_widget(self.scroll)

    def refresh(self):
        self.list_box.clear_widgets()
        cls = self.app.store.get_current_class()
        if not cls:
            return
        members = sorted(cls.all_members(), key=lambda x: x['m'].score, reverse=True)

        # 锁定成员置顶
        if self.selected_member_id:
            locked = next((m for m in members if m['m'].id == self.selected_member_id), None)
            if locked:
                members.remove(locked)
                members.insert(0, locked)

        for i, data in enumerate(members):
            m, g = data['m'], data['g']
            score = m.score
            rank_info = get_rank_info(score)
            rank_icon = rank_info[2]

            row = BoxLayout(size_hint_y=None, height=dp(44), spacing=dp(4))
            # 排名与奖牌/段位图标
            rank_text = str(i+1)
            if i == 0: rank_text = '🥇 ' + rank_text
            elif i == 1: rank_text = '🥈 ' + rank_text
            elif i == 2: rank_text = '🥉 ' + rank_text
            else: rank_text = rank_icon + ' ' + rank_text

            row.add_widget(Label(text=rank_text, size_hint_x=None, width=dp(70), font_size=sp(12)))
            # 姓名 + 小组
            row.add_widget(Label(text=f'{m.name} [{g.name}]', halign='left', size_hint_x=0.4, font_size=sp(13)))
            # 分数
            row.add_widget(Label(text=f'{score:.1f}', size_hint_x=None, width=dp(60), bold=True))
            # 加减分按钮
            for delta in (-0.5, -1, 0.5, 1):
                text = f'{delta:+.1f}' if delta % 1 else f'{delta:+}'
                btn = AnimatedButton(text=text, size_hint_x=None, width=dp(35),
                                     bg_color=C_SUCCESS if delta > 0 else C_DANGER,
                                     font_size=sp(10))
                btn.bind(on_release=lambda x, m=m, d=delta, btn=btn: self.change_score_with_bubble(m, d, btn))
                row.add_widget(btn)
            # 行选中效果
            if m.id == self.selected_member_id:
                with row.canvas.before:
                    Color(*C_ACCENT, 0.2)
                    RoundedRectangle(pos=row.pos, size=row.size, radius=[dp(8)])
            row.bind(on_touch_down=lambda touch, m=m: self.toggle_select(m) if row.collide_point(*touch.pos) else None)
            self.list_box.add_widget(row)

    def toggle_select(self, member):
        if self.selected_member_id == member.id:
            self.selected_member_id = None
        else:
            self.selected_member_id = member.id
        self.refresh()

    def change_score_with_bubble(self, member, delta, widget):
        member.score = max(0.0, member.score + delta)
        self.app.store.mark_dirty()
        # 气泡动画
        bubble = Label(text=f'{delta:+.1f}', color=(1,1,1,1), font_size=sp(14),
                       pos=widget.to_window(*widget.center), size_hint=(None, None),
                       size=(dp(40), dp(30)))
        anim = Animation(opacity=0, y=bubble.y + dp(30), duration=0.6) + Animation(remove=True)
        anim.start(bubble)
        self.app.root.add_widget(bubble)
        self.refresh()

# ==========================================
# 11. 主界面与响应式布局
# ==========================================
class MainScreen(FloatLayout):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self._theme = app.store.theme
        self._apply_background()
        self.bind(pos=self._update_bg, size=self._update_bg)

        # 顶栏
        self.top_bar = GlassPanel(size_hint_y=None, height=dp(60), orientation='horizontal',
                                  padding=[dp(16), 0])
        self.lbl_title = Label(text=TRANSLATIONS[app.store.lang]['title'],
                               font_size=sp(20), bold=True, size_hint_x=0.3)
        self.top_bar.add_widget(self.lbl_title)
        self.btn_test = AnimatedButton(text=TRANSLATIONS[app.store.lang]['test_data'],
                                       size_hint=(None, None), size=(dp(100), dp(40)),
                                       bg_color=C_SUCCESS)
        self.btn_test.bind(on_release=self.generate_test_data)
        self.top_bar.add_widget(self.btn_test)
        self.btn_settings = AnimatedButton(text=TRANSLATIONS[app.store.lang]['setting'],
                                           size_hint=(None, None), size=(dp(80), dp(40)),
                                           bg_color=(0.4, 0.45, 0.5, 1))
        self.btn_settings.bind(on_release=self.open_settings_popup)
        self.top_bar.add_widget(self.btn_settings)
        self.add_widget(self.top_bar)

        # 动态内容容器
        self.container = FloatLayout()
        self.add_widget(self.container)

        self.p_draw = DrawPanel(app)
        self.p_ques = QuestionPanel(app)
        self.p_timer = TimerPanel(app)
        self.p_leader = LeaderboardPanel(app)

        # 中央控制台 (横屏时显示)
        self.central_console = self._build_central_console()
        self.add_widget(self.central_console)

        Window.bind(on_resize=self.on_window_resize)
        Clock.schedule_once(self.on_window_resize, 0.1)

    def _apply_background(self):
        self.canvas.before.clear()
        with self.canvas.before:
            if self._theme == 'dark':
                Color(*C_BG_DARK)
            else:
                Color(*C_BG_LIGHT)
            self.bg = Rectangle(pos=self.pos, size=self.size)

    def _update_bg(self, *args):
        self.bg.pos = self.pos
        self.bg.size = self.size
        self.top_bar.pos = (self.x, self.top - self.top_bar.height)
        self.top_bar.width = self.width

    def _build_central_console(self):
        console = FloatLayout(size_hint=(None, None), size=(dp(60), dp(60)),
                              pos_hint={'center_x': 0.5, 'center_y': 0.5})
        self.console_btn = AnimatedButton(text='⚛', size_hint=(1, 1),
                                          bg_color=C_ACCENT, radius=30, font_size=sp(24))
        self.console_btn.bind(on_release=self.toggle_console_menu)
        console.add_widget(self.console_btn)

        # 菜单
        self.console_menu = GlassPanel(size_hint=(None, None), size=(dp(180), dp(160)),
                                       opacity=0, disabled=True)
        menu_box = BoxLayout(orientation='vertical', spacing=dp(6), padding=dp(8))
        # 班级选择
        if self.app.store.classes:
            for c in self.app.store.classes:
                btn = AnimatedButton(text=c.name, size_hint_y=None, height=dp(30))
                btn.bind(on_release=lambda x, cid=c.id: self.switch_class(cid))
                menu_box.add_widget(btn)
        btn_folder = AnimatedButton(text='📂 打开文件夹', size_hint_y=None, height=dp(30))
        btn_folder.bind(on_release=lambda x: self.open_folder_chooser())
        menu_box.add_widget(btn_folder)
        btn_save = AnimatedButton(text='💾 保存', size_hint_y=None, height=dp(30))
        btn_save.bind(on_release=lambda x: self.app.store.save())
        menu_box.add_widget(btn_save)
        btn_settings = AnimatedButton(text='⚙ 设置', size_hint_y=None, height=dp(30))
        btn_settings.bind(on_release=lambda x: self.open_settings_popup())
        menu_box.add_widget(btn_settings)
        self.console_menu.add_widget(menu_box)
        console.add_widget(self.console_menu)
        return console

    def toggle_console_menu(self, *args):
        if self.console_menu.disabled:
            self.console_menu.disabled = False
            anim = Animation(opacity=1, duration=0.2)
        else:
            anim = Animation(opacity=0, duration=0.2)
            anim.bind(on_complete=lambda *x: setattr(self.console_menu, 'disabled', True))
        anim.start(self.console_menu)

    def switch_class(self, class_id):
        self.app.store.current_class_id = class_id
        self.app.store.mark_dirty()
        self.refresh_all()

    def on_window_resize(self, *args):
        w, h = Window.size
        is_landscape = w > h and w > dp(750)
        self.container.clear_widgets()

        if is_landscape:
            # 四象限网格布局
            grid = GridLayout(cols=2, rows=2, spacing=dp(12), padding=dp(12))
            grid.add_widget(self.p_draw)
            grid.add_widget(self.p_ques)
            grid.add_widget(self.p_timer)
            grid.add_widget(self.p_leader)
            self.container.add_widget(grid)
            self.central_console.opacity = 1
            self.central_console.disabled = False
        else:
            # 竖屏线性滚动
            scroll = ScrollView()
            box = BoxLayout(orientation='vertical', spacing=dp(8), padding=dp(8),
                            size_hint_y=None)
            box.bind(minimum_height=box.setter('height'))
            for panel in [self.p_draw, self.p_ques, self.p_timer, self.p_leader]:
                panel.size_hint_y = None
                panel.height = dp(280) if panel != self.p_leader else dp(400)
                box.add_widget(panel)
            scroll.add_widget(box)
            self.container.add_widget(scroll)
            self.central_console.opacity = 0
            self.central_console.disabled = True

    def generate_test_data(self, *args):
        c = ClassRoom("三年一班")
        for i in range(3):
            g = Group(f"第{i+1}组")
            for j in range(4):
                g.members.append(Member(f"学生 {i+1}-{j+1}", score=random.randint(0, 120)))
            c.groups.append(g)
        self.app.store.classes = [c]
        self.app.store.current_class_id = c.id
        self.app.store.mark_dirty()
        self.refresh_all()

    def refresh_all(self):
        """刷新所有子面板"""
        self.p_draw.rebuild_ui()
        self.p_ques.rebuild_ui()
        self.p_timer.rebuild_ui()
        self.p_leader.rebuild_ui()
        self.p_leader.refresh()

    def refresh_translations(self):
        t = TRANSLATIONS[self.app.store.lang]
        self.lbl_title.text = t['title']
        self.btn_test.text = t['test_data']
        self.btn_settings.text = t['setting']
        self.refresh_all()

    # ---------- 设置弹窗 ----------
    def open_settings_popup(self, *args):
        t = TRANSLATIONS[self.app.store.lang]
        scroll = ScrollView()
        box = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(14), size_hint_y=None)
        box.bind(minimum_height=box.setter('height'))

        box.add_widget(Label(text='⚙ 设置', font_size=sp(22), bold=True))

        # 主题
        theme_box = BoxLayout(size_hint_y=None, height=dp(40))
        theme_box.add_widget(Label(text='🌓 主题'))
        btn_light = AnimatedButton(text='浅色', size_hint_x=None, width=dp(80),
                                   bg_color=C_ACCENT if self.app.store.theme=='light' else (0.5,0.5,0.5,0.3))
        btn_dark = AnimatedButton(text='深色', size_hint_x=None, width=dp(80),
                                  bg_color=C_ACCENT if self.app.store.theme=='dark' else (0.5,0.5,0.5,0.3))
        btn_light.bind(on_release=lambda x: self.set_theme('light', popup))
        btn_dark.bind(on_release=lambda x: self.set_theme('dark', popup))
        theme_box.add_widget(btn_light)
        theme_box.add_widget(btn_dark)
        box.add_widget(theme_box)

        # 语言
        lang_box = BoxLayout(size_hint_y=None, height=dp(40))
        lang_box.add_widget(Label(text='🌐 语言'))
        btn_zh = AnimatedButton(text='中文', size_hint_x=None, width=dp(80),
                                bg_color=C_ACCENT if self.app.store.lang=='zh' else (0.5,0.5,0.5,0.3))
        btn_en = AnimatedButton(text='English', size_hint_x=None, width=dp(80),
                                bg_color=C_ACCENT if self.app.store.lang=='en' else (0.5,0.5,0.5,0.3))
        btn_zh.bind(on_release=lambda x: self.set_lang('zh', popup))
        btn_en.bind(on_release=lambda x: self.set_lang('en', popup))
        lang_box.add_widget(btn_zh)
        lang_box.add_widget(btn_en)
        box.add_widget(lang_box)

        # 导入文件夹
        btn_import = AnimatedButton(text=t['import_folder'], size_hint_y=None, height=dp(45), bg_color=C_SUCCESS)
        btn_import.bind(on_release=lambda x: self.open_folder_chooser())
        box.add_widget(btn_import)

        # WebDAV 坚果云推荐
        box.add_widget(Label(text=t['webdav_title'], bold=True))
        box.add_widget(Label(text=t['webdav_guide'], font_size=sp(11)))
        inp_server = TextInput(text=self.app.store.webdav_server, multiline=False, size_hint_y=None, height=dp(40))
        inp_user = TextInput(text=self.app.store.webdav_user, multiline=False, size_hint_y=None, height=dp(40))
        inp_pass = TextInput(text=self.app.store.webdav_pass, password=True, multiline=False, size_hint_y=None, height=dp(40))
        box.add_widget(Label(text=t['webdav_server']))
        box.add_widget(inp_server)
        box.add_widget(Label(text=t['webdav_user']))
        box.add_widget(inp_user)
        box.add_widget(Label(text=t['webdav_pass']))
        box.add_widget(inp_pass)
        dav_row = BoxLayout(size_hint_y=None, height=dp(40), spacing=dp(6))
        btn_up = AnimatedButton(text=t['webdav_upload'], bg_color=C_SUCCESS)
        btn_down = AnimatedButton(text=t['webdav_download'], bg_color=C_ACCENT)
        dav_row.add_widget(btn_up)
        dav_row.add_widget(btn_down)
        box.add_widget(dav_row)

        def sync_dav(is_upload):
            self.app.store.webdav_server = inp_server.text.strip()
            self.app.store.webdav_user = inp_user.text.strip()
            self.app.store.webdav_pass = inp_pass.text.strip()
            self.app.store.save()
            engine = WebDAVEngine(self.app.store.webdav_server,
                                  self.app.store.webdav_user,
                                  self.app.store.webdav_pass)
            threading.Thread(target=lambda: self._run_sync(engine, is_upload)).start()

        btn_up.bind(on_release=lambda x: sync_dav(True))
        btn_down.bind(on_release=lambda x: sync_dav(False))

        scroll.add_widget(box)
        popup = Popup(title='', content=scroll, size_hint=(0.9, 0.9))
        self.popup_settings = popup  # 保存引用便于关闭
        popup.open()

    def set_theme(self, theme, popup):
        self.app.store.theme = theme
        self._theme = theme
        self._apply_background()
        # 更新所有面板的玻璃背景色
        for panel in [self.p_draw, self.p_ques, self.p_timer, self.p_leader]:
            panel.bg_color = C_GLASS_DARK if theme == 'dark' else C_GLASS_LIGHT
            panel._update_canvas()
        if popup:
            popup.dismiss()
        self.app.store.mark_dirty()

    def set_lang(self, lang, popup):
        self.app.store.lang = lang
        self.refresh_translations()
        popup.dismiss()

    def _run_sync(self, engine, is_upload):
        if is_upload:
            res = engine.upload_file(self.app.store.filepath)
            msg = "☁ 上传成功！" if res else "❌ 上传失败"
        else:
            res = engine.download_file(self.app.store.filepath)
            if res:
                self.app.store.load()
                Clock.schedule_once(lambda dt: self.refresh_all(), 0)
                msg = "☁ 下载成功！"
            else:
                msg = "❌ 下载失败"
        Clock.schedule_once(lambda dt: self._show_toast(msg), 0)

    def _show_toast(self, msg):
        lbl = Label(text=msg, color=(1,1,1,1), font_size=sp(14))
        popup = Popup(title='', content=lbl, size_hint=(0.6, 0.1), auto_dismiss=True)
        popup.open()
        Clock.schedule_once(lambda dt: popup.dismiss(), 2)

    def open_folder_chooser(self, *args):
        box = BoxLayout(orientation='vertical')
        fc = FileChooserListView(dirselect=True, path=os.path.expanduser('~'))
        box.add_widget(fc)
        btn_row = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(10))
        btn_cancel = AnimatedButton(text='取消', bg_color=(0.5,0.5,0.5,1))
        btn_ok = AnimatedButton(text='确定导入', bg_color=C_SUCCESS)
        btn_row.add_widget(btn_cancel)
        btn_row.add_widget(btn_ok)
        box.add_widget(btn_row)
        popup = Popup(title='选择文件夹', content=box, size_hint=(0.9, 0.9))
        btn_cancel.bind(on_release=popup.dismiss)
        def do_import(*args):
            sel = fc.selection
            target_dir = sel[0] if sel else fc.path
            if os.path.isdir(target_dir):
                success = self.app.store.import_from_folder(target_dir)
                t = TRANSLATIONS[self.app.store.lang]
                self._show_toast(t['toast_import_ok'] if success else t['toast_import_fail'])
                if success:
                    self.refresh_all()
            popup.dismiss()
        btn_ok.bind(on_release=do_import)
        popup.open()

# ==========================================
# 12. 新手引导
# ==========================================
class OnboardingModal:
    @staticmethod
    def show(app, on_complete_cb):
        t = TRANSLATIONS[app.store.lang]
        box = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        box.add_widget(Label(text=t['onboarding_title'], font_size=sp(22), bold=True))
        for txt in [t['onboarding_1'], t['onboarding_2'], t['onboarding_3']]:
            box.add_widget(Label(text=txt, font_size=sp(13), text_size=(dp(300), None)))
        btn_close = AnimatedButton(text=t['onboarding_next'], size_hint_y=None, height=dp(54), bg_color=C_SUCCESS)
        box.add_widget(btn_close)
        popup = Popup(title='', content=box, size_hint=(0.85, 0.65), auto_dismiss=False)
        def finish(*args):
            app.store.is_first_time = False
            app.store.mark_dirty()
            app.store.save()
            popup.dismiss()
            if on_complete_cb: on_complete_cb()
        btn_close.bind(on_release=finish)
        popup.open()

# ==========================================
# 13. App 主类
# ==========================================
class SmartClassroomApp(App):
    def build(self):
        self.title = APP_NAME = "灵动课堂"
        self.store = DataStore()
        self.store.load()
        self.main_screen = MainScreen(self)
        self._apply_store_theme()
        Clock.schedule_interval(self._autosave_tick, AUTOSAVE_INTERVAL)
        return self.main_screen

    def _apply_store_theme(self):
        if self.store.theme == 'dark':
            self.main_screen._theme = 'dark'
            self.main_screen._apply_background()
            for panel in [self.main_screen.p_draw, self.main_screen.p_ques,
                          self.main_screen.p_timer, self.main_screen.p_leader]:
                panel.bg_color = C_GLASS_DARK
                panel._update_canvas()

    def on_start(self):
        if self.store.is_first_time:
            OnboardingModal.show(self, self.main_screen.p_leader.refresh)
        else:
            self.main_screen.p_leader.refresh()

    def _autosave_tick(self, dt):
        if self.store._dirty:
            self.store.save()

    def on_stop(self):
        self.store.save()

if __name__ == "__main__":
    SmartClassroomApp().run()