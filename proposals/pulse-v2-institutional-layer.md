# Project Pulse v2 — 制度基础设施层扩展方案

> **开源之道** · 2026-08-10
> 分析视角：新制度经济学（Coase / Williamson / North / Ostrom）
> 目标：从代码层信号 → 制度层信号，补全交易成本分析的实证底座

---

## 0. 问题陈述

Project Pulse v1（当前）覆盖 10 个项目（k8s、kernel、ASF、PyTorch、LLVM、Debian、Python、vLLM、SGLang、AAIF），采集信号全部位于**代码层**：GitHub PR/issue、邮件列表 patch、release note、贡献者活跃度。

适兕此前在 issues-musings 中的理论框架（科斯-威廉姆森-诺斯-阿西莫格鲁）需要**制度层信号**做实证支撑。没有制度数据，理论是空中楼阁。

本方案设计 **Pulse v2 — Institutional Infrastructure Layer**：补入基金会治理、产权安排、合规制度、专利政策等维度的信号源，使 Pulse 从"代码脉搏"升级为"制度脉搏"。

---

## 1. 筛选框架：NIE 四轴模型

适兕此前分析中反复出现的理论家可以压缩为**四个分析轴**。每个轴对应一类可观测的信号：

| 轴 | 理论家 | 核心概念 | Pulse 映射信号 |
|----|--------|---------|---------------|
| **产权与资产专用性** | Coase (1937) / Williamson (1985) | 谁来拥有代码？专用性投资由谁承担？ | 基金会章程、代码所有权声明、CLA/DCO 政策 |
| **制度变迁与路径依赖** | North (1990) | 正式规则（章程）如何随时间演化？ | 章程修订记录、治理结构变更、争议解决流程 |
| **公共池塘资源治理** | Ostrom (1990) | 谁有准入权？违规如何制裁？ | 贡献者分级、维护者委员会投票、社区准入标准 |
| **包容性 vs 汲取性制度** | Acemoglu & Robinson (2012) | 治理权集中还是分散？ | 核心维护者占比、fork 事件、治理模式迁移 |

每个待选项目必须能在**至少三个轴**上提供典型样本，才有入选 Pulse v2 的制度分析价值。

---

## 2. 候选项目清单与代表性制度特征

适兕给出的五个例子恰好覆盖了四种不同的制度原型。逐一分析：

### 2.1 FFmpeg — 无基金会的"纯社区治理"原型

**制度特征：**
- 无基金会背书，无公司控股，纯邮件列表驱动
- 决策者（Michael Niedermayer 等）靠资历而非投票产生——典型的**习惯法治理**（Hume/Burke 传统）
- 高资产专用性但无产权集中——Williamson 框架下的极端案例

**NIE 价值：** 观察**没有正式制度**时社区如何维持秩序。Ostrom 八原则的自然实验。

**信号源：** ffmpeg-devel 邮件列表、Git 提交历史、版本发布记录

### 2.2 Homebrew — 治理危机的教科书

**制度特征：**
- 2021 年 "brew.guide 事件" — 创始人与核心维护者分裂，项目 fork
- 从个人魅力型治理（Max Howell 时代）→ 委员会治理 → GitHub Discussions 社区投票
- 典型的**治理失败后重建制度**的案例

**NIE 价值：** North 路径依赖的反例——制度可以突变（governance shock）。分析冲击后的重新纳什均衡。

**信号源：** GitHub Discussions（社区投票）、GitHub Issues（治理争议存档）、维护者变更记录

### 2.3 Python Software Foundation (PSF) — "嵌入式基金会"

**制度特征：**
- 基金会 501(c)(3)，但**日常治理权不在基金会董事会**，而在 Steering Council + 各 SIG
- 基金会管钱（商标、活动），社区管技术——Coase 交易成本的经典降低策略
- PEP 体系 = 正式的制度变迁规则（North 正式约束）

**NIE 价值：** 观察**正式基金会**与**非正式社区规则**如何分工——Williamson 的混合治理（hybrid governance）典型。

**信号源：** PSF 年度财务报告、PEP 提案、Steering Council 会议纪要

### 2.4 Free Software Foundation (FSF) — "意识形态驱动型基金会"

**制度特征：**
- Stallman 个人权威主导 → 委员会民主 → 2019 年 FSF 分裂（FSFE 欧洲独立）
- GPL 许可证诉讼策略 = 产权行使的激进形式
- 2023 年 FSF 重新定位（不再坚持 GPL-only，转向更务实的立场）

**NIE 价值：** North 制度变迁的**意识形态驱动型**案例——当核心理念与现实脱节时，制度如何调整？以及**合法性危机**（legitimacy crisis）如何触发治理重建。

