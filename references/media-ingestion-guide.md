---
name: yike-easywiki-skill/media-ingestion-guide
description: >
  媒体内容摄入工作手册。当用户需要获取外部媒体内容（文章、播客、视频）到知识库时，
  Read 本文件查看各平台的获取方法和命令。
---

# 媒体内容摄入工作手册

> 本文档记录了 yike-easywiki-skill 支持的所有内容获取路径。
> 按平台查找对应命令和注意事项即可。

## 快速开始

```bash
# 1. 初始化工具链（首次使用时运行）
bash <skill-path>/scripts/setup-media-tools.sh

# 2. 设置环境变量（可选但推荐）
export HF_ENDPOINT=https://hf-mirror.com
export XHS_COOKIE="你的小红书cookie"     # 提高小红书成功率
export DEEPSEEK_API_KEY="你的key"        # YouTube翻译/爆款拆解
```

**前置检查**：下文各平台的抓取命令都调用 `chubbyskills/<平台>-ingest/scripts/`，这个目录**不在本 skill 内**，是安装器 clone 下来的外部仓库，默认落在 `~/wiki-tools/chubbyskills`。

```bash
ls ~/wiki-tools/chubbyskills 2>/dev/null || echo "未安装，先跑第 1 步"
```

目录不存在就按第 1 步安装，或先 `export WORK_DIR=<你的路径>` 再运行安装器，然后把下面命令里的相对路径换成实际路径。不安装也能用：微信公众号那套 `curl` 方案、`transcribe-media.py` 处理本地音视频，都不依赖 `chubbyskills`。

## 平台获取方式速查

### 1. 微信公众号

```bash
# 方法：curl + MicroMessenger User-Agent
curl -sL -H "User-Agent: MicroMessenger/8.0.44" \
  "https://mp.weixin.qq.com/s/xxxxx" -o article.html

# 然后用 Python 提取正文
python3 -c "
import re, html as h
with open('article.html') as f: c = f.read()
# 提取标题
title = re.findall(r'var msg_title = \"(.*?)\";', c)
# 提取正文（js_content 区域）
body = re.findall(r'id=\"js_content\"[^>]*>(.*?)</div>', c, re.S)
# 清理HTML标签
if body: text = re.sub(r'<[^>]+>', '', body[0])
"
```

**注意**：
- `mp.weixin.qq.com/s/` 链接 → 可抓取
- `mp.weixin.qq.com/sph/` 链接（视频号）→ **无法抓取**，需要用户提供文字
- MicroMessenger UA 绕过验证码，获取完整页面（3MB+）

### 2. 小红书

```bash
# 图文笔记（零依赖）
python3 chubbyskills/xiaohongshu-ingest/scripts/fetch_note.py \
  "http://xhslink.com/xxxx" -o ./out --no-video

# 视频笔记（含转录，需要 funasr + ffmpeg）
python3 chubbyskills/xiaohongshu-ingest/scripts/fetch_note.py \
  "http://xhslink.com/xxxx" -o ./out

# 抓取失败时手动提供正文
python3 chubbyskills/xiaohongshu-ingest/scripts/fetch_note.py \
  "链接" -o ./out --fallback-text 手动正文.txt
```

**工具路径**：`chubbyskills/xiaohongshu-ingest/scripts/fetch_note.py`

### 3. 小宇宙播客

```bash
# 方式一：使用 skill 自带转录脚本
python3 <skill-path>/scripts/transcribe-media.py \
  "https://www.xiaoyuzhoufm.com/episode/xxxx" \
  --project-path /path/to/wiki -t "播客标题"

# 方式二：手动下载 + 转录
curl -sL "https://www.xiaoyuzhoufm.com/episode/xxxx" -o page.html
grep -oP 'https://[^"]+\.mp3' page.html | head -1
curl -sL "音频URL" -o podcast.mp3

python3 -c "
from faster_whisper import WhisperModel
model = WhisperModel('base', device='cpu', compute_type='int8')
segments, info = model.transcribe('podcast.mp3', language='zh')
for seg in segments:
    print(f'[{seg.start:.1f}-{seg.end:.1f}] {seg.text}')
" > transcript.txt
```

### 4. 飞书社区 / Wiki

```bash
# 飞书社区页面内容在 iframe 里，直接用 lark-cli fetch iframe 的 wiki token
# 步骤1：浏览器打开飞书社区页面，找到 iframe URL（leespace.larkenterprise.com/wiki/xxxx）
# 步骤2：用 lark-cli 读取
lark-cli docs +fetch \
  --doc "https://leespace.larkenterprise.com/wiki/xxxx" \
  --doc-format markdown --detail simple

# 首次使用需要认证
lark-cli auth login
```

