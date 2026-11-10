#!/bin/bash
set -e

PROJECT_PATH="$1"
SCENARIO="$2"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$PROJECT_PATH" ] || [ -z "$SCENARIO" ]; then
    echo "Usage: bash init-wiki.sh <project-path> <scenario: personal|organizational|boss|project|department|open> [project-name|extra-dirs...]"
    echo "Example: bash init-wiki.sh ~/my-wiki personal raw/podcasts wiki/entities"
    echo "Example: bash init-wiki.sh ~/project-hub project 欧奇密码-儿童营养"
    echo "Example: bash init-wiki.sh ~/my-library open records notes"
    echo ""
    echo "Base directories created by scenario:"
    echo "  personal:       raw/, wiki/, wiki/concepts/, wiki/cases/"
    echo "  organizational: raw/, wiki/, wiki/concepts/, wiki/cases/, wiki/outputs/"
    echo "  boss:           raw/, wiki/, wiki/concepts/, wiki/cases/, wiki/decisions/"
    echo "  project:        raw/, wiki/, projects/ (third arg = first project name, copies project template)"
    echo "  open:           raw/, wiki/ (top-level categories come from the interview; pass them as extra dirs)"
    echo "  department:     raw/, wiki/, wiki/01-制度 ... wiki/06-培训, wiki/99-归档"
    echo ""
    echo "Pass extra directories as additional arguments based on interview results."
    echo "For the boss scenario, pass raw/meetings, raw/dictations, raw/artifacts,"
    echo "wiki/methodology, wiki/conversations etc. as extra dirs when needed."
    echo ""
    echo "wiki/index.md is pre-trimmed to common slots plus the current scenario's slots."
    exit 1
fi

if [ "$SCENARIO" != "personal" ] && [ "$SCENARIO" != "organizational" ] && [ "$SCENARIO" != "boss" ] && [ "$SCENARIO" != "project" ] && [ "$SCENARIO" != "department" ] && [ "$SCENARIO" != "open" ]; then
    echo "Error: scenario must be 'personal', 'organizational', 'boss', 'project', 'department' or 'open'"
    exit 1
fi

echo "Creating wiki project at: $PROJECT_PATH"
echo "Scenario: $SCENARIO"
echo ""

# Create base directories (minimal viable structure)
mkdir -p "$PROJECT_PATH"/raw
mkdir -p "$PROJECT_PATH"/wiki

# Create essential wiki subdirectories (scenario 4/5/6 organize by project, content type or user-defined categories, not by knowledge type)
if [ "$SCENARIO" != "project" ] && [ "$SCENARIO" != "department" ] && [ "$SCENARIO" != "open" ]; then
    mkdir -p "$PROJECT_PATH"/wiki/concepts
    mkdir -p "$PROJECT_PATH"/wiki/cases
fi

# department 场景：按判断动作分六类 + 归档
if [ "$SCENARIO" = "department" ]; then
    for d in "01-制度" "02-流程" "03-标准" "04-模板" "05-案例" "06-培训" "99-归档"; do
        mkdir -p "$PROJECT_PATH/wiki/$d"
    done
fi

if [ "$SCENARIO" = "organizational" ]; then
    mkdir -p "$PROJECT_PATH"/wiki/outputs
fi

if [ "$SCENARIO" = "boss" ]; then
    mkdir -p "$PROJECT_PATH"/wiki/decisions
fi

mkdir -p "$PROJECT_PATH"/wiki
if [ "$SCENARIO" = "project" ]; then
    mkdir -p "$PROJECT_PATH"/projects
fi

# Create extra directories passed as arguments (based on interview results)
shift 2
FIRST_PROJECT=""
if [ "$SCENARIO" = "project" ] && [ -n "$1" ]; then
    FIRST_PROJECT="$1"
    shift
fi
for dir in "$@"; do
    mkdir -p "$PROJECT_PATH"/"$dir"
    echo "  + extra dir: $dir"
done

# Add .gitkeep to all directories so they're tracked by git
find "$PROJECT_PATH" -type d -empty -exec touch {}/.gitkeep \;

# Copy template files
cp "$SKILL_DIR/assets/bootstrap-agents.md" "$PROJECT_PATH/AGENTS.md"
cp "$SKILL_DIR/assets/readme-template.md" "$PROJECT_PATH/README.md"
cp "$SKILL_DIR/assets/gitignore-template" "$PROJECT_PATH/.gitignore"
# 索引按场景裁剪：保留通用分类 + 当前场景专属分类，移除其他场景的槽位
awk -v sc="$SCENARIO" '
    /^<!--SCENARIO:[a-z]+-->$/ {
        tag = $0
        gsub(/<!--SCENARIO:|-->/, "", tag)
        skip = (tag != sc)
        next
    }
    /^<!--\/SCENARIO-->$/ { skip = 0; next }
    /^<!--COMMON-->$/ { skip = (sc == "project" || sc == "department" || sc == "open"); next }
    /^<!--\/COMMON-->$/ { skip = 0; next }
    !skip { print }
' "$SKILL_DIR/assets/index-template.md" > "$PROJECT_PATH/wiki/index.md"
cp "$SKILL_DIR/assets/log-template.md" "$PROJECT_PATH/wiki/log.md"

# project 场景：复制首个项目骨架，每个项目目录自包含
if [ "$SCENARIO" = "project" ] && [ -n "$FIRST_PROJECT" ]; then
    TARGET="$PROJECT_PATH/projects/$FIRST_PROJECT"
    mkdir -p "$TARGET"
    cp -r "$SKILL_DIR/assets/project-template/." "$TARGET/"
    mkdir -p "$TARGET/01-项目上下文/01-客户原始资料" "$TARGET/01-项目上下文/02-我方调研" "$TARGET/01-项目上下文/03-资料解读与映射"
    echo "  + project skeleton: projects/$FIRST_PROJECT"
fi

echo ""
echo "✓ Base directory structure created"
echo "✓ .gitkeep files added to empty directories"
echo "✓ Template files copied"
echo ""
echo "Created structure:"
find "$PROJECT_PATH" -type d | sort | sed 's|'"$PROJECT_PATH"'||' | head -20
echo ""
echo "Next steps:"
echo "  1. Open the project in your AI coding tool"
echo "  2. The AGENTS.md is in bootstrap state — the yike-easywiki-skill will trigger onboarding"
echo "  3. Follow the interview process to customize your knowledge base"
echo "  4. The Agent will create additional directories based on your interview answers"
