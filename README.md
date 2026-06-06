# agent-skills

#### 介绍

Claude Code 技能仓库，包含可用于 Claude Code 的技能。主要组件是 `skill-creator`，一个用于创建、评估和改进其他技能的元技能。

#### 软件架构

```
agent-skills/
├── .claude/
│   └── skills/                      # 项目专属技能目录
│       ├── skill-creator/            # 技能创建器
│       ├── uv-creator/               # UV 环境创建器
│       ├── train-model/              # 模型训练器
│       └── git-commit-creator/       # Git Commit 生成器
├── skill-creator/                   # 技能源码
├── uv-creator/                      # UV 环境创建器源码
├── train-model/                     # 模型训练器源码
├── git-commit-creator/              # Git Commit 生成器源码
└── template/                        # 技能模板
```

#### 安装技能
```bash
# 创建项目专属技能目录
mkdir -p .claude/skills

# 安装 skill-creator
cp -r skill-creator .claude/skills/

# 安装 uv-creator
cp -r uv-creator .claude/skills/

# 安装 train-model
cp -r train-model .claude/skills/

# 安装 git-commit-creator
cp -r git-commit-creator .claude/skills/
```

安装后的目录结构：

```
.claude/skills/
├── skill-creator/
├── uv-creator/
│   └── SKILL.md          # UV 环境创建器技能定义
├── train-model/
│   └── SKILL.md          # 模型训练器技能定义
└── git-commit-creator/
    └── SKILL.md          # Git Commit 生成器技能定义
```

#### 使用说明

安装完成后，在 Claude Code 中可以直接使用已安装的技能。技能会根据其 `description` 字段自动触发。

