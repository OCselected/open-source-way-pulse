# Project Pulse v2 — OpenSSF Institutional Signal Proposal

> **开源之道** · 2026-08-11
> 分析视角：新制度经济学（Williamson / Ostrom / Acemoglu）
> 信号源验证：2026-08-11 全部通过

---

## 1. 制度定位

OpenSSF（Open Source Security Foundation）是**企业联盟型基金会**——Google、Microsoft、Amazon、IBM、Tenable 等战略成员主导。在 NIE 制度光谱中：

| 维度 | OpenSSF 定位 |
|------|-------------|
| Coase 企业边界 | 安全标准化的"外部治理"——企业间为降低供应链安全风险而组成的制度联盟 |
| Williamson 交易成本 | Scorecard = **第三方认证机制**，将安全合规从双边谈判转为标准化评估 |
| Ostrom 公共池塘资源 | SLSA / Sigstore / Scorecard 定义了"可信安全信号"这一公共资源的准入和制裁 |
| Acemoglu 包容性 | 战略成员（Google/MS/Amazon）vs 社区——**定价权**在企业还是社区？ |

与已有 Pulse 项目的关系：

| 已有项目 | 制度原型 | OpenSSF 独特价值 |
|---------|---------|----------------|
| ASF | 制度化治理 | OpenSSF 是**企业联盟**而非社区驱动 |
| PSF | 嵌入式基金会 | OpenSSF **基金会权力让渡给战略成员** |
| FFmpeg | 纯社区 | OpenSSF 恰恰相反——**公司主导** |
| FSF | 意识形态驱动 | OpenSSF 是**商业驱动** |

**结论：OpenSSF 填上了"企业联盟型基金会"这个制度原型空白。**

---

## 2. 验证信号源（2026-08-11）

| 信号源 | URL | 内容 | 状态 |
|--------|-----|------|------|
| Scorecard API | `api.scorecard.dev/projects/github.com/{owner}/{repo}` | 结构化安全指标（10+ checks） | ✅ 200 |
| Blog RSS | `openssf.org/feed/` | 12 posts，最新 2026-08-06 | ✅ 200 |
| GitHub org | `api.github.com/orgs/ossf/repos` | 30 repos，今日有 push | ✅ 200 |
| Technical Charter | `github.com/ossf/community/CHARTER.md` | 治理规则 | ✅ 200 |

---

## 3. 监控信号矩阵

### 3.1 Scorecard 安全指标（核心信号）

对 Pulse v1 中所有项目运行 Scorecard：

| Check | NIE 含义 | 制度信号 |
|-------|---------|---------|
| `Maintained` | Ostrom 参与持续性 | 项目是否"活着" |
| `Code-Review` | Williamson 治理约束 | 合并门槛 |
| `Branch-Protection` | Williamson 产权保护 | 防篡改 |
| `Dependency-Update-Tool` | Williamson 自动化降低交易成本 | 依赖治理 |
| `Security-Policy` | Williamson 正式规则 | 安全响应制度 |
| `Vulnerabilities` | 制度失败信号 | 安全债务 |

**核心价值：** 第一次能对多个开源项目做**横向制度对比**——这是 Williamson 比较制度分析的实证基础。

### 3.2 Blog/RSS 信号

- OpenSSF newsletter（月度）= 制度动态
- SOSS podcast = 意识形态传播信号
- 政策倡议（Dependency Firewall, Scorecard 立法推动）= North 制度变迁

### 3.3 GitHub 事件流

- Scorecard 自身代码变更 = 标准化规则演化
- `wg-securing-critical-projects` = 关键基础设施治理
- `best-practices-badge` = 社区准入信号

---

## 4. 与 Pulse v1 的交叉分析

Scorecard API 允许对任意 GitHub 项目打分：

```
[Pulse v2 制度信号] Scorecard 横向对比

项目           | 总分 | Code-Review | Branch-Protection | Security-Policy | Vulnerabilities
---------------|------|-------------|-------------------|-----------------|----------------
kubernetes     | 7.6  | 10          | 8                 | 5               | 0

【适兕判断】Kubernetes 7.6 分说明什么？它不是"安全不够"，
而是"企业联盟治理下的制度权衡"——快速迭代与严格保护的张力。
这是 Williamson 的交易成本经典案例：治理越复杂，效率越低。
```

---

## 5. 适兕判断

> OpenSSF 的独特价值不在于它本身有多重要，而在于它提供了一个**可量化的制度比较工具**——Scorecard。
>
> 在此之前，我们对开源项目的制度分析是定性的：读邮件列表、看代码结构、观察治理流程。有了 Scorecard，第一次可以对多个项目做**横向的、可量化的制度对比**。
>
> 这是 Williamson 比较制度分析方法的实证落地——从"描述一个制度"到"比较一组制度"，这是方法论上的跃迁。

---

*方案作者：「开源之道」· 窄廊*