### 5. 抖音

```bash
python3 chubbyskills/douyin-transcribe/scripts/transcribe.py \
  "https://www.douyin.com/video/xxxx" -o ./out
```

### 6. B站

```bash
# 字幕优先，无字幕走音频转录
python3 chubbyskills/bilibili-transcribe/scripts/transcribe.py \
  "https://www.bilibili.com/video/BVxxxx" -o ./out
```

**注意**：B站 412 反爬限制，音频下载可能失败

### 7. YouTube

```bash
# 转录 + 英文翻译为中文
DEEPSEEK_API_KEY="your-key" \
python3 chubbyskills/youtube-transcribe/scripts/transcribe.py \
  "https://www.youtube.com/watch?v=xxxx" -o ./out
```

**注意**：YouTube SSL 连接不稳定，可能需要重试

### 8. TikTok / 微博 / 知乎

```bash
# TikTok
python3 chubbyskills/tiktok-transcribe/scripts/transcribe.py "链接" -o ./out

# 微博
python3 chubbyskills/weibo-transcribe/scripts/transcribe.py "链接" -o ./out

# 知乎
python3 chubbyskills/zhihu-transcribe/scripts/transcribe.py "链接" -o ./out
```

### 9. X / Twitter

```bash
# 图文（零依赖）
python3 chubbyskills/x-ingest/scripts/fetch_tweet.py "https://x.com/user/status/xxxx" -o ./out

# 视频需要 funasr + ffmpeg
```

### 10. 用户提供文本

直接粘贴对话中，或保存为文件后处理。

## 转录工具选择

| 场景 | 工具 | 优势 |
|------|------|------|
| 短视频（小红书/抖音/B站等） | SenseVoice (funasr) | 中文效果极好，RTF ~0.06 |
| 长音频（播客/讲座） | faster-whisper | 稳定，支持时间戳 |

## 摄入到 Wiki 的标准流程

```
1. 获取原始内容 → raw/articles/ 或 raw/podcasts/ 或 raw/videos/
2. 创建结构化摘要 → wiki/sources/（外部资料）或 wiki/thoughts/（个人见解）
3. 更新 wiki/index.md（页面列表 + 统计数字）
4. 更新 wiki/log.md（操作记录）
5.（可选）更新相关 synthesis 或 concept 页面
```

### 页面模板

**sources 页面**：
```markdown
---
title: 标题
category: sources
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: 作者
source: 来源平台
url: 原始链接
tags: [标签1, 标签2]
---

# 标题

> 作者（平台），日期

## 原始资料
[[../raw/articles/文件名]]

## 关键内容
### 一、主题1
> 原文引用

### 二、主题2

## 金句摘录

## 与 Wiki 现有知识的连接
- [[页面名]]：连接说明
```

**thoughts 页面**：
```markdown
---
title: 标题
category: thoughts
status: 萌芽 | 成形 | 成熟
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [标签]
---

# 标题

## 触发点
## 核心想法
## 与现有知识的连接
## 待验证的问题
## 可能的行动
```

### 引用规范

- **外部来源**：`人名（[[出处页面]]）` + blockquote 原文
- **个人观察**：`**个人观察**：` 前缀
- **对话转录**：先经本人校准确认，存入 `thoughts/`

## 环境变量

| 变量 | 用途 | 必需性 |
|------|------|--------|
| `HF_ENDPOINT` | 国内模型下载加速 `=https://hf-mirror.com` | 推荐 |
| `XHS_COOKIE` | 小红书登录态，提高成功率 | 可选 |
| `DEEPSEEK_API_KEY` | YouTube翻译、爆款拆解 | 可选 |
| `WORK_DIR` | chubbyskills 安装路径，默认 `~/wiki-tools` | 可选 |

## 故障排查

| 问题 | 解决方案 |
|------|---------|
| 小红书抓取被风控 | 设置 `XHS_COOKIE`；或用 `--fallback-text` 手动提供正文 |
| 公众号返回验证码 | 确认使用 `MicroMessenger/8.0.44` UA |
| B站 412 错误 | 使用字幕优先策略；或换用浏览器手动下载 |
| YouTube SSL 失败 | 多试几次；或用 yt-dlp 直接下载 |
| 飞书 iframe 跨域 | 用 lark-cli docs +fetch 读取 wiki token |
| 模型下载失败 | 设置 `HF_ENDPOINT=https://hf-mirror.com` |
| funasr 导入失败 | 确认 torch 已正确安装 |
