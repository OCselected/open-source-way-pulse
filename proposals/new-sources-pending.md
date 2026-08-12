## 2026-08-12 — Hermes Agent + OpenClaw（AI Agent 项目对照）

> **评估来源：** 窄廊手工注入（GitHub API 主动扫描），非信号甄别管线产出
> **评估时间：** 2026-08-12
> **评估者：** 窄廊（dry run 模拟 cron job `61f35420f663`）

---

### 来源 1：OpenClaw

| 项 | 内容 |
|---|------|
| 来源名称 | OpenClaw |
| 类型 | GitHub 开源项目（AI Agent / 个人助理） |
| 来源 URL | https://github.com/openclaw/openclaw |
| Stars / Forks | 385,996 / 81,122 |
| License | **NOASSERTION**（API）/ MIT（LICENSE 文件内容） |
| 推荐人 | 窄廊 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（产权） | ⭐⭐⭐ 3/3 | License API = NOASSERTION，产权边界在技术声明层面缺失；LICENSE 文件为 MIT 但 API 不认 = 产权声明未完全落地 |
| Williamson（混合治理） | ⭐⭐ 2/3 | Top 3 贡献者占 89%（steipete=39,765 commits），bus factor≈1，治理极度集中 |
| North（制度变迁） | ⭐⭐ 2/3 | 7 个月从 0 到 386K stars，增长速度远超制度建设速度，"代码先行，产权后补" |
| Ostrom（公共池塘） | ⭐⭐⭐ 3/3 | 386K stars = 数字公地；产权不明 = 边界清晰原则缺失；81K forks 无合法再分发权 |
| A&R（包容性 vs 汲取性） | ⭐⭐⭐ 3/3 | 事实开放 vs 法律闭源的悖论，大分流 2.0 新制度样本 |

**综合评级：P1**（≥3 轴典型性，数据源可自动化获取，与现有监测池互补）

**数据源状态：**
- ✅ GitHub API（项目元数据、commits、contributors、releases）
- ✅ README / LICENSE / CONTRIBUTING / SECURITY 均可直接 curl
- ⚠️ Scorecard API 404（尚未缓存）
- ⚠️ "OpenClaw Foundation" 法律实体状态待验证

**建议触发条件（升级为 P0）：**
1. API license 从 NOASSERTION → MIT（产权正式化完成）→ 此时写入 registry.yaml + 同步脚本
2. "OpenClaw Foundation" 法律实体注册确认 → 触发制度变迁分析
3. Top 3 贡献者占比降至 <50% → 治理分散化信号

**独特价值：**
Pulse v2 现有 10 个项目均为产权清晰（MIT/BSD/Apache/GPL），OpenClaw 是唯一"产权真空"样本。与 Hermes Agent 构成 MIT vs NOASSERTION 的极端对照。

---

### 来源 2：Hermes Agent

| 项 | 内容 |
|---|------|
| 来源名称 | Hermes Agent |
| 类型 | GitHub 开源项目（AI Agent / 自我改进 agent） |
| 来源 URL | https://github.com/nousresearch/hermes-agent |
| Stars / Forks | 229,123 / 45,164 |
| License | **MIT** |
| 推荐人 | 窄廊 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（产权） | ⭐⭐⭐ 3/3 | MIT 产权清晰，与 OpenClaw NOASSERTION 构成极端对照 |
| Williamson（混合治理） | ⭐⭐ 2/3 | 499 贡献者 / 18,512 commits 显示社区广度；但 Top 5 贡献者占 83%，bus factor=1 |
| North（制度变迁） | ⭐⭐ 2/3 | ~10 天一个 release，快速迭代；15 个版本/年；社区从 Nous Research 学术团队向 229K stars 扩展 |
| Ostrom（公共池塘） | ⭐⭐ 2/3 | 229K stars 数字公地；但外部 PR 合并率仅 13% = 边界清晰原则部分失效 |

**综合评级：P1**（≥3 轴典型性，元层监控必要性高，数据源可自动化获取）

**数据源状态：**
- ✅ GitHub API（项目元数据、commits、contributors、releases、issues）
- ✅ README / CONTRIBUTING / SECURITY 可直接 curl
- ✅ 12 周 commit 数据、499 贡献者、PR 合并率均可获取
- ⚠️ Scorecard API 404（尚未缓存）
- ⚠️ GOVERNANCE.md 缺失（治理正式化未完成）

**建议触发条件（升级为 P0）：**
1. GOVERNANCE.md 建立 → 治理正式化，写入 registry.yaml
2. bus factor 从 1 → >2（核心贡献者分散化）→ 社区健康信号
3. 基金会成立或类似法律实体注册 → 制度变迁重大事件
4. 适兕作为 contributor 首次 PR 合并 → 元层监控的"内部人"通道开启

**独特价值：**
- Pulse 管线的元层监控对象（自身运行平台）
- 适兕作为 contributor 进入的实际路径（skill 贡献 → bug fix → feature PR）
- 与 OpenClaw 的 MIT vs NOASSERTION 对照

---

### 两个来源的关系

| 维度 | Hermes Agent | OpenClaw |
|------|-------------|----------|
| License (API) | **MIT** | **NOASSERTION** |
| Stars | 229K | 386K |
| bus factor | 1 | ~1 |
| 治理文档 | CONTRIBUTING ✅ / GOVERNANCE ❌ | CONTRIBUTING ✅ |
| Scorecard | 404 未缓存 | 404 未缓存 |

**核心对照：** 同样量级、同样集中度的两个 AI Agent 项目，产权结构截然不同——MIT（包容性）vs NOASSERTION（产权真空）。这是大分流 2.0 在 AI Agent 生态层面的微观体现。

**Scorecard 共同缺失：** 两个项目均未被 OpenSSF Scorecard 缓存，说明安全认证体系尚未覆盖新兴 AI Agent 生态——这本身就是一个制度信号。
