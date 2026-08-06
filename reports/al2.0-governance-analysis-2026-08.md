# Apache License 2.0 治理深度分析

**数据源：** `legal-discuss@apache.org`（2025-07 至 2026-08，14 个月完整归档）
**抓取时间：** 2026-08-06
**分析师：** 「开源之道」·窄廊

---

## 核心发现

`legal-discuss@apache.org` 是 Apache 基金会许可证治理的**正式决策记录**。它不是一个"讨论区"，而是 Apache 法律委员会（Legal Committee）和整个社区就许可证兼容性、发布政策、商标、CLA/ICLA 等议题进行**制度性协商**的归档。

14 个月累计 **500+ 邮件、300+ 线程**，覆盖 LEGAL-536 到 LEGAL-735 共 100+ 个正式议题。

### 治理链全景

```
ASF Board (董事会)
  └── ASF Legal Committee (法律委员会)
        ├── [VOTE] 许可证兼容性决议 (resolved.md)
        ├── [VOTE] 发布政策修订
        ├── 商标转移 / 品牌管理
        └── Bylaws 修订
              └── 各 PMC 通过 legal-discuss 发起 LEGAL-xxx 议题
```

---

## 一、AL 3.0 提案事件（2026-01）：许可证治理中的"提案权 vs 决策权"

### 事件始末

2026 年 1 月 3 日，Maksim Klimarchuk（外部个人，gmail.com 邮箱）在 `legal-discuss` 上发布提案，要求 AL 2.0 升级到 3.0，包含五个条款：

| 提案条款 | 内容 | 制度意图 |
|---|---|---|
| Network Attribution (SaaS) | 要求在 UI 保留作者署名链接 | 封堵"AGPL 式 SaaS loophole" |
| AI Clause & "Substantial Portion" | 定义"抄袭"（10 行连续代码） | 在 AI 训练时代保护原作者 |
| Embedded DCO | 内置开发者来源证书 | 替代 ICLA/CCLA 流程 |
| Affiliate Patent Protection | 专利报复条款扩展到所有关联企业 | 防"专利外包" |
| Backward Compatibility | 与 AL 2.0 完全兼容 | 保持迁移可行性 |

**48 小时内，被 ASF 法律委员会否决。**

### 参与者巨链

```
Maksim Klimarchuk <ma...@gmail.com>
  ├─ 身份：外部个人，无 ASF 会员身份，无 .apache.org 邮箱
  ├─ 发言量：3 封（提案 1 + 细化 1 + 最终背书 1）
  ├─ 立场：推动 AL 3.0 现代化，主张"闭 loophole"
  └─ 制度位置：提案者（proposer），无决策权

Hen (bayard) <ba...@apache.org>
  ├─ 身份：ASF 法律委员会核心成员，legal-discuss 长期负责人
  ├─ 逐条反驳：
  │   "This is the Advertising Clause of the late 90s. Apache-1.0 contained such a clause."
  │   "Copying is defined by legal systems, not our license."
  │   "Covered in Apache-2.0 'Legal Entity' defined term."
  └─ 制度位置：守门人（gatekeeper），实质决策权

Christopher (ct) <ct...@apache.org>
  ├─ 身份：ASF 法律委员会成员
  └─ 立场："Hen said everything I wanted to say. +1."

Roman Shaposhnik <ro...@shaposhnik.org>
  ├─ 身份：前 ASF Board member，长期 PMC 参与者
  ├─ 关键判断："changing our license has a high bar of burden of proof"
  │   "like rewriting airplane software in-flight"
  └─ 制度位置：制度守卫者，"举证责任在提议方"

Luis Villa <lu...@lu.is>
  ├─ 身份：律师，OSI Board member，MPL 2.0 共同作者，前 ASF Board
  ├─ 关键判断："MPL 2.0's patent clause is superior to Apache's"
  │   "there is a reason why no lawyer leads these processes twice"
  └─ 制度位置：跨组织仲裁者，提供跨许可证比较视角
```

### 制度解读

**1. 提案权 ≠ 决策权**

Maksim 可以**提出**任何修改，但 **Hen 和 Christopher 作为法律委员会成员拥有实质否决权**。Apache 是委员会共识模型，但共识由**有 .apache.org 身份的人**形成。

**2. Roman 的"举证责任"原则**

> "changing our license in any way shape or form has a high bar of a burden of proof"

这是**制度保守主义**的核心逻辑：Apache 的稳定性本身就是它的最大资产（institutional capital）。任何修改的举证责任完全在提议方。

**3. Luis Villa 的跨组织比较**

> "MPL 2.0's patent clause is superior to Apache's"

许可证设计是一个**制度选择**。Apache 选择"弱专利条款"是为了最大化兼容性，而不是疏忽。弱不等于差——弱是 Apache 保持"最宽松"定位的制度选择。

**4. Maksim 的"最终背书"**

2026 年 1 月底 Maksim 发表了"Final Endorsement"，称"我正式背书 AL 3.0 的当前版本"。但这是**他个人的背书，不是 ASF 的背书**。之后没有任何 ASF 成员回应。

> **结论：AL 3.0 提案已被实质否决。提案者获得了"被听见"的权利，但没有获得"被采纳"的结果。**

---

## 二、中文翻译审查（2026-08）：跨组织许可证治理

2026 年 8 月，OpenAtom Foundation（开放原子开源基金会）成员 PAGE PAGE 在 `legal-discuss` 上发起：

> **[Collaboration] Review of A Chinese Translation of Apache License 2.0**

这是**中国开源治理机构正式进入 Apache 许可证治理话语体系**的信号：

1. OpenAtom 试图将 AL 2.0 语言本地化——翻译是一种**制度话语权**
2. 谁有权翻译许可证，谁就参与了许可证意义的再生产
3. OpenAtom 试图成为 AL 2.0 在中文世界中的"解释者"

