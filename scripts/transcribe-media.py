#!/usr/bin/env python3
"""
播客/视频转录脚本
支持：小宇宙、喜马拉雅、B站、YouTube 等平台
依赖：faster-whisper, yt-dlp, ffmpeg

用法:
  python3 transcribe-media.py <url> --project-path /path/to/wiki -t "标题"
  python3 transcribe-media.py <url> --project-path /path/to/wiki -p video -t "标题"
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path
from datetime import datetime


def run_command(cmd, cwd=None):
    """运行 shell 命令并返回输出"""
    result = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True,
        cwd=cwd
    )
    if result.returncode != 0:
        print(f"命令失败: {cmd}")
        print(f"错误: {result.stderr}")
        return None
    return result.stdout


def download_audio(url, output_dir, filename):
    """使用 yt-dlp 下载音频"""
    output_path = output_dir / filename
    cmd = (
        f'yt-dlp -x --audio-format mp3 --audio-quality 0 '
        f'-o "{output_path}.%(ext)s" "{url}"'
    )
    print(f"正在下载: {url}")
    result = run_command(cmd)
    if result is None:
        return None

    # yt-dlp 会自动添加扩展名
    audio_file = output_path.with_suffix('.mp3')
    if audio_file.exists():
        return audio_file

    # 尝试其他可能的扩展名
    for ext in ['.m4a', '.webm', '.opus']:
        alt_file = output_path.with_suffix(ext)
        if alt_file.exists():
            return alt_file

    return None


def transcribe_audio(audio_file, output_file):
    """使用 faster-whisper 转录音频"""
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("请先安装 faster-whisper: pip install faster-whisper")
        return False

    print(f"正在转录: {audio_file}")

    # 加载模型（使用 small 模型，中文支持较好）
    model = WhisperModel("small", device="cpu", compute_type="int8")

    # 转录
    segments, info = model.transcribe(
        str(audio_file),
        language="zh",
        task="transcribe",
        vad_filter=True
    )

    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"# 转录文本\n\n")
        f.write(f"- 源文件: {audio_file.name}\n")
        f.write(f"- 转录时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"- 检测语言: {info.language} (置信度: {info.language_probability:.2f})\n\n")
        f.write("---\n\n")

        for segment in segments:
            timestamp = f"[{segment.start:.2f}s -> {segment.end:.2f}s]"
            f.write(f"{timestamp} {segment.text}\n\n")

    print(f"转录完成: {output_file}")
    return True


def process_podcast(url, project_path, title=None):
    """处理播客：下载 + 转录"""
    raw_dir = Path(project_path) / "raw"
    podcasts_dir = raw_dir / "podcasts"

    if title is None:
        title = f"podcast_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    # 确保目录存在
    podcasts_dir.mkdir(parents=True, exist_ok=True)

    # 下载音频
    audio_file = download_audio(url, podcasts_dir, title)
    if audio_file is None:
        print("下载失败")
        return False

    # 转录
    transcript_file = podcasts_dir / f"{title}.md"
    return transcribe_audio(audio_file, transcript_file)


def process_video(url, project_path, title=None):
    """处理视频：下载 + 转录"""
    raw_dir = Path(project_path) / "raw"
    videos_dir = raw_dir / "videos"

    if title is None:
        title = f"video_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    # 确保目录存在
    videos_dir.mkdir(parents=True, exist_ok=True)

    # 下载音频
    audio_file = download_audio(url, videos_dir, title)
    if audio_file is None:
        print("下载失败")
        return False

    # 转录
    transcript_file = videos_dir / f"{title}.md"
    return transcribe_audio(audio_file, transcript_file)


def main():
    parser = argparse.ArgumentParser(description='播客/视频转录工具')
    parser.add_argument('url', help='播客或视频的 URL')
    parser.add_argument('--project-path', '-d', required=True,
                        help='Wiki 项目根目录路径')
    parser.add_argument('-t', '--title', help='输出文件名（不含扩展名）')
    parser.add_argument('-p', '--platform', choices=['podcast', 'video'],
                        default='podcast', help='平台类型（默认: podcast）')

    args = parser.parse_args()

    if args.platform == 'podcast':
        success = process_podcast(args.url, args.project_path, args.title)
    else:
        success = process_video(args.url, args.project_path, args.title)

    if success:
        platform_dir = Path(args.project_path) / "raw" / f"{args.platform}s"
        print("\n处理完成！")
        print(f"文件保存在: {platform_dir}")
    else:
        print("\n处理失败")
        sys.exit(1)


if __name__ == '__main__':
    main()
