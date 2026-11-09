#!/bin/bash
# ========================================
# 媒体内容获取工具链 - 环境初始化脚本
# ========================================
# 用法: bash setup-media-tools.sh
#
# 功能:
#   1. 克隆 chubbyskills 到工作目录
#   2. 安装 Python 依赖 (funasr, torch, faster-whisper, yt-dlp)
#   3. 检查 ffmpeg 和 lark-cli
#   4. 输出环境状态报告
#
# 适用场景:
#   - 用户在 onboarding 第五步选择安装媒体工具时运行
#   - 新环境部署时运行
# ========================================

set -e

WORK_DIR="${WORK_DIR:-/data/user/work}"
CHUBBY_DIR="${CHUBBY_DIR:-$WORK_DIR/chubbyskills}"

echo "🔧 媒体内容获取工具链 - 环境初始化"
echo "======================================"
echo ""

# --- 0. 前置检查 ---
echo "📌 [0/5] 前置环境检查..."

# Python
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | awk '{print $2}')
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
        echo "  ✅ Python $PY_VER"
    else
        echo "  ❌ Python $PY_VER（需要 3.10+）"
        echo "     请升级 Python: https://python.org"
        exit 1
    fi
else
    echo "  ❌ Python 3 未安装"
    echo "     安装方式: apt install python3 / brew install python3"
    exit 1
fi

# git
if command -v git &>/dev/null; then
    echo "  ✅ git $(git --version | awk '{print $3}')"
else
    echo "  ❌ git 未安装"
    echo "     安装方式: apt install git / brew install git"
    exit 1
fi

# pip
if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    echo "  ✅ pip 已安装"
else
    echo "  ❌ pip 未安装"
    echo "     安装方式: python3 -m ensurepip"
    exit 1
fi

echo "  ✅ 前置环境检查通过"
echo ""

# --- 1. ffmpeg ---
echo "📌 [1/5] 检查 ffmpeg..."
if command -v ffmpeg &>/dev/null; then
    echo "  ✅ ffmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
else
    echo "  ❌ ffmpeg 未安装"
    echo "     Ubuntu: sudo apt install ffmpeg"
    echo "     macOS: brew install ffmpeg"
    exit 1
fi

# --- 2. chubbyskills ---
echo ""
echo "📌 [2/5] 检查 chubbyskills..."
if [ -d "$CHUBBY_DIR/.git" ]; then
    echo "  ✅ 已存在，更新中..."
    cd "$CHUBBY_DIR" && git pull --quiet 2>/dev/null || echo "  ⚠️ 更新失败（网络问题），使用现有版本"
else
    echo "  📦 克隆 chubbyskills..."
    git clone https://github.com/chubbyguan/chubbyskills.git "$CHUBBY_DIR" 2>/dev/null || {
        echo "  ⚠️ GitHub 克隆失败，尝试 Gitee 镜像..."
        git clone https://gitee.com/chubbyguan/chubbyskills.git "$CHUBBY_DIR" 2>/dev/null || {
            echo "  ❌ 克隆失败，请检查网络"
            exit 1
        }
    }
fi
echo "  ✅ chubbyskills 就绪"

# --- 3. Python 依赖 ---
echo ""
echo "📌 [3/5] 安装 Python 依赖..."
PIP_FLAG=""
if [ "$(id -u)" = "0" ] || [ -z "$VIRTUAL_ENV" ]; then
    PIP_FLAG="--break-system-packages"
fi

# 轻量依赖（公众号、X 图文、小红书图文）
echo "  📦 安装轻量依赖..."
pip install beautifulsoup4 pymupdf markitdown $PIP_FLAG 2>/dev/null || true

# 视频转录依赖（funasr + torch）
echo "  📦 安装视频转录依赖（funasr + torch，约 3GB）..."
pip install funasr modelscope torch torchaudio $PIP_FLAG 2>/dev/null || {
    echo "  ⚠️ funasr 安装失败，视频转录功能不可用"
    echo "     手动安装: pip install funasr modelscope torch torchaudio $PIP_FLAG"
}

