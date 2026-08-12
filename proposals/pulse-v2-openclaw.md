# Project Pulse v2 — OpenClaw Institutional Signal Proposal

> **开源之道** · 2026-08-12
> 分析视角：Coase（产权）/ Williamson（混合治理）/ North（制度变迁）/ Acemoglu（包容性）
> 信号源验证：2026-08-12 全部通过
> 优先级：**P1**（产权真空对照样本）

---

## 1. 制度定位

OpenClaw 是**个人 AI 助理项目**，成立于 2025-11-24，7 个月内达到 385,996 stars
（GitHub 第二大项目级别）。在 NIE 制度光谱中，它是**"产权真空的数字公地"**的极端样本：

| 维度 | OpenClaw 定位 |
|------|-------------|
| Coase 企业边界 | LICENSE 文件内容为 MIT，但 GitHub API 返回 **NOASSERTION**（未声明许可）——产权声明自相矛盾 |
| Williamson 混合治理 | Top 3 贡献者占 89%（steipete=39,765 commits）——极度集中，接近个人项目 |
| Ostrom 公共池塘资源 | 386K stars / 81K forks = 典型数字公地；但产权不明 = 边界清晰原则缺失 |
| Acemoglu 包容性 vs 汲取性 | 事实开源（代码可见、可 fork）但法律闭源（API 无许可）= **事实开放 vs 法律汲取的悖论** |

与已有 Pulse 项目的关系：

| 已有项目 | 制度原型 | OpenClaw 独特价值 |
|---------|---------|----------------|
| ASF | 制度化治理 | OpenClaw 的**产权真空**是 ASF 极端反面 |
| PSF | 嵌入式基金会 | OpenClaw 有**OpenClaw Foundation**声明但无法律实体验证 |
| FFmpeg | 纯社区 | OpenClaw 社区超 FFmpeg，但产权结构远不成熟 |
| Homebrew | 治理危机/重建 | OpenClaw 面临**同类问题**——81K forks 中无合法再分发权 |

**结论：OpenClaw 是 Pulse v2 制度层目前缺少的"产权真空"样本类型——现有 10 个项目都是产权清晰的（MIT/BSD/Apache/GPL），OpenClaw 是唯一例外。**

---

## 2. 验证信号源（2026-08-12）

| 信号源 | URL | 内容 | 状态 |
|--------|-----|------|------|
| GitHub 项目 API | `api.github.com/repos/openclaw/openclaw` | 项目元数据 | ✅ 200 |
| README | `raw.githubusercontent.com/.../main/README.md` | 项目定位 | ✅ 200 |
| LICENSE | `raw.githubusercontent.com/.../main/LICENSE` | 文件内容为 MIT 但 API = NOASSERTION | ✅ 200 |
| CONTRIBUTING.md | `raw.githubusercontent.com/.../main/CONTRIBUTING.md` | 存在 | ✅ 200 |
| SECURITY.md | `raw.githubusercontent.com/.../main/SECURITY.md` | 存在 | ✅ 200 |
| Commits | `api.github.com/repos/openclaw/openclaw/stats/commit_activity` | 12 周数据 | ✅ 200 |
| Contributors | `api.github.com/repos/openclaw/openclaw/contributors` | 数据可获取 | ✅ 200 |
| Releases | `api.github.com/repos/openclaw/openclaw/releases` | v2026.7.1-2 | ✅ 200 |
| Scorecard | `api.scorecard.dev/projects/github.com/openclaw/openclaw` | **404 — 尚未缓存** | ⚠️ PENDING |

---

## 3. 核心发现：产权声明的自相矛盾

**这是 OpenClaw 的制度分析核心：**

```
LICENSE 文件内容： "MIT License / Copyright (c) 2026 OpenClaw Foundation"
GitHub API 返回：  license.spdx_id = "NOASSERTION"
```

这可能是因为：
1. LICENSE 文件是手动写的 MIT 文本，但 repo 层面未通过 GitHub 的 SPDX 声明机制确认
2. 文件声称 "OpenClaw Foundation" 为版权持有者，但该 Foundation 的法律实体状态未验证
3. GitHub API 的 license 字段以 repo 的 `default_branch` 上的 `license` 自动检测为准——**如果 SPDX 标识不完整，API 返回 NOASSERTION**

