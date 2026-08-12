# Project Pulse v2 — Hermes Agent Institutional Signal Proposal

> **开源之道** · 2026-08-12
> 分析视角：Coase（产权）/ Williamson（混合治理）/ North（制度变迁）/ Acemoglu（包容性）
> 信号源验证：2026-08-12 全部通过
> 优先级：**P1**（元层监控 + 制度对照）

---

## 1. 制度定位

Hermes Agent 是**自我改进的 AI Agent 项目**——MIT 许可、Python 主导、由 Nous Research 学术团队发起。
在 NIE 制度光谱中，它是一个**包容性制度的典型样本**，同时也暴露了**bus factor = 1**的治理集中风险。

| 维度 | Hermes Agent 定位 |
|------|-----------------|
| Coase 企业边界 | MIT 许可 = 产权边界清晰，与 OpenClaw 的 NOASSERTION 构成极端对照 |
| Williamson 混合治理 | 499 贡献者 / 18,512 commits = 社区协同；Top 5 贡献 83% = 极度集中 |
| Ostrom 公共池塘资源 | 229K stars = 数字公地；但外部 PR 合并率仅 13% = 边界清晰原则部分失效 |
| Acemoglu 包容性 | MIT + 开放贡献 = 包容性制度；bus factor=1 = 汲取性风险 |

与已有 Pulse 项目的关系：

| 已有项目 | 制度原型 | Hermes Agent 独特价值 |
|---------|---------|---------------------|
| ASF | 制度化治理 | Hermes 是**Agent 项目**——治理对象是 agent 本身 |
| PSF | 嵌入式基金会 | Hermes **无基金会**，纯社区 + 商业公司 |
| FFmpeg | 纯社区习惯法 | Hermes 有 **CONTRIBUTING.md** 但无 GOVERNANCE.md = 半制度化 |
| Homebrew | 治理危机/重建 | Hermes **bus factor=1** = 制度衰变早期信号 |

**结论：Hermes Agent 填上了"AI Agent 项目的制度演化"这个监测空白，同时是 Pulse 管线自身的元层监控对象。**

---

## 2. 验证信号源（2026-08-12）

| 信号源 | URL | 内容 | 状态 |
|--------|-----|------|------|
| GitHub 项目 API | `api.github.com/repos/nousresearch/hermes-agent` | 项目元数据 | ✅ 200 |
| README | `raw.githubusercontent.com/.../main/README.md` | 项目定位 | ✅ 200 |
| CONTRIBUTING.md | `raw.githubusercontent.com/.../main/CONTRIBUTING.md` | 贡献指南 | ✅ 200 |
| SECURITY.md | `raw.githubusercontent.com/.../main/SECURITY.md` | 安全响应 | ✅ 200 |
| Commits | `api.github.com/repos/nousresearch/hermes-agent/stats/commit_activity` | 12 周数据 | ✅ 200 |
| Contributors | `api.github.com/repos/nousresearch/hermes-agent/contributors` | 499 人 | ✅ 200 |
| Releases | `api.github.com/repos/nousresearch/hermes-agent/releases` | 10 天/版本 | ✅ 200 |
| Scorecard | `api.scorecard.dev/projects/github.com/nousresearch/hermes-agent` | **404 — 尚未缓存** | ⚠️ PENDING |
| PR 数据 | `api.github.com/repos/nousresearch/hermes-agent/pulls` | 外部 PR 合并率 13% | ✅ 200 |

---

## 3. 监控信号矩阵

### 3.1 治理结构稳定性（核心信号）

| 信号 | 当前值 | 制度含义 | 风险阈值 |
|------|--------|---------|---------|
| bus factor | 1（teknium1 = 50% commits） | Williamson 治理集中度 | Top 1 占比 >60% 时告警 |
| PR 合并率 | 13%（最近 30 个外部 PR） | 社区开放度 | <10% 时告警 |
| Release 频率 | ~10 天/版本 | 迭代节奏 | >20 天间隔时告警 |
| 周提交量 | 4 周均值 1,226 | 活跃度 | 周提交 <200 时告警 |
| 贡献者增长率 | 499 人（年度） | 社区扩张 | 连续 4 周 0 新贡献者时告警 |

### 3.2 制度演化信号

| 信号 | 监测点 | 制度含义 |
|------|-------|---------|
| CODEOWNERS | 是否建立（当前缺失） | Williamson 治理正式化 |
| GOVERNANCE.md | 是否建立（当前缺失） | Ostrom 集体选择安排 |
| CODE_OF_CONDUCT | 是否建立（当前缺失） | 社区规范层 |
| 许可证变更 | MIT → 其他 | Coase 产权边界变化 |
| 基金会成立 | 是否从个人/公司转为基金会 | North 制度变迁 |

### 3.3 与 OpenClaw 的对照信号

Hermes Agent 和 OpenClaw 构成**极端对照样本**：

| 维度 | Hermes Agent | OpenClaw | 制度分析价值 |
|------|-------------|----------|------------|
| License | MIT | NOASSERTION | Coase 产权边界对照 |
| Stars | 229K | 386K | 同样量级下的制度差异 |
| 治理文档 | CONTRIBUTING ✅ / GOVERNANCE ❌ | 待验证 | Williamson 正式化程度 |
| 贡献者 | 499 人 | 待验证 | Ostrom 参与广度 |

---

## 4. 数据源

```
GitHub API（项目元数据）
  → repos/nousresearch/hermes-agent
  → repos/nousresearch/hermes-agent/stats/commit_activity
  → repos/nousresearch/hermes-agent/contributors
  → repos/nousresearch/hermes-agent/pulls
  → repos/nousresearch/hermes-agent/releases
  → repos/nousresearch/hermes-agent/issues
```

**自动化可行性：** 高（全部 GitHub REST API，无需认证基础调用即可）

---

## 5. 推荐策略

| 步骤 | 动作 | 优先级 |
|------|------|--------|
| 1 | 加入 Pulse v2 监测池（P1） | 本周 |
| 2 | 建立周度快照：bus factor / PR 合并率 / 周提交量 | 本周 |
| 3 | 触发式告警：bus factor 变化 / 许可证变更 / 基金会成立 | 本月 |
| 4 | Scorecard 缓存后纳入安全信号横向对比 | 待 Scorecard 缓存 |

---

## 6. 与大分流 2.0 的理论连接

Hermes Agent 的 MIT 许可 + bus factor=1 + 499 贡献者构成了**包容性制度中的集中风险悖论**：

> **法律上是包容性的（MIT），结构上是集中的（bus factor=1）——这正是阿西莫格鲁"包容性制度不等于自动有效"的开源版本。**

适兕成为 contributor 的可行路径：从 **skill 贡献**（SKILL.md 格式，门槛最低）切入，逐步进入核心开发者圈层，降低 bus factor=1 的治理风险。

---

## 7. 备注

- **元层监控：** Hermes Agent 是 Pulse 管线的运行平台本身——它的健康度直接影响所有下游信号源的采集
- **适兕贡献路径：** Python 经验 → skill 贡献（路径 A，最低门槛）→ bug fix（路径 B）→ feature PR（路径 C，最高门槛）
