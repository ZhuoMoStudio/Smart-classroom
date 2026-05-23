#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵动课堂 v2.5 (Smart Classroom v2.5)
"""

import os
import sys
import json
import csv
import time
import random
import threading
import ssl
from urllib.request import Request, build_opener, HTTPBasicAuthHandler, HTTPSHandler
from urllib.error import HTTPError
from datetime import datetime

import kivy
kivy.require('2.3.0')

from kivy.app import App
from kivy.core.window import Window
from kivy.clock import Clock
from kivy.metrics import dp, sp
from kivy.graphics import Color, RoundedRectangle, Line
from kivy.uix.widget import Widget
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.behaviors import ButtonBehavior
from kivy.utils import platform

# ==========================================
# 1. 国际化多语言系统 (I18N)
# ==========================================
TRANSLATIONS = {
    'zh': {
        'title': "灵动课堂 v2.5",
        'draw_title': "[b]随机抽取[/b]",
        'draw_person': "∃ 抽学生",
        'draw_group': "G 抽小组",
        'person': "个人",
        'group': "小组",
        'timer': "倒计时",
        'leaderboard': "[b]积分排行榜[/b]",
        'question_bank': "[b]课堂题库[/b]",
        'draw_question': "Q 随机抽题",
        'refresh': "⟳ 刷新",
        'setting': "⚙ 设置",
        'webdav_title': "WebDAV 云同步",
        'webdav_server': "服务器地址",
        'webdav_user': "用户名",
        'webdav_pass': "应用密码",
        'webdav_test': "测试云连接",
        'webdav_upload': "手动同步至云端 ↑",
        'webdav_download': "从云端同步本地 ↓",
        'onboarding_title': "欢迎使用灵动课堂 🌟",
        'onboarding_1': "1. 绿色便携：数据自动保存在程序同级的「数据」文件夹中，拷贝 U 盘即可带走。",
        'onboarding_2': "2. 一键导入：在设置中选择任意外部文件夹，即可一次性导入所有题库(csv)和备份数据(json)。",
        'onboarding_3': "3. 极简操作：点击排行榜的分数可以直接修改，系统每 30 秒自动为您备份，放心使用！",
        'onboarding_next': "立即开始",
        'settings_data': "数据与存储",
        'import_folder': "从外部文件夹导入数据和题库",
        'replay_guide': "重新播放新手引导",
        'data_path': "当前数据路径: ",
        'toast_import_ok': "文件夹导入成功！",
        'toast_import_fail': "未在文件夹中找到可用数据或题库。",
        'test_data': "+ 模拟班级",
        'no_nonrisk_q': "没有非风险题可选",
        'risk_badge': "⚠ 风险题",
    },
    'en': {
        'title': "Smart Classroom v2.5",
        'draw_title': "[b]Random Draw[/b]",
        'draw_person': "∃ Student",
        'draw_group': "G Group",
        'person': "Student",
        'group': "Group",
        'timer': "Timer",
        'leaderboard': "[b]Leaderboard[/b]",
        'question_bank': "[b]Questions[/b]",
        'draw_question': "Q Draw Qs",
        'refresh': "⟳ Refresh",
        'setting': "⚙ Settings",
        'webdav_title': "WebDAV Cloud Sync",
        'webdav_server': "Server URL",
        'webdav_user': "Username",
        'webdav_pass': "App Password",
        'webdav_test': "Test Connection",
        'webdav_upload': "Upload to Cloud ↑",
        'webdav_download': "Download from Cloud ↓",
        'onboarding_title': "Welcome to Smart Classroom 🌟",
        'onboarding_1': "1. Portable: Data is saved in the '数据' folder next to the app. Carry it on a USB drive!",
        'onboarding_2': "2. Easy Import: Select an external folder in Settings to import all questions (csv) and data (json).",
        'onboarding_3': "3. Simple UI: Click scores to edit. Auto-saves every 30s. Enjoy your class!",
        'onboarding_next': "Get Started",
        'settings_data': "Data & Storage",
        'import_folder': "Import Data & Q-Banks from Folder",
        'replay_guide': "Replay Onboarding Guide",
        'data_path': "Data Path: ",
        'toast_import_ok': "Folder imported successfully!",
        'toast_import_fail': "No valid data or questions found in folder.",
        'test_data': "+ Gen Dummy",
        'no_nonrisk_q': "No non-risk questions available",
        'risk_badge': "⚠ Risk",
    }
}

# ==========================================
# 2. 常量与UI色彩
# ==========================================
APP_NAME = "灵动课堂"
DATA_DIR_NAME = "数据"
DATA_FILE = "smart_classroom_v2.json"
AUTOSAVE_INTERVAL = 30

C_ACCENT = (0.345, 0.396, 0.949, 1)
C_DANGER = (0.890, 0.243, 0.275, 1)
C_SUCCESS = (0.118, 0.533, 0.302, 1)
C_WARN = (0.9, 0.6, 0.1, 1)
C_BG_LIGHT = (0.965, 0.969, 0.980, 1)
C_TEXT_DARK = (0.086, 0.086, 0.122, 1)
C_GLASS_BG = (1.0, 1.0, 1.0, 0.95)

RANKS = [
    (0,   "Bronze", "○", (0.804, 0.498, 0.196, 1)),
    (10,  "Silver", "◇", (0.659, 0.663, 0.678, 1)),
    (25,  "Gold", "△", (0.831, 0.627, 0.090, 1)),
    (50,  "Platinum", "☆", (0.118, 0.588, 0.588, 1)),
    (100, "Diamond", "◆", (0.118, 0.471, 1.000, 1)),
    (200, "Legend", "⊕", (0.890, 0.243, 0.275, 1)),
]

def get_rank(score):
    for i in range(len(RANKS)-1, -1, -1):
        if score >= RANKS[i][0]: return RANKS[i]
    return RANKS[0]

# ==========================================
# 3. 极简轻量级 WebDAV 引擎 (非阻塞)
# ==========================================
class WebDAVEngine:
    def __init__(self, server_url, username, password):
        self.server_url = server_url.rstrip('/')
        self.username = username
        self.password = password
        self.remote_folder_url = f"{self.server_url}/smart_classroom_sync"

    def _get_opener(self):
        handler = HTTPBasicAuthHandler()
        handler.add_password(realm=None, uri=self.server_url, user=self.username, passwd=self.password)
        # 修复 Android 上可能缺失的 SSL 上下文
        context = ssl.create_default_context()
        https_handler = HTTPSHandler(context=context)
        return build_opener(handler, https_handler)

    def test_and_create_dir(self):
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
        if not self.test_and_create_dir(): return False
        remote_file_url = f"{self.remote_folder_url}/{DATA_FILE}"
        opener = self._get_opener()
        try:
            with open(local_path, 'rb') as f: data = f.read()
            req = Request(remote_file_url, data=data, method='PUT')
            req.add_header('Content-Type', 'application/json')
            with opener.open(req) as resp: return resp.status in (200, 201, 204)
        except Exception: return False

    def download_file(self, local_path):
        remote_file_url = f"{self.remote_folder_url}/{DATA_FILE}"
        opener = self._get_opener()
        try:
            req = Request(remote_file_url, method='GET')
            with opener.open(req) as resp: data = resp.read()
            tmp = local_path + ".cloud.tmp"
            with open(tmp, 'wb') as f: f.write(data)
            os.replace(tmp, local_path)
            return True
        except Exception: return False

# ==========================================
# 4. 数据实体 & 本地/U盘存储逻辑
# ==========================================
class Member:
    def __init__(self, name="Unnamed", score=0.0, mid=None):
        self.id = mid or f"m-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name, self.score = name, float(score)
    def to_dict(self): return {'id': self.id, 'name': self.name, 'score': self.score}

class Group:
    def __init__(self, name="New Group", gid=None):
        self.id = gid or f"g-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name = name
        self.members = []
    def to_dict(self): return {'id': self.id, 'name': self.name, 'members': [m.to_dict() for m in self.members]}

class ClassRoom:
    def __init__(self, name="New Class", cid=None):
        self.id = cid or f"c-{int(time.time()*1000):x}-{random.randint(100,999)}"
        self.name = name
        self.groups = []
    def to_dict(self): return {'id': self.id, 'name': self.name, 'groups': [g.to_dict() for g in self.groups]}
    def all_members(self):
        return [{'m': m, 'g': g} for g in self.groups for m in g.members]

class Question:
    def __init__(self, text, answer=""):
        self.text = text
        self.answer = answer

class DataStore:
    def __init__(self):
        self.classes = []
        self.question_banks = {} # dict of list of Questions
        self.current_class_id = None
        self.lang = 'zh'
        self.is_first_time = True
        self.timer_total = 300
        self.webdav_server = ""
        self.webdav_user = ""
        self.webdav_pass = ""
        self._dirty = False
        self.setup_path()

    def setup_path(self):
        """核心：U盘便携化检测。
        Windows: 放在 exe 或 py 所在目录的 "数据" 文件夹中。
        Android: 放在 App 私有沙盒中。"""
        if platform == 'android':
            # 延迟导入，避免桌面环境缺少 android 模块
            from android.storage import app_storage_path
            self.data_dir = os.path.join(app_storage_path(), DATA_DIR_NAME)
        else:
            # 修复 PyInstaller --onefile 路径：使用 sys.executable 而不是 __file__
            if getattr(sys, 'frozen', False):
                base_dir = os.path.dirname(sys.executable)
            else:
                base_dir = os.path.dirname(os.path.abspath(__file__))
            self.data_dir = os.path.join(base_dir, DATA_DIR_NAME)
            
        os.makedirs(self.data_dir, exist_ok=True)
        self.filepath = os.path.join(self.data_dir, DATA_FILE)

    def mark_dirty(self): self._dirty = True

    def load(self):
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
            self.webdav_server = data.get('webdav_server', "")
            self.webdav_user = data.get('webdav_user', "")
            self.webdav_pass = data.get('webdav_pass', "")
            self.question_banks = data.get('question_banks', {})
            self._dirty = False
        except Exception:
            self._init_defaults()

    def _init_defaults(self):
        self.classes = [ClassRoom("默认班级")]
        self.current_class_id = self.classes[0].id
        self.is_first_time = True
        self.question_banks = {"默认题库": [{"text": "1 + 1 = ?", "answer": "2", "risk": False}]}

    def save(self):
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
        """一键导入：扫描指定的文件夹，合并 JSON 数据并加载所有 CSV 题库（支持风险题第三列）"""
        success_flag = False
        try:
            for file in os.listdir(folder_path):
                fpath = os.path.join(folder_path, file)
                # 导入并覆盖当前数据
                if file.endswith('.json'):
                    try:
                        with open(fpath, 'r', encoding='utf-8') as f:
                            data = json.load(f)
                            if 'classes' in data:
                                # 覆盖本地文件并重新 load
                                os.replace(fpath, self.filepath)
                                self.load()
                                success_flag = True
                    except Exception: pass
                # 批量导入题库 CSV（支持第三列风险标记）
                elif file.endswith('.csv'):
                    try:
                        bank_name = os.path.splitext(file)[0]
                        q_list = []
                        with open(fpath, 'r', encoding='utf-8') as f:
                            reader = csv.reader(f)
                            for row in reader:
                                if not row: continue
                                q_text = row[0].strip()
                                q_ans = row[1].strip() if len(row) > 1 else ""
                                # 解析第三列风险标记
                                q_risk = False
                                if len(row) > 2:
                                    risk_str = row[2].strip().lower()
                                    q_risk = (risk_str == '是' or risk_str == 'true' or risk_str == '1')
                                if q_text: 
                                    q_list.append({"text": q_text, "answer": q_ans, "risk": q_risk})
                        if q_list:
                            self.question_banks[bank_name] = q_list
                            self.mark_dirty()
                            success_flag = True
                    except Exception: pass
        except Exception: pass
        return success_flag

    def get_current_class(self):
        for c in self.classes:
            if c.id == self.current_class_id: return c
        return self.classes[0] if self.classes else None

# ==========================================
# 5. M3 圆角抗锯齿高精度 Canvas 样式组件
# ==========================================
class CLabel(Label):
    def __init__(self, **kwargs):
        kwargs.setdefault('color', C_TEXT_DARK)
        super().__init__(**kwargs)

class RoundedButton(ButtonBehavior, Label):
    def __init__(self, text="", bg_color=C_ACCENT, radius=12, **kwargs):
        self.bg_color = bg_color
        self.radius = radius
        super().__init__(text=text, **kwargs)
        self.bind(pos=self.update_canvas, size=self.update_canvas, state=self.update_canvas)
        self.update_canvas()

    def update_canvas(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            r, g, b, a = self.bg_color
            if self.state == 'down': Color(r * 0.8, g * 0.8, b * 0.8, a)
            else: Color(r, g, b, a)
            RoundedRectangle(pos=self.pos, size=self.size, radius=[dp(self.radius)])

class GlassPanel(BoxLayout):
    def __init__(self, **kwargs):
        kwargs.setdefault('orientation', 'vertical')
        kwargs.setdefault('padding', dp(14))
        kwargs.setdefault('spacing', dp(10))
        super().__init__(**kwargs)
        self.bind(pos=self.update_canvas, size=self.update_canvas)

    def update_canvas(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            Color(*C_GLASS_BG)
            RoundedRectangle(pos=self.pos, size=self.size, radius=[dp(18)])
            Color(0.2, 0.2, 0.3, 0.08)
            Line(rounded_rectangle=(self.x, self.y, self.width, self.height, dp(18)), width=1.5)

# ==========================================
# 6. 四大核心业务象限面板
# ==========================================
class DrawPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(CLabel(text=t['draw_title'], markup=True, halign="left", font_size=sp(16)))
        self.add_widget(header)

        content = BoxLayout(spacing=dp(12))
        self.lbl_person = CLabel(text="—", font_size=sp(28), bold=True)
        self.lbl_group = CLabel(text="—", font_size=sp(28), bold=True)
        
        box_p = BoxLayout(orientation='vertical', spacing=dp(8))
        box_p.add_widget(CLabel(text=t['person'], size_hint_y=None, height=dp(20), font_size=sp(12)))
        box_p.add_widget(self.lbl_person)
        btn_p = RoundedButton(text=t['draw_person'], size_hint_y=None, height=dp(50), bg_color=C_ACCENT)
        btn_p.bind(on_release=lambda x: self.roll('person'))
        box_p.add_widget(btn_p)
        content.add_widget(box_p)

        box_g = BoxLayout(orientation='vertical', spacing=dp(8))
        box_g.add_widget(CLabel(text=t['group'], size_hint_y=None, height=dp(20), font_size=sp(12)))
        box_g.add_widget(self.lbl_group)
        btn_g = RoundedButton(text=t['draw_group'], size_hint_y=None, height=dp(50), bg_color=(0.14, 0.54, 0.74, 1))
        btn_g.bind(on_release=lambda x: self.roll('group'))
        box_g.add_widget(btn_g)
        content.add_widget(box_g)

        self.add_widget(content)
        self._roll_event = None
        self._roll_count = 0

    def roll(self, mode):
        cls = self.app.store.get_current_class()
        if not cls: return
        candidates = [m['m'].name for m in cls.all_members()] if mode == 'person' else [g.name for g in cls.groups]
        if not candidates: return
        self._mode, self._candidates, self._roll_count = mode, candidates, 0
        if self._roll_event: self._roll_event.cancel()
        self._roll_event = Clock.schedule_interval(self._animate, 0.04)

    def _animate(self, dt):
        self._roll_count += 1
        name = random.choice(self._candidates)
        if self._mode == 'person': self.lbl_person.text = name
        else: self.lbl_group.text = name
        if self._roll_count > 14: self._roll_event.cancel()

class QuestionPanel(GlassPanel):
    """题库面板 (支持风险题红色边框，默认不抽取风险题)"""
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.risk_show = False
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(CLabel(text=t['question_bank'], markup=True, halign="left", font_size=sp(16)))
        self.add_widget(header)

        # 题目容器（用于绘制红色边框）
        self.q_container = BoxLayout(orientation='vertical', padding=dp(4))
        self.q_container.bind(pos=self._update_q_border, size=self._update_q_border)
        
        self.lbl_q = CLabel(text="—", font_size=sp(18), bold=True, text_size=(dp(300), None), halign='center', valign='middle')
        self.lbl_ans = CLabel(text="", font_size=sp(14), color=(0.4, 0.4, 0.4, 1))
        self.lbl_risk = CLabel(text="", font_size=sp(12), color=C_DANGER, bold=True)
        
        self.q_container.add_widget(self.lbl_q)
        self.q_container.add_widget(self.lbl_ans)
        self.q_container.add_widget(self.lbl_risk)
        self.add_widget(self.q_container)

        btn_q = RoundedButton(text=t['draw_question'], size_hint_y=None, height=dp(50), bg_color=(0.9, 0.6, 0.2, 1))
        btn_q.bind(on_release=self.draw_question)
        self.add_widget(btn_q)

    def _update_q_border(self, *args):
        self.q_container.canvas.before.clear()
        if self.risk_show:
            with self.q_container.canvas.before:
                Color(*C_DANGER)
                Line(rounded_rectangle=(self.q_container.x, self.q_container.y,
                                       self.q_container.width, self.q_container.height, dp(8)), width=2)

    def draw_question(self, *args):
        t = TRANSLATIONS[self.app.store.lang]
        banks = self.app.store.question_banks
        # 默认排除风险题
        all_qs = [q for b in banks.values() for q in b if not q.get('risk', False)]
        if not all_qs:
            self.lbl_q.text = t['no_nonrisk_q']
            self.lbl_ans.text = ""
            self.lbl_risk.text = ""
            self.risk_show = False
            self._update_q_border()
            return
        q = random.choice(all_qs)
        self.lbl_q.text = q.get('text', '')
        self.lbl_ans.text = "Answer: " + q.get('answer', 'N/A')
        self.risk_show = q.get('risk', False)
        self.lbl_risk.text = t['risk_badge'] if self.risk_show else ""
        self._update_q_border()

class TimerPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.running = False
        self.remaining = app.store.timer_total
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]
        self.lbl_time = CLabel(text=self.format_time(), font_size=sp(68), bold=True)
        self.add_widget(self.lbl_time)
        
        controls = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(6))
        for minutes in [3, 5, 10]:
            btn = RoundedButton(text=f"{minutes}′", bg_color=(0.4,0.45,0.5,1))
            btn.bind(on_release=lambda x, sec=minutes*60: self.set_time(sec))
            controls.add_widget(btn)
        
        self.btn_toggle = RoundedButton(text="▶", bg_color=C_ACCENT)
        self.btn_toggle.bind(on_release=self.toggle)
        controls.add_widget(self.btn_toggle)
        self.add_widget(controls)
        self._event = None

    def format_time(self):
        m, s = divmod(max(0, self.remaining), 60)
        return f"{m:02d}:{s:02d}"

    def set_time(self, seconds):
        self.remaining = seconds
        self.app.store.timer_total = seconds
        self.app.store.mark_dirty()
        self.lbl_time.text = self.format_time()
        self.lbl_time.color = C_TEXT_DARK

    def toggle(self, *args):
        if self.running:
            self.running, self.btn_toggle.text = False, "▶"
            if self._event: self._event.cancel()
        else:
            if self.remaining <= 0: return
            self.running, self.btn_toggle.text = True, "⏸"
            self._event = Clock.schedule_interval(self.tick, 1)

    def tick(self, dt):
        if self.remaining > 0:
            self.remaining -= 1
            self.lbl_time.text = self.format_time()
            if self.remaining <= 10: self.lbl_time.color = C_DANGER
        else:
            self.toggle()
            self.lbl_time.text = "00:00"

class LeaderboardPanel(GlassPanel):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.rebuild_ui()

    def rebuild_ui(self):
        self.clear_widgets()
        t = TRANSLATIONS[self.app.store.lang]

        header = BoxLayout(size_hint_y=None, height=dp(30))
        header.add_widget(CLabel(text=t['leaderboard'], markup=True, halign="left", font_size=sp(16)))
        btn_refresh = RoundedButton(text=t['refresh'], size_hint_x=None, width=dp(70), bg_color=C_ACCENT)
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
        if not cls: return
        members = sorted(cls.all_members(), key=lambda x: x['m'].score, reverse=True)
        
        for i, data in enumerate(members):
            m, g = data['m'], data['g']
            _, r_name, r_sym, r_col = get_rank(m.score)
            
            row = BoxLayout(size_hint_y=None, height=dp(48), padding=[dp(10), 0])
            with row.canvas.before:
                Color(0,0,0, 0.03 if i % 2 == 0 else 0.06)
                RoundedRectangle(pos=row.pos, size=row.size, radius=[dp(8)])
            row.bind(pos=self._update_row, size=self._update_row)
            
            row.add_widget(CLabel(text=f"{i+1}", size_hint_x=None, width=dp(25), bold=True))
            row.add_widget(CLabel(text=r_sym, size_hint_x=None, width=dp(25), color=r_col, font_size=sp(18), bold=True))
            row.add_widget(CLabel(text=f"{m.name} [{g.name}]", halign="left", size_hint_x=0.5))
            
            # 点击分数区域直接编辑
            btn_score = RoundedButton(text=f"{m.score:.1f}", bg_color=(0,0,0,0), color=C_TEXT_DARK, bold=True, size_hint_x=None, width=dp(60))
            btn_score.bind(on_release=lambda btn, mem=m: self.popup_edit_score(mem))
            row.add_widget(btn_score)
            
            btn_add = RoundedButton(text="+1", size_hint_x=None, width=dp(40), bg_color=C_SUCCESS)
            btn_add.bind(on_release=lambda btn, mem=m: self.change_score(mem, 1.0))
            row.add_widget(btn_add)
            
            self.list_box.add_widget(row)

    def _update_row(self, instance, *args):
        instance.canvas.before.clear()
        with instance.canvas.before:
            Color(0,0,0, 0.04)
            RoundedRectangle(pos=instance.pos, size=instance.size, radius=[dp(8)])

    def change_score(self, member, delta):
        member.score = max(0.0, member.score + delta)
        self.app.store.mark_dirty()
        self.refresh()

    def popup_edit_score(self, member):
        box = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(12))
        box.add_widget(CLabel(text=f"Edit: {member.name}", font_size=sp(18), bold=True))
        inp_score = TextInput(text=str(member.score), multiline=False, input_filter='float', size_hint_y=None, height=dp(45))
        box.add_widget(CLabel(text="Score", font_size=sp(12)))
        box.add_widget(inp_score)

        btn_row = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(10))
        btn_cancel = RoundedButton(text="Cancel", bg_color=(0.5,0.5,0.5,1))
        btn_save = RoundedButton(text="Save", bg_color=C_SUCCESS)
        btn_row.add_widget(btn_cancel)
        btn_row.add_widget(btn_save)
        box.add_widget(btn_row)

        popup = Popup(title="Edit Score", content=box, size_hint=(0.7, 0.4))
        btn_cancel.bind(on_release=popup.dismiss)
        
        def do_save(*args):
            try: member.score = max(0.0, float(inp_score.text))
            except ValueError: pass
            self.app.store.mark_dirty()
            popup.dismiss()
            self.refresh()
            
        btn_save.bind(on_release=do_save)
        popup.open()

# ==========================================
# 7. 智能交互式新手教程
# ==========================================
class OnboardingModal:
    @staticmethod
    def show(app, on_complete_cb):
        t = TRANSLATIONS[app.store.lang]
        box = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        
        box.add_widget(CLabel(text=t['onboarding_title'], font_size=sp(22), bold=True))
        box.add_widget(CLabel(text=t['onboarding_1'], size_hint_y=None, height=dp(60), text_size=(dp(300), None), font_size=sp(13)))
        box.add_widget(CLabel(text=t['onboarding_2'], size_hint_y=None, height=dp(60), text_size=(dp(300), None), font_size=sp(13)))
        box.add_widget(CLabel(text=t['onboarding_3'], size_hint_y=None, height=dp(60), text_size=(dp(300), None), font_size=sp(13)))

        btn_close = RoundedButton(text=t['onboarding_next'], size_hint_y=None, height=dp(54), bg_color=C_SUCCESS)
        box.add_widget(btn_close)

        popup = Popup(title="Guide", content=box, size_hint=(0.85, 0.65), auto_dismiss=False)
        
        def finish(*args):
            app.store.is_first_time = False
            app.store.mark_dirty()
            app.store.save()
            popup.dismiss()
            if on_complete_cb: on_complete_cb()

        btn_close.bind(on_release=finish)
        popup.open()

# ==========================================
# 8. 主应用屏幕与自适应排版
# ==========================================
class MainScreen(FloatLayout):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        with self.canvas.before:
            Color(*C_BG_LIGHT)
            self.bg = RoundedRectangle(pos=self.pos, size=self.size)
        self.bind(pos=self._update_bg, size=self._update_bg)

        # 顶栏
        self.top_bar = GlassPanel(size_hint_y=None, height=dp(64), orientation='horizontal', padding=[dp(16), 0])
        self.lbl_title = CLabel(text=TRANSLATIONS[app.store.lang]['title'], font_size=sp(22), bold=True, size_hint_x=0.3)
        self.top_bar.add_widget(self.lbl_title)
        
        self.btn_test = RoundedButton(text=TRANSLATIONS[app.store.lang]['test_data'], size_hint=(None, None), size=(dp(100), dp(44)), bg_color=C_SUCCESS)
        self.btn_test.bind(on_release=self.generate_test_data)
        self.top_bar.add_widget(self.btn_test)

        self.btn_settings = RoundedButton(text=TRANSLATIONS[app.store.lang]['setting'], size_hint=(None, None), size=(dp(90), dp(44)), bg_color=(0.4, 0.45, 0.5, 1))
        self.btn_settings.bind(on_release=self.open_settings_popup)
        self.top_bar.add_widget(self.btn_settings)

        self.add_widget(self.top_bar)

        # 动态容器
        self.container = BoxLayout()
        self.add_widget(self.container)
        
        self.p_draw = DrawPanel(app)
        self.p_ques = QuestionPanel(app)
        self.p_timer = TimerPanel(app)
        self.p_leader = LeaderboardPanel(app)
        
        Window.bind(on_resize=self.on_window_resize)
        Clock.schedule_once(self.on_window_resize, 0.1)

    def _update_bg(self, *args):
        self.bg.pos = self.pos
        self.bg.size = self.size
        self.top_bar.pos = (self.x, self.top - self.top_bar.height)
        self.top_bar.width = self.width
        self.container.pos = (self.x, self.y)
        self.container.size = (self.width, self.height - self.top_bar.height - dp(8))

    def on_window_resize(self, *args):
        w, h = Window.size
        is_landscape = w > h and w > dp(750)
        self.container.clear_widgets()
        
        if is_landscape:
            # 电脑端 100英寸白板 完美 2x2 四象限平衡布局
            grid = GridLayout(cols=2, rows=2, spacing=dp(16), padding=dp(16))
            if w >= 1920:
                self.lbl_title.font_size = sp(28)
            grid.add_widget(self.p_draw)
            grid.add_widget(self.p_leader) # 右上角放排行榜
            grid.add_widget(self.p_timer)
            grid.add_widget(self.p_ques)   # 右下角放题库
            self.container.add_widget(grid)
        else:
            # 手机端流畅瀑布流
            scroll = ScrollView()
            box = BoxLayout(orientation='vertical', spacing=dp(12), padding=dp(12), size_hint_y=None)
            box.bind(minimum_height=box.setter('height'))
            for p in [self.p_draw, self.p_ques, self.p_timer, self.p_leader]:
                p.size_hint_y = None
                p.height = dp(240) if p != self.p_leader else dp(420)
                box.add_widget(p)
            scroll.add_widget(box)
            self.container.add_widget(scroll)

    def generate_test_data(self, *args):
        c = ClassRoom("三年一班" if self.app.store.lang=='zh' else "Class 3A")
        for i in range(3):
            g = Group(f"第{i+1}组" if self.app.store.lang=='zh' else f"Group {i+1}")
            for j in range(4):
                g.members.append(Member(f"学生 {i+1}-{j+1}" if self.app.store.lang=='zh' else f"Student {i+1}-{j+1}", score=random.randint(0, 50)))
            c.groups.append(g)
        self.app.store.classes = [c]
        self.app.store.current_class_id = c.id
        self.app.store.mark_dirty()
        self.p_leader.refresh()

    def refresh_translations(self):
        t = TRANSLATIONS[self.app.store.lang]
        self.lbl_title.text = t['title']
        self.btn_test.text = t['test_data']
        self.btn_settings.text = t['setting']
        self.p_draw.rebuild_ui()
        self.p_ques.rebuild_ui()
        self.p_timer.rebuild_ui()
        self.p_leader.rebuild_ui()
        self.p_leader.refresh()

    # ==========================================
    # 9. 设置面板与全量文件夹导入操作
    # ==========================================
    def open_settings_popup(self, *args):
        t = TRANSLATIONS[self.app.store.lang]
        scroll = ScrollView()
        box = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(14), size_hint_y=None)
        box.bind(minimum_height=box.setter('height'))

        box.add_widget(CLabel(text=t['setting'], font_size=sp(22), bold=True))

        # --- 第一部分：数据与存储 (全量文件夹导入) ---
        box.add_widget(CLabel(text=t['settings_data'], bold=True, font_size=sp(16), color=C_ACCENT))
        box.add_widget(CLabel(text=f"{t['data_path']}\n{self.app.store.data_dir}", font_size=sp(11)))
        
        btn_import = RoundedButton(text=t['import_folder'], size_hint_y=None, height=dp(45), bg_color=C_SUCCESS)
        btn_import.bind(on_release=self.open_folder_chooser)
        box.add_widget(btn_import)
        
        btn_guide = RoundedButton(text=t['replay_guide'], size_hint_y=None, height=dp(45), bg_color=(0.5,0.5,0.5,1))
        btn_guide.bind(on_release=lambda x: [popup.dismiss(), OnboardingModal.show(self.app, None)])
        box.add_widget(btn_guide)

        # --- 第二部分：多语言 ---
        box.add_widget(CLabel(text="Language / 语言", bold=True, font_size=sp(16), color=C_ACCENT))
        lang_btn_row = BoxLayout(size_hint_y=None, height=dp(45), spacing=dp(10))
        btn_zh = RoundedButton(text="中文", bg_color=C_ACCENT if self.app.store.lang == 'zh' else (0.6,0.6,0.6,1))
        btn_en = RoundedButton(text="English", bg_color=C_ACCENT if self.app.store.lang == 'en' else (0.6,0.6,0.6,1))
        lang_btn_row.add_widget(btn_zh)
        lang_btn_row.add_widget(btn_en)
        box.add_widget(lang_btn_row)

        # --- 第三部分：WebDAV ---
        box.add_widget(CLabel(text=t['webdav_title'], bold=True, font_size=sp(16), color=C_ACCENT))
        inp_server = TextInput(text=self.app.store.webdav_server, hint_text="https://dav.jianguoyun.com/dav", multiline=False, size_hint_y=None, height=dp(45))
        inp_user = TextInput(text=self.app.store.webdav_user, multiline=False, size_hint_y=None, height=dp(45))
        inp_pass = TextInput(text=self.app.store.webdav_pass, password=True, multiline=False, size_hint_y=None, height=dp(45))

        box.add_widget(CLabel(text=t['webdav_server'], font_size=sp(11)))
        box.add_widget(inp_server)
        box.add_widget(CLabel(text=t['webdav_user'], font_size=sp(11)))
        box.add_widget(inp_user)
        box.add_widget(CLabel(text=t['webdav_pass'], font_size=sp(11)))
        box.add_widget(inp_pass)

        dav_row = BoxLayout(size_hint_y=None, height=dp(45), spacing=dp(6))
        btn_up = RoundedButton(text=t['webdav_upload'], bg_color=C_SUCCESS)
        btn_down = RoundedButton(text=t['webdav_download'], bg_color=C_ACCENT)
        dav_row.add_widget(btn_up)
        dav_row.add_widget(btn_down)
        box.add_widget(dav_row)

        scroll.add_widget(box)
        popup = Popup(title="Settings", content=scroll, size_hint=(0.9, 0.9))

        def set_lang(lang):
            self.app.store.lang = lang
            self.app.store.mark_dirty()
            self.refresh_translations()
            popup.dismiss()

        btn_zh.bind(on_release=lambda x: set_lang('zh'))
        btn_en.bind(on_release=lambda x: set_lang('en'))

        def sync_dav(is_upload):
            self.app.store.webdav_server, self.app.store.webdav_user, self.app.store.webdav_pass = inp_server.text.strip(), inp_user.text.strip(), inp_pass.text.strip()
            self.app.store.save()
            engine = WebDAVEngine(self.app.store.webdav_server, self.app.store.webdav_user, self.app.store.webdav_pass)
            
            def run():
                if is_upload:
                    res = engine.upload_file(self.app.store.filepath)
                    self.show_toast_msg("Upload Success!" if res else "Upload Failed!")
                else:
                    res = engine.download_file(self.app.store.filepath)
                    if res:
                        self.app.store.load()
                        Clock.schedule_once(lambda dt: self.refresh_translations(), 0)
                    self.show_toast_msg("Download Success!" if res else "Download Failed!")
            threading.Thread(target=run).start()

        btn_up.bind(on_release=lambda x: sync_dav(True))
        btn_down.bind(on_release=lambda x: sync_dav(False))
        popup.open()

    def open_folder_chooser(self, *args):
        """打开文件夹选择器以导入全部数据和题库"""
        box = BoxLayout(orientation='vertical')
        fc = FileChooserListView(dirselect=True, path=os.path.expanduser('~'))
        box.add_widget(fc)
        
        btn_row = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(10))
        btn_cancel = RoundedButton(text="取消", bg_color=(0.5,0.5,0.5,1))
        btn_ok = RoundedButton(text="确定导入选中文件夹", bg_color=C_SUCCESS)
        btn_row.add_widget(btn_cancel)
        btn_row.add_widget(btn_ok)
        box.add_widget(btn_row)

        popup = Popup(title="选择包含题库/数据的文件夹", content=box, size_hint=(0.9, 0.9))
        btn_cancel.bind(on_release=popup.dismiss)
        
        def do_import(*args):
            sel = fc.selection
            target_dir = sel[0] if sel else fc.path
            if os.path.isdir(target_dir):
                success = self.app.store.import_from_folder(target_dir)
                t = TRANSLATIONS[self.app.store.lang]
                self.show_toast_msg(t['toast_import_ok'] if success else t['toast_import_fail'])
                if success:
                    self.refresh_translations()
            popup.dismiss()

        btn_ok.bind(on_release=do_import)
        popup.open()

    @kivy.clock.mainthread
    def show_toast_msg(self, msg):
        lbl = Label(text=msg, color=(1,1,1,1), font_size=sp(14))
        popup = Popup(title="", content=lbl, size_hint=(0.7, 0.12), auto_dismiss=True)
        popup.open()
        Clock.schedule_once(lambda dt: popup.dismiss(), 2.0)

# ==========================================
# 10. APP 核心主类与启动检测
# ==========================================
class SmartClassroomApp(App):
    def build(self):
        self.title = APP_NAME
        self.store = DataStore()
        self.store.load()
        
        # 定时保存机制
        Clock.schedule_interval(self._autosave_tick, AUTOSAVE_INTERVAL)
        self.main_screen = MainScreen(self)
        return self.main_screen
        
    def on_start(self):
        # 智能新手引导生命周期
        if self.store.is_first_time:
            OnboardingModal.show(self, self.main_screen.p_leader.refresh)
        else:
            self.main_screen.p_leader.refresh()

    def _autosave_tick(self, dt):
        if self.store._dirty: self.store.save()

    def on_stop(self):
        self.store.save()

if __name__ == "__main__":
    SmartClassroomApp().run()