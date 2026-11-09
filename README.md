# Easy Wiki Skill

从零搭建 LLM 知识库的引导 Skill。安装后，用户只需说"我想搭建知识库"，即可通过结构化访谈生成定制化的知识库项目。

## 安装

```bash
npx skills add https://github.com/ElanneWang/yike-easywiki-skill.git
```

## 使用

安装后，在你的 AI 编码工具中打开任意项目（或新建一个），说：

> 我想搭建一个知识库

Skill 会自动激活，通过访谈引导你完成知识库的搭建。

## 它做什么

```
用户表达搭建意图
    ↓
场景识别（个人 / 组织共享 / 老板第二大脑）
    ↓
结构化访谈（挖掘真实需求）
    ↓
生成知识库（目录 + AGENTS.md + 模板）
    ↓
处理内容种子（演示完整流程）
    ↓
可选：安装媒体摄入工具
```

## 三种场景

| 场景 | 适用人群 | 核心问题 |
|------|---------|---------|
| 个人知识库 | 研究者、创业者、投资人、创作者 | 你消费什么、你怎么思考、你想产出什么 |
| 组织共享知识库 | 企业中的决策层、产品经理、研发、销售 | 你服务谁、协作关系是什么、输入输出是什么 |
| 老板第二大脑（决策分身） | 创始人/一把手，及其助理、顾问 | 老板的词表是什么、怎么拍板、谁的话算数 |

## 项目结构

```
yike-easywiki-skill/
├── SKILL.md              # Skill 主文件（访谈流程和引导逻辑）
├── references/
│   ├── scenario-1.md     # 场景一访谈流程和翻译规则
│   ├── scenario-2.md     # 场景二访谈流程和翻译规则
│   ├── scenario-3.md     # 场景三（老板第二大脑）访谈流程和翻译规则
│   ├── templates.md      # AGENTS.md 模板 + 页面模板
│   └── media-ingestion-guide.md  # 媒体内容摄入工作手册（12 个平台）
├── assets/
│   ├── bootstrap-agents.md   # AGENTS.md 初始模板
│   ├── readme-template.md    # README 模板
│   ├── gitignore-template    # .gitignore 模板
│   ├── index-template.md     # wiki/index.md 模板
│   └── log-template.md       # wiki/log.md 模板
├── scripts/
│   ├── init-wiki.sh          # 目录结构初始化脚本
│   ├── setup-media-tools.sh  # 媒体工具环境初始化
│   └── transcribe-media.py   # 播客/视频转录脚本
└── evals/
    └── evals.json        # 测试用例
```

## 核心设计

### 双向关联约束

知识库不是文件仓库，而是知识网络。页面之间的关联分三级：

- **必须双向**：concepts↔cases（所有场景）；outputs↔concepts, outputs↔cases（场景一/二）；decisions↔concepts/cases（场景三）
- **建议双向**：thoughts↔sources, thoughts↔cases, sources↔entities
- **单向引用**：synthesis→sources, cases→sources
- **场景三核心链**：raw→concepts→cases→decisions，claims.md 与 verification.md 横切台账

### 访谈驱动

不直接给模板，而是通过对话挖掘用户真实需求。访谈节奏：每次只问 2-3 个问题，确认理解后再继续。

### 自包含

知识库核心功能（文本处理、关联、检索）完全自包含，模板、脚本、配置全部打包在 skill 内。媒体摄入工具（播客转录、视频下载等）为可选安装，需联网下载第三方工具集 chubbyskills。

## 可选工具

如果用户日常会处理播客或视频内容，可以安装媒体摄入工具。工具已内置在 skill 中，无需从外部仓库克隆：

```bash
# 运行 skill 自带的安装脚本
bash scripts/setup-media-tools.sh
```

支持的平台：微信公众号、小红书、小宇宙播客、飞书社区、抖音、B站、YouTube、TikTok、微博、知乎、X/Twitter、喜马拉雅。

详细使用方法见 `references/media-ingestion-guide.md`。

## 许可

MIT