# 播客转录依赖（faster-whisper）
echo "  📦 安装播客转录依赖（faster-whisper）..."
pip install faster-whisper $PIP_FLAG 2>/dev/null || {
    echo "  ⚠️ faster-whisper 安装失败，播客转录功能不可用"
}

# yt-dlp（B站/YouTube/TikTok/微博/知乎视频下载）
echo "  📦 安装 yt-dlp..."
pip install yt-dlp $PIP_FLAG 2>/dev/null || true

echo "  ✅ Python 依赖安装完成"

# --- 4. lark-cli ---
echo ""
echo "📌 [4/5] 检查 lark-cli..."
if command -v lark-cli &>/dev/null; then
    echo "  ✅ lark-cli 已安装"
    # 检查认证状态
    AUTH_STATUS=$(lark-cli auth status 2>/dev/null || echo "unknown")
    if echo "$AUTH_STATUS" | grep -qi "logged in\|已登录\|active"; then
        echo "  ✅ lark-cli 已认证"
    else
        echo "  ⚠️ lark-cli 未认证，飞书社区内容需要先运行: lark-cli auth login"
    fi
else
    echo "  ⚠️ lark-cli 未安装"
    echo "     飞书社区/Wiki 内容获取需要 lark-cli"
    echo "     安装方式请参考: https://github.com/larksuite/lark-cli"
fi

# --- 5. 环境变量检查 ---
echo ""
echo "📌 [5/5] 环境变量检查..."
[ -n "$XHS_COOKIE" ] && echo "  ✅ XHS_COOKIE 已设置" || echo "  ⚠️ XHS_COOKIE 未设置（小红书抓取可能被风控）"
[ -n "$DEEPSEEK_API_KEY" ] && echo "  ✅ DEEPSEEK_API_KEY 已设置" || echo "  ⚠️ DEEPSEEK_API_KEY 未设置（YouTube翻译/爆款拆解不可用）"
[ -n "$HF_ENDPOINT" ] && echo "  ✅ HF_ENDPOINT=$HF_ENDPOINT" || echo "  💡 建议设置 HF_ENDPOINT=https://hf-mirror.com（国内模型下载加速）"

# --- 状态报告 ---
echo ""
echo "======================================"
echo "📊 环境状态报告"
echo "======================================"
echo ""
echo "平台支持矩阵："
echo ""
echo "| 平台        | 状态 | 工具                          |"
echo "|-------------|------|-------------------------------|"
echo "| 微信公众号   |  ✅  | curl + MicroMessenger UA       |"
echo "| 小红书       |  ✅  | chubbyskills/fetch_note.py    |"
echo "| 小宇宙播客   |  ✅  | 直接下载 + faster-whisper     |"
echo "| 飞书社区     |  $(command -v lark-cli &>/dev/null && echo '✅' || echo '⚠️')  | lark-cli docs +fetch           |"
echo "| 抖音         |  ✅  | chubbyskills/douyin-transcribe|"
echo "| B站          |  ✅  | chubbyskills/bilibili-transcribe|"
echo "| YouTube      |  ✅  | chubbyskills/youtube-transcribe|"
echo "| TikTok       |  ✅  | chubbyskills/tiktok-transcribe|"
echo "| 微博         |  ✅  | chubbyskills/weibo-transcribe |"
echo "| 知乎         |  ✅  | chubbyskills/zhihu-transcribe |"
echo "| X/Twitter    |  ✅  | chubbyskills/x-ingest         |"
echo "| 喜马拉雅     |  ✅  | chubbyskills/podcast-transcribe|"
echo ""
echo "chubbyskills 路径: $CHUBBY_DIR"
echo ""
echo "常用命令："
echo "  小红书:  python3 $CHUBBY_DIR/xiaohongshu-ingest/scripts/fetch_note.py '链接' -o ./out"
echo "  播客:    python3 $CHUBBY_DIR/podcast-transcribe/scripts/transcribe.py '链接' -o ./out"
echo "  公众号:  curl -sL -H 'User-Agent: MicroMessenger/8.0.44' '链接' -o article.html"
echo "  飞书:    lark-cli docs +fetch --doc '链接' --doc-format markdown"
echo ""
echo "详细使用方法请参阅 skill 的 references/media-ingestion-guide.md"
echo ""
echo "✅ 初始化完成"