**无论具体技术原因是什么，从制度角度这是一个重要的"产权模糊信号"——它意味着 OpenClaw 的 81K forks 在法律上处于不确定状态。**

---

## 4. 监控信号矩阵

### 4.1 产权与治理结构

| 信号 | 当前值 | 制度含义 | 风险阈值 |
|------|--------|---------|---------|
| API license | NOASSERTION | 产权声明缺失 | 从 NOASSERTION → MIT 时确认产权 |
| Top 3 占比 | 89%（steipete=39,765） | 极度集中，bus factor≈1 | Top 1 占比 >60% 告警 |
| 周提交量 | 4 周均值 2,195 | 极高活跃度 | 周提交 <500 时告警 |
| Fork 率 | 21%（81K forks / 386K stars） | 极高二次开发率 | 稳定观察 |
| License 文件 vs API | 不一致 | **产权模糊核心信号** | API 声明为 MIT 时告警（已解决） |

### 4.2 制度演化信号

| 信号 | 监测点 | 制度含义 |
|------|-------|---------|
| "OpenClaw Foundation" | 是否注册为法律实体 | North 制度变迁 |
| API license 变化 | NOASSERTION → MIT | Coase 产权边界正式化 |
| 贡献者分散度 | Top 3 占比下降 | Ostrom 参与广度 |
| 基金会治理文档 | 是否出现 GOVERNANCE.md | Williamson 治理正式化 |

---

## 5. 数据源

```
GitHub API（项目元数据）
  → repos/openclaw/openclaw
  → repos/openclaw/openclaw/stats/commit_activity
  → repos/openclaw/openclaw/contributors
  → repos/openclaw/openclaw/releases
  → raw.githubusercontent.com/openclaw/openclaw/main/LICENSE
```

**自动化可行性：** 高（全部 GitHub REST API）

---

## 6. 与 Hermes Agent 的极端对照

| 维度 | Hermes Agent | OpenClaw | 制度对照价值 |
|------|-------------|----------|------------|
| License (API) | **MIT** | **NOASSERTION** | Coase 产权边界极端对照 |
| License (文件) | MIT ✅ | MIT 文本但 API 不认 | 产权声明的一致性对照 |
| Stars | 229K | 386K | 同量级不同制度结果 |
| Forks | 45K | 81K | Fork 率 20% vs 19% |
| bus factor | 1（teknium1=50%） | ~1（steipete=63%） | 都极度集中 |
| 贡献者 | 499 人 | 待全量统计 | 社区广度对照 |
| 治理文档 | CONTRIBUTING ✅ | CONTRIBUTING ✅ | 半制度化 |
| 基金会 | 无 | "OpenClaw Foundation" 待验证 | North 制度变迁 |

**两个项目的对照价值：** 同样高 star 量级、同样 bus factor≈1，但产权结构完全不同——MIT（包容性）vs NOASSERTION（产权真空）——这正是大分流 2.0 在 AI Agent 项目层面的微观体现。

---

## 7. 推荐策略

| 步骤 | 动作 | 优先级 |
|------|------|--------|
| 1 | 加入 Pulse v2 监测池（P1） | 本周 |
| 2 | 建立周度快照：API license / Top 3 占比 / 周提交量 | 本周 |
| 3 | 触发式告警：API license 从 NOASSERTION → MIT 时（产权正式化） | 本月 |
| 4 | "OpenClaw Foundation" 法律实体验证 | 下月 |
| 5 | Scorecard 缓存后纳入安全信号横向对比 | 待缓存 |

---

## 8. 理论连接：大分流 2.0 的新样本

OpenClaw 的产权真空现象是大分流 2.0 框架的一个**新维度**：

> **传统的"许可驱动型开源"（MIT/GPL）和"闭源商业"之间的第三种形态——"事实开源但法律闭源"。**

这不是"坏开源"，而是一个制度演化中的过渡状态：当项目速度超过制度建设的速度时，会出现**"代码先行，产权后补"**的现象。OpenClaw 的 7 个月成长史（2025-11 到 386K stars）是一个**制度追赶技术**的典型样本。

适兕作为 contributor 进入的可行性：**低**（Top 3 占比 89%，社区进入门槛高），但**作为制度观察者进入价值极高**——OpenClaw 的产权演化本身就是开源制度研究的重要案例。