**信号源：** FSF 官方公告、GPL 诉讼档案、LWN.net FSF 专题报道

### 2.5 GNU 工程 — "历史遗产型项目群"

**制度特征：**
- GNU 不是一个项目而是一组项目的集合（GCC、Coreutils、Bash、Emacs、Glibc…）
- 每个子项目有独立维护者，但商标和发布由 FSF 统一管理
- 部分项目（GCC）已事实脱离 FSF 管理（由 Red Hat 主导开发）

**NIE 价值：** 观察**制度衰变**（institutional decay）——当中央权威下降时，各子系统如何自主演化。类比诺斯对"苏联式命令经济效率衰退"的分析。

**信号源：** FSF Savannah（历史存档）、各子项目独立仓库、LWN.net GNU 专题

### 2.6 补充：Apache Software Foundation — "治理制度化最彻底的样本"

适兕此前 Pulse v1 已有 ASF 邮件列表数据，但**监控维度偏窄**（仅 announce + legal-discuss）。建议扩展：

**制度特征：**
- 治理规则写入 ASF 宪法（Charter），有完整的**投票权、提案权、争议解决**制度
- Board + VP + PMC 三层治理，年度 Board 选举
- 2024 年 Kubernetes 申请加入 ASF 被拒事件——制度边界管理的案例

**NIE 价值：** Ostrom 八原则的**制度化版本**——所有治理规则都明文化、可审计。

**信号源：** board 邮件列表、PMC 成员变更、项目毕业/孵化记录

---

## 3. 推荐 Pulse v2 项目矩阵

| 项目 | 制度原型 | NIE 典型性 | 信号可获取性 | 推荐优先级 |
|------|---------|-----------|------------|----------|
| ASF（扩展） | 制度化治理 | ⭐⭐⭐ | 高（已有数据管道） | **P0** |
| Python PSF | 嵌入式基金会 | ⭐⭐⭐ | 高 | **P0** |
| FFmpeg | 纯社区习惯法 | ⭐⭐⭐ | 中 | P1 |
| Homebrew | 治理危机/重建 | ⭐⭐⭐ | 高 | P1 |
| GNU/FSF | 制度衰变 | ⭐⭐ | 中（FSF 网站信息较少） | P2 |
| Debian | 民主治理（已有 v1） | ⭐⭐ | 已有 | 维持 v1 |
| LLVM | 公司主导混合治理 | ⭐⭐ | 已有（kernel inbox） | 维持 v1 |

---

## 4. 各项目的监控信号定义

### 4.1 ASF 扩展信号

```yaml
# pulse/asf/institutional-registry.yaml（新增）
board_list:
  - name: board
    list: board
    domain: apache.org
    description: "ASF Board discussions (governance decisions, project additions)"
    category: governance
    watch_level: high
    status: active

committee_list:
  - name: foundation
    list: foundation
    domain: apache.org
    description: "Foundation operational matters (financial, legal, IP)"
    category: institutional
    watch_level: medium
    status: active

governance_events:
  - name: project-graduation
    source: "https://projects.apache.org/"
    frequency: daily
    description: "Projects moving from Incubator → Top-level (institutional recognition)"
    category: lifecycle
    status: not-yet-cloned

  - name: podling-creation
    source: "https://incubator.apache.org/"
    frequency: daily
    description: "New incubator projects (institutional entry point)"
    category: lifecycle
    status: not-yet-cloned
```

### 4.2 PSF 制度信号

```yaml
# pulse/psf/registry.yaml（新建）
pep_stream:
  - name: new-peps
    source: "https://peps.python.org/pep-0001.html"
    frequency: daily
    description: "New PEP proposals (governance proposals + technical proposals)"
    category: governance
    watch_level: high
    status: not-yet-cloned

  - name: steering-council
    source: "https://github.com/python/steering-council"
    frequency: weekly
    description: "Steering Council meeting minutes (institutional decision log)"
    category: governance
    watch_level: high
    status: not-yet-cloned

financial_reports:
  - name: psf-annual
    source: "https://www.python.org/psf-records/annual-reports/"
    frequency: yearly
    description: "PSF annual financial report (funding sustainability)"
    category: financial
    status: not-yet-cloned
```

### 4.3 FFmpeg 信号

