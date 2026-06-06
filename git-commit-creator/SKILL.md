---
name: git-commit-creator
description: 帮助用户生成 git commit message。检测未提交的更改，分析更改内容，生成符合约定式提交格式的 commit message，询问用户确认后执行 git add 和 git commit。当用户需要提交代码时使用此技能。
---

# Git Commit 生成器

帮助用户生成符合约定式提交（Conventional Commits）格式的 git commit message。

## 核心原则

1. **检测未提交更改** - 自动检测 git 未 add 和未 commit 的更改
2. **智能分析** - 分析更改的内容和影响范围，不关注技术细节
3. **格式规范** - 使用约定式提交格式
4. **总分结构** - 先英文总结，再中文分点说明
5. **用户确认** - 执行前询问用户确认

## Commit 类型

| 类型 | 说明 | 示例 |
|------|------|------|
| feat | 新功能（feature） | feat: add user login |
| fix | 修复 bug | fix: resolve memory leak |
| docs | 文档更新 | docs: update README |
| style | 格式调整（不影响代码运行） | style: fix indentation |
| refactor | 重构代码 | refactor: optimize algorithm |
| perf | 性能优化 | perf: reduce memory usage |
| test | 添加测试 | test: add unit tests |
| chore | 构建/工具变动 | chore: update dependencies |
| revert | 撤销提交 | revert: feat: add feature X |

## 工作流程

### 第 1 步：检测更改

运行以下命令检测更改：

```bash
# 检查未 add 的更改
git status

# 查看未 add 的更改详情
git diff

# 查看已 add 但未 commit 的更改
git diff --cached
```

### 第 2 步：分析更改

分析检测到的更改内容，重点关注：

1. **影响范围** - 涉及哪些文件或模块
2. **更改类型** - 是新功能、修复 bug、还是其他类型

**注意**：不需要分析技术实现细节和更改的目的，只需要说明"改了什么"。

### 第 3 步：生成 commit message

根据分析结果，使用"总分"格式生成 commit message：

**格式模板**：

```
<type>: <简短总结（英文）>

<详细说明（中文）>
```

**语言规范**：
- 简短总结（第一行）：使用英文
- 详细说明（分点列表）：使用中文

**示例**：

```
feat: add user authentication

本次更改新增用户认证相关功能：

- 新增登录/注册页面
- 添加 token 管理模块
- 集成第三方 OAuth 登录
```

### 第 4 步：展示并询问

向用户展示生成的 commit message，并询问：

```
建议的 commit message：

<生成的 commit message>

是否执行以下操作？
1. 执行 git add 和 git commit
2. 仅使用此 commit message，手动执行
3. 重新生成
```

### 第 5 步：执行或取消

根据用户选择执行相应操作：

**选择 1（执行）**：
```bash
# 添加所有更改
git add .

# 提交
git commit -m "<commit message>"
```

**选择 2 或 3**：不执行 git 命令

## 常见场景

### 场景 1：混合类型的更改

当更改包含多种类型时，选择主要类型，并在详细说明中说明其他内容。

```
feat: add user profile feature

本次更改新增用户档案相关功能：

- 新增用户资料编辑页面
- 添加头像上传功能
- 优化个人信息展示样式
```

### 场景 2：修复 bug

```
fix: resolve data loading error

修复了数据加载相关的问题：

- 修正 JSON 解析逻辑
- 添加错误处理机制
- 优化重试策略
```

### 场景 3：重构代码

```
refactor: simplify data processing pipeline

简化了数据处理相关代码：

- 合并重复的转换函数
- 优化数据流向
- 移除冗余代码
```

### 场景 4：文档更新

```
docs: update project documentation

更新了项目相关文档：

- 补充 API 说明
- 添加使用示例
- 更新环境配置指南
```

### 场景 5：无更改

如果检测到没有未提交的更改，告知用户：

```
当前没有需要提交的更改。
```

## 输出格式

### 有更改时

```
检测到以下未提交的更改：
<列出更改的文件>

建议的 commit message：

<生成的 commit message>

是否执行以下操作？
1. 执行 git add 和 git commit
2. 仅使用此 commit message，手动执行
3. 重新生成
```

### 无更改时

```
当前没有需要提交的更改。
```

## 注意事项

- 简短总结（第一行）使用英文，不超过 50 个字符
- 详细说明（分点列表）使用中文
- 每点说明一个更改
- 不需要包含技术实现细节
- 不需要最后的总结行
- 执行 git add 前确保用户确认
- 如果用户不需要执行或忽略问题，不要执行 git 命令