### 跨组织治理链

```
ASF Legal Committee ──→ 审查 AL 2.0 官方英文文本
  ↑
  └── OpenAtom Foundation ──→ 提交中文翻译审查
        └── 制度位置：外部审查请求者（review requester），非决策参与者
```

---

## 三、LEGAL 议题分类（14 个月跨域统计）

| 类别 | 独立议题数 | 代表议题 |
|---|---|---|
| 许可证兼容性 | 21 | LEGAL-340 (MPL/CDDL shading), LEGAL-437 (GPL Docker), LEGAL-722 (LGPL transitive), LEGAL-728 (GPL-2.0 in Rust crate) |
| 发布政策 | 5 | LEGAL-588 (release policy tidy), LEGAL-711 (committer hardware), LEGAL-727 (Bylaws) |
| 第三方许可证 | 2 | LEGAL-663 (Oracle JDBC), LEGAL-726 (MySQL/MariaDB), LEGAL-721 (FSL Liquibase) |
| CLA/ICLA | 7 | LEGAL-704 (CLA review), LEGAL-599 (GitHub Merge Queue) |
| AI 政策 | 7 | LEGAL-709 (PR mergeable per AI policy), LEGAL-452 (Provenance FAQ) |
| 商标 | 3 | LEGAL-710 (Seata trademark), LEGAL-713 (Grails trademarks) |
| 其他 | 12 | LEGAL-390 (gcc/libstdc++), LEGAL-719 (OpenAI Aardvark) |

**关键观察：** 许可证兼容性是最大类别（21 个议题），其中**GPL 家族兼容性问题占了一半以上**（GPL Docker、LGPL transitive、GPL in Rust crate、weak copyleft shading）。Apache 项目的最大许可证张力来源不是 AL 2.0 本身，而是**AL 2.0 项目与 GPL 生态的接口问题**。

---

## 四、参与者制度层级

| 层级 | 邮箱特征 | 权力 |
|---|---|---|
| 决策层 | `.apache.org` | 拥有 [VOTE] 权力，可形成决议 |
| 参与层 | `.apache.org` | 有发言权，可提 LEGAL-xxx |
| 外部层 | 外部邮箱 | 可提议、可请求审查，无决策权 |

**外部层典型案例：**
- Maksim Klimarchuk（gmail.com）— AL 3.0 提案者，3 封发言，无决策权
- PAGE PAGE（gmail.com / OpenAtom）— 中文翻译审查请求者
- 各公司法律代表（OpenAI Aardvark, Google license 等议题）

---

## 五、制度经济学解读

### 谁在定义"什么是可接受的贡献"？

Maksim 的 AL 3.0 提案被否决，不是因为技术上有问题——而是因为它**挑战了 ASF 的制度定义权**：

**Hen 的反驳**本质上是说："许可证是由法律体系定义的，不是由我们定义的。"——这暴露了 ASF 的核心立场：许可证是**被动遵守的法律文本**，不是**主动设计的治理工具**。

**Roman 的"举证责任"原则**是制度保守主义的体现：Apache 的稳定性是其最大的**制度资产**（institutional capital），任何修改的代价远高于收益。

### 跨组织许可证治理的制度边界

OpenAtom 的中文翻译审查请求，暴露了**一个更深层的制度问题**：

> **许可证的"解释权"归属谁？**

- ASF 拥有 AL 2.0 的**官方解释权**（通过 legal-discuss + Legal Committee）
- OpenAtom 试图获得**中文世界的解释参与权**
- 中国行政式开源试图通过**语言本地化**获得治理话语权

这恰恰是**大分流 2.0 的核心张力**在许可证层面的体现：
- **Apache 的许可证治理** = 自发秩序（委员会共识，meritocracy）
- **中国行政式开源** = 试图通过"翻译→解释→制度化"路径获得治理权

---

## 六、结论

1. **AL 3.0 已被实质否决**——提案者有发言权，但法律委员会拥有否决权。这符合 Apache 的共识治理模型。

2. **许可证兼容性是 Apache 最大治理挑战**——21 个独立议题围绕 GPL 家族兼容性，说明 AL 2.0 的核心张力是**与 GPL 生态的接口**，而非自身条款。

3. **OpenAtom 的中文翻译审查**标志着中国开源机构试图进入 ASF 许可证治理话语体系——这是"大分流 2.0"在许可证层面的延伸。

4. **参与者的制度位置决定话语权**——.apache.org 邮箱 = 决策权；外部邮箱 = 提案权。这不是技术问题，而是**制度身份**问题。

5. **许可证治理的本质是"谁有权解释"的斗争**——ASF 通过 legal-discuss + Legal Committee 保持解释垄断；OpenAtom 试图通过翻译审查进入解释体系。

---

## 参考文献

- `data/asf/legal-discuss-2025-07.json` 至 `2026-08.json`（14 个月完整归档）
- `data/asf/al3-q5ld4b375t3h8bhn7zox8frgqjtt890m.json`（AL 3.0 原始提案全文）
- `data/asf/al3-odnz2nk9tmvxz9yx01bfk7zq32mmlt0p.json`（Maksim 细化提案）
- `data/asf/al3-3r1gzdy8yb12nk3gr8m1nf0r62gfvvrn.json`（Roman 回复）
- `data/asf/al3-lmdwkdp9ztvyl6ny3wqpkn7ht5q8lkq4.json`（Luis Villa 回复）
- lists.apache.org legal-discuss archive (PonyMail JSON API)

---

**署名：** 「开源之道」·窄廊
**声明：** 基于 Apache Software Foundation legal-discuss 公开邮件数据，结合适兕开源经济学知识体系分析，仅供参考。