```yaml
# pulse/ffmpeg/registry.yaml（新建）
mailing_lists:
  - name: ffmpeg-devel
    source: "https://ffmpeg.org/pipermail/ffmpeg-devel/"
    frequency: daily
    description: "FFmpeg development mailing list (pure community governance)"
    category: governance
    watch_level: high
    status: not-yet-cloned

version_releases:
  - name: releases
    source: "https://ffmpeg.org/releases.html"
    frequency: weekly
    description: "FFmpeg version releases (release cadence = institutional health signal)"
    category: lifecycle
    status: not-yet-cloned
```

### 4.4 Homebrew 信号

```yaml
# pulse/homebrew/registry.yaml（新建）
github_discussions:
  - name: discuss
    source: "https://github.com/Homebrew/discussions/discussions"
    frequency: daily
    description: "Homebrew community discussions (voting, policy changes)"
    category: governance
    watch_level: high
    status: not-yet-cloned

maintainer_changes:
  - name: maintainers
    source: "https://github.com/Homebrew/brew/graphs/contributors"
    frequency: weekly
    description: "Core maintainer roster changes (governance turnover)"
    category: governance
    watch_level: medium
    status: not-yet-cloned
```

---

## 5. 实施路径

### 阶段一（1 天）：ASF 扩展
- 新增 `board` + `foundation` 邮件列表监控
- 复用现有 ASF 数据管道（al@nominet.org UK-based archive）
- 产出：每周 Board 决议摘要

### 阶段二（2 天）：PSF 制度信号
- 新增 `pulse/psf/` 目录
- 编写 PEP stream 抓取脚本（PEP 0001 index 是 HTML 表，易解析）
- Steering Council 会议纪要通过 GitHub API 拉取

### 阶段三（3 天）：FFmpeg + Homebrew
- FFmpeg 邮件列表归档（纯 HTML → 需编写 parser）
- Homebrew Discussions API 集成（复用现有 github-sync.py retry 逻辑）

### 阶段四（可选）：GNU/FSF
- 优先级较低——信号可获取性差
- 可考虑通过 LWN.net RSS 间接追踪

---

## 6. 分析产出设计

每个制度信号对应适兕的**制度诊断模板**：

```
[Pulse v2 制度信号] <项目> — <事件类型>

【事件】<一句话摘要>
【理论定位】<Coase / Williamson / North / Ostrom / A&R>
【交易成本维度】<资产专用性 / 治理结构 / 路径依赖 / 公共池塘>
【适兕判断】<1-2 句判断句，非描述性>
【信号来源】<链接>
```

示例（虚拟）：

```
[Pulse v2 制度信号] PSF — PEP 提案：Steering Council 选举改革

【事件】PSF Steering Council 提出改革提案，增加 SIG 代表席位
【理论定位】Ostrom（公共池塘资源治理中的代表性原则）
【交易成本维度】治理结构 / 准入权分配
【适兕判断】这不是一次选举改革，而是一次产权重新分配——
  从 Steering Council 集中的"公司型治理"向 SIG 分散的"合伙型治理"过渡。
  Williamson 的混合治理（hybrid governance）在 Python 生态中正发生。
```

---

## 7. 与现有 Pulse v1 的关系

```
Pulse v1 (当前)              Pulse v2 (本方案)
├── k8s (GitHub)             ├── ASF 扩展 (Board/Foundation)
├── kernel (LKML)            ├── PSF (PEP + Steering)
├── ASF (announce)  ──────→  ├── FFmpeg (mailing list)
├── Debian (discourse)       ├── Homebrew (Discussions)
├── Python (discourse)       └── GNU/FSF (间接信号)
├── PyTorch (GitHub)
├── LLVM (kernel inbox)
├── vLLM (GitHub)
└── SGLang (GitHub)
```

**不是替代，是叠加。** v2 在 v1 之上加制度维度，让同一个项目（如 ASF、Debian、Python）同时有代码信号 + 制度信号，做交叉分析。

---

## 8. 适兕判断

> 为什么是这几个项目？不是因为它们技术影响力大，而是因为它们的**制度结构有代表性**。
>
> FFmpeg 代表"没有制度的制度"——习惯法能走多远？
> Homebrew 代表"制度崩溃"——治理失败后如何重建？
> PSF 代表"制度分工"——基金会和社区如何各管一摊？
> FSF/GNU 代表"制度衰变"——意识形态驱动的治理为何逐渐空心化？
> ASF 代表"制度制度化"——所有规则明文化是最高级的治理吗？
>
> 这五个样本合在一起，覆盖了 North 所说的**制度光谱**——从纯粹的非正式规则到最彻底的正式化制度。缺任何一个，我们对"开源制度经济学"的理解都是片面的。

---

*本方案基于新制度经济学框架设计，适兕保留对信号筛选标准的调整权。实施细节（脚本编写、数据管道）由窄廊执行。*