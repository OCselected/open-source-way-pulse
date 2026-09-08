# Project Pulse v2 — Tokenomics Foundation 信号接入方案

> **开源之道** · 2026-09-06
> 分析视角：新制度经济学（Coase / Williamson / North / Ostrom / Acemoglu & Robinson）
> 目标：AI 经济治理层信号——大分流2.0的第三条路

---

## 0. 问题陈述

Tokenomics Foundation 于 2026-08-04 由 Linux Foundation 正式发布，30 家初始成员（IBM/Oracle/SAP/JPMorganChase/Broadcom/Hitachi/Accenture/BNY 等），定位 AI 经济学的开放标准——token 生产/消费/价值三域。与 FinOps Foundation 联合运营 FOCUS 规范。

当前（2026-09-06）：基金会成立 1 个月，TSC 刚建立，GitHub 仅 3 个仓库（6 stars，0 issues，0 PR），Working Groups 尚未产出公开规范。

**核心判断**：Tokenomics 是**大分流2.0的制度标本**——企业联合体以基金会外壳运作，产出"开放标准"实为成本度量互操作性协议。与"信创"在制度结构上高度同构：都是企业联合体通过行政/基金会外壳实现标准化。区别仅在于信创是代码治理，Tokenomics 是成本治理。

---

## 1. NIE 四轴分析

| 轴 | 理论家 | Tokenomics 映射 | 典型性 |
|----|--------|----------------|--------|
| **产权与资产专用性** | Coase (1937) / Williamson (1985) | 30 家企业共同建立"token 经济学标准"——AI 时代的产权制度创新。谁拥有"成本度量权"？FOCUS 规范是产权行使形式 | ⭐⭐⭐ |
| **制度变迁与路径依赖** | North (1990) | 刚经历"意图宣布"→"章程建立"→"工作组运作"的制度初创期。从 LF 托管到独立标准组织的制度路径正在形成 | ⭐⭐⭐ |
| **公共池塘资源治理** | Ostrom (1990) | FOCUS 规范是开源标准，但"标准"能否产生公共池塘效应？准入权 = 会员制（组织级，非个人级） | ⭐⭐ |
| **包容性 vs 汲取性制度** | Acemoglu & Robinson (2012) | 成员全是 Fortune 500 级企业——是包容性制度还是企业联合体？直接对应大分流2.0"特许工程代码"vs"公地开源" | ⭐⭐⭐⭐ |

---

## 2. 候选信号源清单

### 2.1 GitHub（当前信号密度：极低）

| 仓库 | Stars | 内容 | 信号类型 |
|------|-------|------|---------|
| `Tokenomics-Foundation/foundation` | 1 | 基金会运营文档 | L2 治理 |
| `Tokenomics-Foundation/tsc` | 1 | MEMBERS.md / POLICIES.md / WORKING-GROUPS.md | L2 治理 |
| `Tokenomics-Foundation/tokenomics_mindmap` | 4 | HTML 思维导图 | L1 文档 |

**接入条件**：TSC repo 出现实质内容更新（MEMBERS.md 变更、POLICIES.md 迭代、WORKING-GROUPS.md 新增工作组）。当前 0 PR 0 issues，接入即空跑。

### 2.2 tokeneconomics.com（当前信号密度：中）

| 数据源 | URL | 频率 | 可提取信号 |
|--------|-----|------|-----------|
| 首页项目 | tokeneconomics.com/projects/ | 周度 | 规范发布、Big-T 版本更新 |
| Working Groups | tokeneconomics.com/about/tokenomics-working-groups/ | 月度 | 工作组新增/解散/成员变动 |
| 博客 | substack.com/@tokenomicsfoundation | 低（20 subscribers） | 政策声明、成员公告 |
| Governing Board | tokeneconomics.com/about/governing-board/ | 年度 | 成员变动、章程修订 |
| Membership | tokeneconomics.com/membership/ | 季度 | 新成员加入（组织级） |

### 2.3 活动日历（当前信号密度：中）

| 活动 | 日期 | 地点 | 信号价值 |
|------|------|------|---------|
| Tokenomicon Meta Amsterdam | 2026-09-22~23 | Amsterdam | 首届会议——制度合法性信号 |
| AGNTCon + MCPCon | 2026-10-22~23 | San Jose | 与 AAIF 同场——LF 子基金会生态 |
| Tokenomicon + FinOps X San Diego | 2027-06-07~10 | San Diego | 正式联合运营信号 |

---

## 3. 与现有 Pulse 项目的对比

| 维度 | AAIF（已接入） | Tokenomics（待接入） |
|------|---------------|---------------------|
| GitHub 活跃度 | 4 repos，goose 52K stars | 3 repos，6 stars |
| 协议版本迭代 | MCP spec v0.7+ | 无公开版本 |
| Working Groups | 已有产出 | 刚建立 |
| 制度成熟度 | TSC 运作中 | Governing Board 刚首次集会 |
| 信号密度 | 高（每日可产出 L1/L2/L3） | 极低（当前只能输出"无重大信号"） |
| **接入时机** | 成熟（2026 Q2 已接入） | **过早（2026 Q4 重新评估）** |

---

## 4. 接入路径规划

### 短期（当前 → 2026-09）
- 写入本方案文档
- 记录大分流2.0制度分析判断
- Calendar 设置中期/长期重新评估节点

### 中期（2026-Q4 重新评估）
**触发条件**（任一满足即评估接入）：
1. TSC repo 出现 ≥1 PR + ≥1 合并（制度文档迭代）
2. 首个 Working Group 发布公开规范（Big-T 正式版 / FOCUS token 扩展）
3. Governing Board 新增成员 ≥5 家（制度扩张信号）
4. Tokenomicon Meta Amsterdam 产出会议摘要

**动作**：若触发，编写 `tokenomics/tokenomics-registry.yaml` + `tokenomics/tokenomics-query.sh`，接入 Project Pulse cronjob。

### 长期（2027-Q1 升级 P0）
**触发条件**：Tokenomics 首个规范被 ≥3 家非成员企业采用（制度扩散信号）。此时 Tokenomics 从"企业联合体"升级为"行业基础设施"，需要 P0 级持续监控。

---

## 5. 制度判断（大分流2.0视角）

Tokenomics Foundation 的制度结构（Governing Board + TSC + Working Groups + FinOps 合作）是 ASF 的翻版，但服务对象不是"开源项目治理"而是"AI 成本标准化"。

**与信创的同构性**：
- 信创：企业联合体 + 行政外壳 → 代码标准化
- Tokenomics：企业联合体 + 基金会外壳 → 成本标准化
- 共同点：都不是公共池塘，不是 meritocracy，是**企业间互操作性协议**

**与"真开源"的距离**：
- Linux Foundation 托管 = 中性基础设施
- 但 30 家成员全是买方/卖方利益相关方 = 标准制定权 = 治理权
- 这不同于 Apache（任何组织都可以 TLP 项目，投票权与组织规模无关）

**适兕判断**：Tokenomics 是**大分流2.0的第三条路**——不是"公地开源"（FLOSS），不是"特许工程代码"（AtomGit），不是"赛博庄园"（局域网共享），而是**"企业经济联合体"**。它的制度创新不在于"开源"，在于用基金会外壳标准化企业间的成本语言。这可能是 AI 时代制度经济的原型——不是"谁拥有代码"，而是"谁拥有度量权"。

---

## 6. 与 AAIF 的三方对比

| 维度 | Kernel (lkml) | ASF | AAIF | Tokenomics |
|------|--------------|-----|------|------------|
| 治理结构 | meritocracy（自发） | PMC（委员会） | LF 子基金会 | LF 子基金会 |
| 制度密度 | 低 | 高 | 中 | 高 |
| 准入模式 | 开放 | 开放（TLP） | 组织会员 | 组织会员 |
| 产权归属 | 分散 | ASF 托管 | 捐赠制 | 联合体 |
| NIE 原型 | 习惯法 | 制度化治理 | 企业-基金会混合 | 企业经济联合体 |
| 大分流定位 | 真开源 | 真开源 | 灰色地带 | 企业联合体 |

---

*本方案基于新制度经济学框架设计。接入时机由适兕决定。*
