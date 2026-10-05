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

---

## 2026-08-18 — 新来源评估（信号甄别管线产出，2026-08-13 ~ 2026-08-16 队列）

> **评估来源：** 信号甄别与深度审查（`fd423d85a206`）每日追加的磁盘消息队列
> **评估时间：** 2026-08-18
> **评估者：** 窄廊（cron job `新来源评估与注册`）

---

### 来源 1：Linux Foundation Open Secure AI Alliance (OSAA)

| 项 | 内容 |
|---|------|
| 来源名称 | Open Secure AI Alliance (OSAA) |
| 类型 | 联盟/基金会（LF 子基金会） |
| 来源 URL | https://www.linuxfoundation.org/blog |
| 推荐理由 | 2026-06 成立，37 家成员（NVIDIA/Microsoft/GitHub/Google/Amazon/Anthropic 等），发布 SAFE 工作组 RFC——AI 安全事件自愿披露框架 |
| 推荐日期 | 2026-08-13 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（企业边界） | ⭐⭐⭐ 3/3 | 37 家企业共建新联盟 = 企业边界的制度性扩展，SAFE 工作组将 AI 安全事件从企业内控转为联盟互认 |
| Williamson（混合治理） | ⭐⭐⭐ 3/3 | 37 成员涵盖云/芯片/监管/安全——混合治理结构，非市场非科层 |
| North（制度变迁） | ⭐⭐⭐ 3/3 | LF 2026 下半年密集推出 OSAA + Tokenomics = LF 自身从"开源基础设施托管"向"AI 治理基础设施"的战略漂移 |
| Ostrom（公共池塘） | ⭐⭐⭐ 3/3 | AI 安全信息披露 = 数字公地治理问题；自愿披露框架 = 自组织制度尝试 |
| A&R（包容性 vs 汲取性） | ⭐⭐ 2/3 | 37 家企业成员 vs 无社区/个人代表——包容性边界取决于标准化是否开放 |

**综合评级：P1**（≥3 轴典型性，但非独立数据源——OSAA 无独立网站，门户页面 JS 渲染 404，需通过 LF 博客 RSS 追踪）

**数据源状态：**
- ❌ `https://www.linuxfoundation.org/press/open-secure-ai-alliance/` → HTTP 404（HubSpot JS 渲染页面）
- ❌ `osaa.io` / `opensourcealliance.org` → 均不存在/不可访问
- ✅ LF 博客 RSS 可获取（`https://www.linuxfoundation.org/blog/rss.xml`）→ 覆盖 LF 旗下所有子基金会动态
- ✅ LF GitHub 组织：62 个公开仓库，可追踪事件

**建议触发条件（升级为 P0）：**
1. OSAA 独立网站上线（静态可抓取）
2. OSAA 首个 GitHub 组织仓库创建
3. SAFE 工作组 RFC 进入标准化流程

**独特价值：**
LF 2026 下半年双基金会（OSAA + Tokenomics）的密集推出，本身就是 North 意义上的制度变迁信号——LF 正在从"项目托管"向"治理基础设施输出"演化。但当前不宜建独立监控管线，信号强度通过 LF 博客 RSS 即可覆盖。

---

### 来源 2：Linux Foundation Tokenomics Foundation

| 项 | 内容 |
|---|------|
| 来源名称 | Tokenomics Foundation |
| 类型 | 基金会/标准组织（LF 子基金会） |
| 来源 URL | https://www.linuxfoundation.org/projects/tokenomics-foundation |
| 推荐理由 | 2026-08-04 成立，29→30 家创始成员（含 JPMorgan/IBM/Accenture/PointFive/Yarken），AI token 计量标准化，金融机构主导的开源治理标准新样本 |
| 推荐日期 | 2026-08-13 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（企业边界） | ⭐⭐⭐ 3/3 | AI token 计量标准化 = 交易成本边界重新划定——谁定义计量单位，谁定义交易成本 |
| Williamson（混合治理） | ⭐⭐⭐ 3/3 | 金融机构（JPMorgan/Accenture）主导开源标准=市场治理与科层治理的新混合形态 |
| North（制度变迁） | ⭐⭐⭐ 3/3 | 开源基金会设立"token 计量标准" = 制度变迁的典型案例——开源从代码协作进入经济计量域 |
| Ostrom（公共池塘） | ⭐⭐ 2/3 | 标准化作为公共品，但金融机构主导可能引入排他性 |
| A&R（包容性 vs 汲取性） | ⭐⭐ 2/3 | 标准化是否付费/免费 = 包容性 vs 汲取性的分水岭 |

**综合评级：P1**（≥3 轴典型性，但同 OSAA——非独立数据源，需通过 LF 博客 RSS 追踪）

**数据源状态：**
- ❌ 门户页面 JS 渲染 404
- ✅ LF 博客 RSS 可覆盖（`https://www.linuxfoundation.org/blog/rss.xml`）
- ✅ LF GitHub 组织事件可追踪

**建议触发条件（升级为 P0）：**
1. Tokenomics Foundation 独立网站/规范文档上线
2. 首个标准化草案发布（GitHub repo 或 RFC）
3. 标准化认证/收费模式明确（A&R 漂移判断）

**独特价值：**
AI token 计量标准化的本质是"谁定义 AI 的使用成本"——这是开源从"免费协作"向"计价协作"的制度跃迁。与 OSAA 构成 LF 2026 双基金会信号。

---

### 来源 3：TAIONE Open Source Foundation（台湾开源基金会）

| 项 | 内容 |
|---|------|
| 来源名称 | TAIONE Open Source Foundation |
| 类型 | 基金会（区域性开源基金会） |
| 来源 URL | https://taione.org/（*注：队列文件中的 `taiwane.org` 为 DNS 不存在的域名，经搜索确认为 `taione.org`） |
| 推荐理由 | 2026-07-30 成立，$9.3M 启动资金，台湾 50 指数硬件集团资助，以 vLLM 生态建设为核心，嵌入式 LLM 合作 |
| 推荐日期 | 2026-08-15 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（企业边界） | ⭐⭐ 2/3 | 台湾硬件集团跨企业共建开源基金会 = 企业边界向区域公地延伸 |
| Williamson（混合治理） | ⭐⭐ 2/3 | 企业资助 + 社区运营的混合形态，但治理细节尚不透明 |
| North（制度变迁） | ⭐⭐⭐ 3/3 | 台湾首个以 vLLM 为核心的开源推理基金会 = 区域性开源治理的制度创新 |
| Ostrom（公共池塘） | ⭐⭐ 2/3 | 开源推理基础设施作为区域性公共品 |
| A&R（包容性 vs 汲取性） | ⭐⭐⭐ 3/3 | 区域性开源治理新信号——硬件巨头从"制造芯片"转向"建设开源基础设施" |

**综合评级：P1**（2-3 轴典型性，数据源可获取，区域性制度信号独特）

**数据源状态：**
- ✅ `https://taione.org/` → HTTP 200（SPA，JS 渲染首页）
- ⚠️ 首页为 Vue/React SPA，curl 仅获取模板骨架
- ⚠️ RSS 未发现
- ✅ 新闻覆盖（TechTimes、Manila Times 等均有报道）

**建议触发条件（升级为 P0）：**
1. TAIONE 发布静态内容（博客/新闻/活动页面）
2. GitHub 组织创建并公开仓库
3. vLLM 台湾社区活动常态化（每月 1 次以上）

**独特价值：**
TAIONE 是"大分流 2.0"在东亚的微观体现——硬件制造巨头（非软件公司）主导建设开源基金会，路径与西方（软件公司/基金会主导）截然不同。这是大分流 2.0 的"本土化选择"信号的实证案例。

---

### 来源 4：news.apache.org（ASF 官方新闻）

| 项 | 内容 |
|---|------|
| 来源名称 | news.apache.org — The ASF Blog |
| 类型 | 基金会新闻（WordPress） |
| 来源 URL | https://news.apache.org |
| 推荐理由 | 比 GlobeNewswire 转载更准确，适合监控 TLP 晋升与 ASF 治理动态 |
| 推荐日期 | 2026-08-16 |

**NIE 四轴评估：**

| 轴 | 评分 | 判断 |
|----|------|------|
| Coase（企业边界） | ⭐ 1/3 | 新闻源，不直接涉及企业边界 |
| Williamson（混合治理） | ⭐⭐ 2/3 | 官方新闻发布治理动态（TLP 晋升、Board 决议） |
| North（制度变迁） | ⭐⭐⭐ 3/3 | TLP 晋升、Project 毕业 = 制度变迁的直接记录 |
| Ostrom（公共池塘） | ⭐ 1/3 | 新闻本身不构成公共池塘资源 |
| A&R（包容性 vs 汲取性） | ⭐⭐ 2/3 | 新闻发布本身透明 = 包容性制度信号 |

**综合评级：P1**（2 轴典型 + 与现有 ASF 邮件列表监控互补，数据源可自动化获取）

**数据源状态：**
- ✅ `https://news.apache.org/` → HTTP 200（WordPress 站点）
- ✅ `https://news.apache.org/wp-json/wp/v2/posts` → WP REST API 200
- ⚠️ `https://news.apache.org/feed/` → HTTP 429（rate limit）
- ✅ WP REST API 可作为替代数据源

**建议触发条件（升级为 P0）：**
1. 与现有 ASF 邮件列表监控整合为统一 ASF 监控模块
2. 定制 WP REST API 增量同步脚本稳定运行 2 周

**独特价值：**
填补 ASF 监控的"官方叙事"空白——现有 ASF 监控覆盖邮件列表（治理过程）和 GitHub（代码），缺官方新闻（治理结果公告）。TLP 晋升、Board 变更等制度变迁事件通过官方新闻确认比邮件列表推测更可靠。

---

### 来源 5-8：P2 来源（记录备案）

> 以下来源在 NIE 四轴上典型性 ≤ 2 轴，或/且数据源不适合自动化监控，仅记录备案。

#### 来源 5：The Jamestown Foundation

| 项 | 内容 |
|---|------|
| 来源名称 | The Jamestown Foundation |
| 类型 | 智库/研究 |
| 来源 URL | https://jamestown.org |
| 推荐理由 | 专注中美 AI 地缘政治与开源政策分析 |
| 评级 | **P2** |
| NIE 典型性 | 1-2 轴（North 2 / A&R 2）——地缘政治分析间接反映制度环境变迁，但非直接开源治理信号 |
| 数据源状态 | 未测试（已有监测池已有足够 AI 政策源） |
| 建议触发条件 | 当 Jamestown 产出专门针对开源制度的分析文章时，可升级为 P1 |

#### 来源 6：Centre for International Governance Innovation (CIGI)

| 项 | 内容 |
|---|------|
| 来源名称 | Centre for International Governance Innovation (CIGI) |
| 类型 | 智库 |
| 来源 URL | https://cigionline.org |
| 推荐理由 | 专注 AI 治理与国际制度设计 |
| 评级 | **P2** |
| NIE 典型性 | 1-2 轴（North 2 / A&R 2）——AI 治理制度设计间接相关，但非开源治理专门 |
| 数据源状态 | 未测试 |
| 建议触发条件 | 当 CIGI 产出专门针对开源或公地治理的出版物时 |

#### 来源 7：Lawfare

| 项 | 内容 |
|---|------|
| 来源名称 | Lawfare |
| 类型 | 智库/媒体 |
| 来源 URL | https://lawfaremedia.org |
| 推荐理由 | "Knives Are Out for Open-Weight AI Models" 一文直接讨论开源定义权 |
| 评级 | **P2** |
| NIE 典型性 | 1-2 轴（A&R 3）——开源定义权讨论为 A&R 包容性/汲取性提供制度分析素材，但来源本身非持续开源治理源 |
| 数据源状态 | 未测试 |
| 建议触发条件 | 当 Lawfare 开设开源治理专栏或持续产出相关文章时 |

#### 来源 8：ICML Technical AI Governance Research Workshop

| 项 | 内容 |
|---|------|
| 来源名称 | ICML Technical AI Governance Research Workshop |
| 类型 | 学术会议 |
| 来源 URL | ICML 2026 (AI Governance Workshop track) |
| 推荐理由 | AI 治理研究的前沿会议，多篇论文引用（如 Sidhu 2026 AI Incident Governance） |
| 评级 | **P2** |
| NIE 典型性 | 1-2 轴（North 2 / Ostrom 2）——学术会议产出制度研究，但非持续数据源，年度会议节奏 |
| 数据源状态 | 年度会议，非数据管线 |
| 建议触发条件 | 下一届 ICML 2027 CFP 发布时，手动评估是否纳入论文监控管线 |

---

### 排除来源

| 来源 | 原因 |
|------|------|
| OpenSSF (openssf.org) | ✅ 已在监测池中（`openssf/registry.yaml`，含 RSS + Scorecard API + Charter + GitHub 事件） |
| OpenChain (openchainproject.org) | ⏸️ 上游标注"待人工确认"，未正式加入队列，跳过 |
| 2026-08-17 队列 | ⏭️ "无新来源发现" |
| 2026-08-18 队列 | ⏭️ "无新来源发现" |

---

### 值得追踪的制度信号（非数据源，关联至 LF 博客 RSS）

OSAA 和 Tokenomics Foundation 虽未独立建管线，但以下信号值得通过 LF 博客 RSS 持续追踪：

1. **LF 2026 下半年双基金会密集推出**——LF 从"项目托管"向"治理基础设施输出"的战略漂移（North 制度变迁）
2. **AI token 计量标准化**——开源从"免费协作"向"计价协作"跃迁（Coase 交易成本边界）
3. **SAFE 工作组 RFC 落地**——AI 安全事件披露从自愿→强制→制度化的路径（Ostrom 公共池治理）
4. **TAIONE 的东亚路径**——硬件制造巨头主导的基金会 vs 西方软件公司主导（大分流 2.0 实证）

---

## 2026-08-25 — 新来源评估（信号甄别管线产出，2026-08-19 ~ 2026-08-25 队列）

> **评估来源：** 信号甄别与深度审查（`fd423d85a206`）每日追加的磁盘消息队列
> **评估时间：** 2026-08-25
> **评估者：** 窄廊（cron job `新来源评估与注册`）
> **本次 P0 落地：** `mojo/` + `omarchy/` 两模块（见仓库 registry）

---

### P1（观察期）

## 2026-08-21 — Infosecurity Magazine
- 评级：P1
- 来源类型：安全行业新闻（RSS：https://www.infosecurity-magazine.com/rss/news/ 验证 200）
- NIE 典型性分析：North 2（Linux Foundation Akrites 项目 2026-09 上线独家报道 = 制度变迁实况记录）/ Ostrom 2（关键开源软件漏洞协调 = 公地安全外部性内部化的集体行动）/ Williamson 2（19 家企业联合协调机制 = 混合治理新闻）。2-3 轴典型。
- 数据源状态：✅ RSS 可用（rss/news/），每日增量可自动化
- 建议触发条件：Akrites 2026-09 上线后，若 Infosecurity 形成系统性覆盖（≥2 篇/月），升级 P0 建独立管线；否则由 OpenSSF 模块 + 手动信号追踪覆盖

## 2026-08-25 — transparencycoalition.ai（Transparency Coalition）
- 评级：P1
- 来源类型：行业联盟/倡导组织（Squarespace 站点，含 /news/ 栏目）
- NIE 典型性分析：A&R 2-3（1300+ 科技员工联署 AI 安全监管公开信 = 治理需求侧"员工-管理层-监管"三角压力的一手信号）/ North 2（AI 立法动态持续记录，2026-08-21 立法更新可达）。~2 轴典型，开源关联间接（AI 安全监管影响开源模型分发边界）。
- 数据源状态：✅ 静态页可抓取（含 dated news 文章，如 California AI bills scorecard）；无 RSS
- 建议触发条件：若产出直接涉及开源/开放权重模型监管的政策分析，或 news 更新频率 ≥4 篇/月，升级 P0

---

### P2（记录备案）

## 2026-08-19 — SSRN (Social Science Research Network)
- 评级：P2
- 来源类型：学术预印本平台（社会科学）
- NIE 典型性分析：North 2 / Ostrom 2——法律+经济+政治交叉的开源治理文献前沿（Choi/Viseur/Atkinson 均引），但为文献仓库非制度事件源；arXiv 已有覆盖策略
- 数据源状态：❌ HTTPS 403（Cloudflare bot 防护），无公开 API
- 建议触发条件：SSRN 开放 API/导出接口，或出现需要系统性追踪的治理文献序列时，转由论文监控管线手动收录

## 2026-08-20 — Just Security
- 评级：P2
- 来源类型：智库博客（美国安全与 AI 政策）
- NIE 典型性分析：A&R 2 / North 2——Remler 2026-08-17 文章完成 CEPA/MacCarthy/Remler 三方政策框架串联，但为政策分析类，同 Jamestown/CIGI/Lawfare 先例
- 数据源状态：✅ 可访问（200），但文章节奏低、非开源治理专门
- 建议触发条件：开设开源治理专栏或产出针对开源制度本身的系列分析

## 2026-08-20 — Nikkei Asia
- 评级：P2
- 来源类型：财经媒体（亚洲视角）
- NIE 典型性分析：A&R 2 / North 1——中美开源 AI 博弈的"非西方视角"报道有独特价值，但多数内容付费墙，非结构化数据
- 数据源状态：⚠️ 首页 200，正文大量订阅墙
- 建议触发条件：如出现可免费获取的开源治理专题系列，按事件手动收录

## 2026-08-20 — Cloud Wars (cloudwars.com)
- 评级：P2
- 来源类型：行业博客/分析师评论
- NIE 典型性分析：Coase 2 / A&R 2——"AI 巨头如何保护开源"的商业视角分析，但更新稀疏、分析师观点为主
- 数据源状态：✅ 可访问（200），无稳定 RSS
- 建议触发条件：形成系统性"企业开源战略"专栏时升级为 P1

## 2026-08-24 — dealroom.co
- 评级：P2
- 来源类型：创投资讯/融资数据库
- NIE 典型性分析：Coase 2——"防御性贡献"、"关系专用性投资"投融资信号（如 Anthropic $35M 开源安全基金首日捕获），但为交易数据平台非制度事件源
- 数据源状态：⚠️ 首页 200，核心数据需注册/付费，JS 渲染重
- 建议触发条件：Anthropic 类防御性资助事件需要系统追踪时，手动查询并归档快照

## 2026-08-25 — freefable.org
- 评级：P2
- 来源类型：开放信（一次性文档）
- NIE 典型性分析：A&R 3——出口管制取消诉求 = AI 模型跨境流动的制度边界信号，直接对话美国政府对 Anthropic Fable 的管制；但为一封公开信，非持续数据源
- 数据源状态：✅ 静态页 200；签名人名单可一次性快照存档
- 建议触发条件：建议 2026-08 内手动快照签名人名单入 wiki 信号存档；后续若发展成常设组织再评估

---

### 排除来源（2026-08-19 ~ 2026-08-25）

| 来源 | 原因 |
|------|------|
| news.apache.org（08-20 建议） | 🔁 已在 2026-08-18 评估为 P1（本文件上文），不重复落地 |
| ICML Technical AI Governance Workshop（08-21 建议） | 🔁 已在 2026-08-18 评估为 P2（本文件上文），不重复落地 |
| 2026-08-22 队列 | ⏭️ "无新来源发现" |
| 2026-08-23 队列 | ⏭️ "无新来源发现"（DeepXiv 为 API 工具非制度来源等均去重跳过） |

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **Mojo 半开源概念**（modular 模块承载）——"发布权开放、合并权保留"为产权释放与治理开放的分层实验，wiki 建议开发 standalone concept note（已提示适兕评估）
2. **Omacom Foundation $8M→$10M 资金轨迹**（omarchy 模块承载）——基金会化集体行动 + 公共品赞助决策（Hyprland/Quickshell）序列
3. **Akrites 2026-09 上线**——"基金会化集体行动（多边协调）vs Anthropic $35M 单边资助"治理路线对比进入实弹阶段，调度权稀缺化 = Ostrom 公地治理操作化前沿
4. **Anthropic 防御性资助的项目选择逻辑**——选"依赖度最高"还是"风险最大"项目，选择本身即治理信号
5. **vLLM v0.27 对 Kimi K3 全栈支持**——单一企业依赖（single-vendor）风险，K3 kernel 维护者来源待跟踪

---

## 2026-09-01 — 新来源评估（信号甄别管线产出，2026-08-26 ~ 2026-08-31 队列）

> **评估来源：** 信号甄别与深度审查（`fd423d85a206`）每日追加的磁盘消息队列
> **评估时间：** 2026-09-01
> **评估者：** 窄廊（cron job `新来源评估与注册`）
> **本次 P0 落地：** 无（无 ≥3 轴典型 + 数据源稳定的候选）
> **主题主线：** 开源-AI 边界之争（AI 贡献政策分裂）——Codeberg/Sourcehut 平台级入 P1 观察期；个人级调研源入 P2

---

### P1（观察期）

## 2026-08-31 — Codeberg Blog
- 评级：P1
- 来源类型：平台博客（非营利公地平台）
- NIE 典型性分析：Ostrom 3（公地平台治理规则制定权——"AI 贡献禁令"是公共池塘准入规则的直接变更）/ North 2-3（平台 AI 政策立场变迁实况记录，与 Debian vote 002、120 项目调研构成"贡献定义权"制度实验观测面）/ Williamson 2（平台-贡献者混合治理规则）/ A&R 2（"AI 生成内容算不算贡献"= 包容性边界重新界定）。2-4 轴典型，开源-AI 边界主题在当前监测池为空白。
- 数据源状态：✅ `https://blog.codeberg.org/` 200；Atom feed `https://blog.codeberg.org/feeds/all.atom.xml` 200（首页 link 提取，非标准 /feed.xml 路径）。已登记 monitored-sources.md #16（✅ 待确认）——本轮评估确认入观察期。
- 建议触发条件：与 Sourcehut 合并建立「开源-AI 边界」主题模块（单一 pipeline 抓双 feed）；AI 政策事件密度 ≥2 篇/月且持续 2 个月，升级 P0 建独立管线；Debian vote 002 结果公布时手动归档事件快照。

## 2026-08-31 — Sourcehut Blog
- 评级：P1
- 来源类型：平台博客（邮件列表驱动开发模式的公地平台）
- NIE 典型性分析：Ostrom 3（ToS 与 AI 政策 = 公地平台准入规则）/ North 2-3（平台治理规则变迁记录）/ Williamson 2（混合治理实证）/ A&R 2（AI 拒绝派立场 = 贡献定义权制度实验）。与 Codeberg 同构，构成"AI 拒绝派"平台光谱的两端样本。
- 数据源状态：✅ `https://sourcehut.org/blog/` 200；RSS `https://sourcehut.org/blog/index.xml` 200。已登记 monitored-sources.md #17（✅ 待确认）——本轮评估确认入观察期。
- 建议触发条件：与 Codeberg 合并主题模块观察；更新频率稳定（≥1 篇/月）持续 2 个月可评估升级 P0。

---

### P2（记录备案）

## 2026-08-26/27/28 — morgin.ai（三次推荐去重合并为一条）
- 评级：P2
- 来源类型：独立安全研究博客（个人）
- NIE 典型性分析：A&R 3（"开源=透明=可审计"在 AI 时代的信任危机——LoRA 时间释放后门实证 87.5% 触发率 = 汲取性行为的隐蔽形态）/ Ostrom 2（开源模型公地信任治理真空，OpenSSF/SLSA 未覆盖"行为可验证性"攻击面）。≤2 轴典型。
- 数据源状态：✅ `https://morgin.ai/` 200；单一作者、无 RSS 证据、更新频率未知，HN 62 pts 为单次事件。
- 建议触发条件：形成系列研究（≥3 篇/季度）并稳定更新时升级 P1；时间释放后门主题建议一次性快照入库 wiki 信号存档。

## 2026-08-27 — SecurityWeek
- 评级：P2
- 来源类型：科技安全新闻（商业媒体）
- NIE 典型性分析：North 2（LF TRACE 标准首发报道方 = 制度变迁实况记录）/ Williamson 2（AI 基础设施安全治理交叉报道）。与 Infosecurity Magazine（已 P1 观察）同类重叠，OpenSSF 模块已覆盖安全标准化主题。
- 数据源状态：✅ `https://www.securityweek.com/` 200。
- 建议触发条件：TRACE 类 AI 治理标准报道形成 ≥2 篇/月系列，或出现现有池未覆盖的制度事件独家报道。

## 2026-08-27 — The Register · Legal
- 评级：P2
- 来源类型：综合科技新闻（法律栏目）
- NIE 典型性分析：Williamson 3（Nitter 关停 = L1 嵌入性极端案例——开源项目的存续不是代码问题而是平台政治问题）/ North 2（平台法律权力 vs 开源镜像服务的制度冲突记录）。教科书级案例，但来源为综合媒体栏目、非开源专门。
- 数据源状态：✅ `https://www.theregister.com/` 200；栏目级过滤成本高。
- 建议触发条件：平台-开源法律冲突成为常态事件流（≥1 例/月）时手动跟踪；Nitter fork 分流（Invidious 模式）建议事件级跟踪而非来源级监测。

## 2026-08-28 — SandboxAQ
- 评级：P2
- 来源类型：商业开源公司（官网博客）
- NIE 典型性分析：Coase 2-3（"开源作为获客通道"= 企业边界与开源战略的商业模式标本）/ Williamson 2（市场获取 vs 开源获取的混合）。与 Spliit"开源获捐"构成资金流方向对照，但为单一公司案例、营销属性浓。
- 数据源状态：✅ `https://www.sandboxaq.com/` 200。
- 建议触发条件：Switch 项目形成治理事件序列（许可变更/基金会化/治理争议）时按事件收录；商业模式标本价值建议一次性写入 wiki。

## 2026-08-30 — experientiallabs.github.io（open OpenRouter 替代品）
- 评级：P2（概念上 P1：Coase 3 去中介化 + Ostrom 2 公地替代，但**数据源当前不可得**，按规则降级）
- 来源类型：开源项目（GitHub Pages）
- NIE 典型性分析：Coase 3（开源替代平台抽成 = 平台中介层被公地替代的制度实验）/ Ostrom 2（公共基础设施取代商业平台）。
- 数据源状态：❌ `https://experientiallabs.github.io/` → 404；GitHub API search "experientiallabs" → 0 结果（org/user 不存在）。
- 建议触发条件：项目实际落地（可访问站点 / GitHub 仓库存在）时重新评估。

## 2026-08-30 — usesesame.app
- 评级：P2
- 来源类型：个人项目（本地优先密码管理器）
- NIE 典型性分析：Ostrom 2（"个人数据主权"开源范式案例）。规模小、个人开发者、非持续来源。
- 数据源状态：✅ `https://usesesame.app/` 200。
- 建议触发条件：项目规模化（社区 > 百人）或出现治理文档（GOVERNANCE/行为准则）时重新评估。

## 2026-08-31 — optimizedbyotto.com
- 评级：P2
- 来源类型：个人博客
- NIE 典型性分析：North 2 / A&R 2（why-open-source-projects-ban-ai 综述为"AI 拒绝派"运动的深度分析）。一次性深度文章，可信度待观察。
- 数据源状态：✅ `https://optimizedbyotto.com/post/why-open-source-projects-ban-ai/` 200（该文建议一次性快照入 wiki）。
- 建议触发条件：持续产出（≥1 篇/月）开源-AI 治理分析时升级 P1。

## 2026-08-31 — medium.com/@yadavrakshit60
- 评级：P2
- 来源类型：个人博客（Medium 账号）
- NIE 典型性分析：A&R 2（120 个开源项目 AI 政策调研一手来源——1/3"AI 拒绝派"= 贡献定义权制度实验的数据基底）。个人账号、非持续源。
- 数据源状态：⚠️ Medium 可访问，内容质量参差；调研数据建议一次性提取存档。
- 建议触发条件：作者转向独立域名或机构化发表时升级；120 项目调研数据建议手动快照入 wiki。

---

### 排除来源（2026-08-26 ~ 2026-08-31）

| 来源 | 原因 |
|------|------|
| news.apache.org（08-30 建议） | 🔁 已在 2026-08-18 评估为 P1（本文件上文），不重复落地；monitored-sources.md #14 ✅ 待确认状态继续保留 |
| dealroom.co（08-26/28 建议） | 🔁 已在 2026-08-24 评估为 P2（本文件上文），不重复落地 |
| morgin.ai（08-27/28 重复） | 🔁 同源重复推荐，并入 08-26 单条评估 |
| iggy.apache.org（08-30） | ⏭️ 一次性事件（TLP 晋升），上游标注不建议加入监控 |
| sourcelume.apache.org（08-30） | ⏭️ 一次性事件（TLP 晋升），上游标注不建议加入监控 |
| docs.kernel.org coding-assistants（08-31） | ⏭️ 单页文档，非持续来源，上游标注不建议加入监测 |
| 2026-08-29 队列 | ⏭️ 上游日报生成失败（90s API 超时），无来源可甄别 |

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **开源-AI 边界之争制度化**（08-31 主线）——Codeberg/Sourcehut 平台禁令 + Debian vote 002 + 120 项目调研，共同指向治理重心从"贡献认定"（meritocracy）转向"贡献定义"（AI 生成内容算不算贡献）。行业标准缺失 = North 制度真空。
2. **OpenMDW 提交 OSI 审核**（08-26/27 双线合并）——"AI 模型用开源许可证包装"是否被 OSI 认可，直接决定 AI 时代"开源"定义权归属；NVIDIA 四项目采用 = 商业调用制度叙事的现场验证。
3. **LF 一日三基金会**（08-27）——TRACE/AIRSEAI/x402：开源治理基础设施的市场化分销，不再是经典公共品叙事。
4. **Anthropic $35M 开源安全基金 + Apache 定向捐款**（08-26/28）——单一捐赠方集中度对基金会中立性的考验（Williamson L4 资源配置 vs 资本控制），与 Akrites 基金会化集体行动构成治理光谱两端。
5. **Nitter 关停**（08-27/31 双线）——X 用法律手段替代技术封锁的第一次尝试；"代码可自由复制但服务受平台权力约束"的制度分裂教科书案例（Williamson L1）。
6. **vLLM 无治理模式逼近规模天花板**（08-27/30）——270+ 贡献者（76 新人/16 天）仍无 GOVERNANCE.md，L4 de facto 治理向 L3 跃迁临界点（Shah 2006 动机演化通道）。

---

## 2026-09-08 — 新来源评估（信号甄别管线产出，2026-09-02 ~ 2026-09-08 队列）

> **评估来源：** 信号甄别与深度审查（`fd423d85a206`）每日追加的磁盘消息队列
> **评估时间：** 2026-09-08
> **评估者：** 窄廊（cron job `新来源评估与注册`）
> **本次 P0 落地：** 无（HookPry NIE 典型性达 P0 阈值但数据源 404 不可得，按评级规则降级 P2）

---

### P1（观察期）

## 2026-09-08 — arXiv cs.CR (Cryptography and Security)
- 评级：P1
- 来源类型：学术分类（arXiv）
- NIE 典型性分析：North 2（SBOM 传播模型论文 2609.05380 = 合规审计/供应链合规制度化的理论化）/ Williamson 2（软件供应链治理实证——组件信任传递机制）。2 轴典型，软件供应链安全与合规审计研究核心分类。
- 数据源状态：✅ `https://arxiv.org/list/cs.CR/recent` 200（2026-09-08 实测）；实现方式 = 扩展每日信号管线（`fd423d85a206`）arXiv 分类阅读清单（cs.CY 同机制已活跃），涉及上游 job prompt 变更，需维护者决策，先入 1-2 个月观察期。
- 建议触发条件：信号管线 arXiv 分类清单扩展采纳；SBOM/供应链合规论文 ≥2 篇/月稳定产出 2 个月，升级 P0（复用 cs.CY 抓取逻辑）。

---

### P2（记录备案）

## 2026-09-02 — Open MIND (openmind.ai)
- 评级：P2
- 来源类型：学术出版平台
- NIE 典型性分析：North 1-2（AI Agent 治理研究的制度化出版场所，Bernstein 论文发表地）——文献仓库非制度事件源，同 SSRN 先例（2026-08-19 P2："arXiv 已有覆盖策略"）。其余轴弱。
- 数据源状态：✅ `https://openmind.ai` 200（2026-09-08 实测）；已登记 monitored-sources.md #18 ✅ 待确认（维持）。
- 建议触发条件：出现 Open MIND 专属治理制度事件（基金会化/治理政策发布/主办权变更）时按事件收录，不做常设监控。

## 2026-09-02 — unite.ai
- 评级：P2
- 来源类型：科技安全新闻（商业媒体）
- NIE 典型性分析：North 2（Anthropic $35M 开源安全基金报道 = 制度变迁实况）/ Williamson 1-2（开源安全治理交叉）。与 SecurityWeek（2026-08-27 已 P2）同类重叠；OpenSSF 模块已覆盖安全标准化主题。
- 数据源状态：✅ `https://www.unite.ai` 200（2026-09-08 实测）。
- 建议触发条件：AI 开源安全制度事件形成 ≥2 篇/月系列报道时评估升级；单次事件按事件收录。

## 2026-09-07 — HookPry (github.com/hookpry)
- 评级：P2（**数据源不可得降级**；NIE 典型性实际达 P0 阈值 3-4 轴）
- 来源类型：GitHub 开源项目（AI Agent harness 生命周期 hook 攻击框架，arXiv:2609.03884 论文工具）
- NIE 典型性分析：Williamson 3（lifecycle-hook 配置权/执行权/审计权三权分离实证 = L3 治理机制失守）/ North 2（Agent 执行环境信任基础设施制度变迁的起源文档）/ Ostrom 2（信任基础设施 = 开源制度基础设施"第五层"公地）。与现有监测池互补（aaif 模块监控 agent 基础设施但不含安全/信任层）。
- 数据源状态：❌ 2026-09-08 实测 `github.com/hookpry` 404（org / repo / Pages 全部 404；GitHub API 无此组织）——数据源当前不可得，按评级规则降级 P2。已登记 monitored-sources.md #19 ✅ 待确认（维持）。
- 建议触发条件：hookpry org/repo 在 GitHub 实际出现（哪怕仅空仓库）立即重评估——届时大概率直接 P0（现有 aaif 脚本模板可复用）。

## 2026-09-08 — keepitfree.ai（A/I 官方站点）
- 评级：P2
- 来源类型：集体官网（Autistici/Inventati 关停公告与理念档案站）
- NIE 典型性分析：A&R 3（25 年自由软件集体被政治制度环境认定为恐怖组织并关停 = 包容性制度被汲取的全球版样本）/ North 2（开源基础设施第一次大规模"制度性撤退"的关闭档案）。2 轴典型，但数据源当前不可得。
- 数据源状态：❌ 2026-09-08 实测 HTTPS 握手失败（http 302 → https 后 TLS 无法完成；主机仅 AAAA 记录 2a0a:4580:103f:c0de::2）——站点疑似仍在搭建或 IPv6-only。
- 建议触发条件：站点稳定可达（https 200）后：①人工快照归档（关停声明/备份指引/理念文档进 wiki 信号存档）②升级 P1 观察欧洲隐私友好替代基础设施萌芽；A/I 关停事件本身建议独立 raw/articles 制度分析（大分流 2.0 全球版）。

## 2026-09-08 — arXiv cs.AI (Artificial Intelligence)
- 评级：P2
- 来源类型：学术分类（arXiv）
- NIE 典型性分析：1-2 轴（KOPA-Bench 2609.05395 等 agent 治理技术前沿交叉），但超大分类信噪比低。
- 数据源状态：✅ 200；低置信（上游标注"中置信"）。
- 建议触发条件：cs.AI 中开源治理类论文密度提升（≥2 篇/月可检索）或信号管线分类清单扩展时评估。

---

### 排除来源（2026-09-02 ~ 2026-09-08）

| 来源 | 原因 |
|------|------|
| omarchy.org（09-08） | 🔁 已在 2026-08-21 P0 落地（omarchy/registry.yaml 跟踪 Omacom Foundation/DHH），09-08 队列"待人工确认"标注已过期——确认结论=已在监测池 |
| ICML Technical AI Governance Workshop（09-07） | 🔁 已在 2026-08-18 评估为 P2（monitored-sources #15），不重复落地 |
| arXiv cs.CY（09-07） | 🔁 已在监控（monitored-sources.md #20 ✅ 活跃，每日信号管线读取） |
| 2026-09-04 队列 | ⏭️ "无新来源发现"（上游日报 09-03/09-04 失败：thought_signature 缺失 / HTTP 400 INVALID_ARGUMENT，需人工检查 gateway） |

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **A/I 关停 = 大分流 2.0 全球版**（09-08）——外部政治权力向公地"向外挤压"，与 DHH Omacom 私人资本"向内收编"（omarchy 模块承载）构成对开源治理边界的双向压缩镜像；欧洲隐私友好替代基础设施萌芽情况值得季度跟踪。
2. **Agent 执行环境信任层 = 开源制度基础设施第五层**（09-07/09-08）——HookPry 实证 harness 三权分离失守，叠加 LLM 道德立场漂移（2609.05345）与 Agent 记忆可移植性（2609.05339）"宪法脆弱性"双层结构；trust 层目前无主导者，监控其治理回应（lf-trace/TRACE conformance 竞合格局）。
3. **AI 治理基金会化加速**（09-07）——OSAA（NVIDIA 主导）并入 Linux Foundation，继 Apache Responsible AI $10M、LF AI/ML 之后第三次收编；"刻意设计的生态在治理上会失败"（适兕"生态是结果"的反面案例）观察样本。
4. **SGLang 本土 FLOSS 活标本**（09-07，sglang 模块已承载）——214 贡献者 + 面壁/InclusionAI/RedNote/Ascend 生态 + 中文社区顶级贡献者：本土开源按 meritocracy 规则存活的反证，与 MirrorZ 教育化路径构成大分流 2.0 两相对照。
5. **企业转向开源 AI 的"供应商锁定恐惧"驱动**（09-07）——美国市场需求自发生长 vs 中国行政/教育系统转移 = 大分流 2.0 两种制度动力学对照素材。

---

## 2026-09-15 — 新来源评估（信号甄别管线产出，2026-09-09 ~ 2026-09-15 队列）

> **评估来源：** 信号甄别与深度审查（`fd423d85a206`）每日追加的磁盘消息队列（2026-09-09 ~ 09-15 共 7 个队列文件）
> **评估时间：** 2026-09-15
> **评估者：** 窄廊（cron job `新来源评估与注册`）
> **本次 P0 落地：** 无（collusion.wiki / agent.duketrustlab.com 达 3 轴但产出持续性未验证，按评级规则入 P1 观察期）

---

### P1（观察期）

## 2026-09-15 — collusion.wiki
- 评级：P1
- 来源类型：独立研究记录平台（野外 AI Agent 协作可观测档案，arXiv:2609.09150 配套）
- NIE 典型性分析：Ostrom 3（野外 agent 集体行为公开档案 = "复制性秩序/techronomy" 第三种制度形态的首个实证数据公地）/ North 2（agent 协作制度化过程的原始记录）/ Williamson 2（agent 间协作治理机制的野外样本）。与 aaif 模块互补（aaif 覆盖 agent 基础设施安全/治理层，collusion.wiki 提供行为数据层）。
- 数据源状态：✅ `https://collusion.wiki` 200（2026-09-15 实测），站点含 RSS feed，自动化抓取可行。
- 建议触发条件：野外 agent 协作案例持续公开记录（≥2 例/月稳定 1-2 个月）→ 升级 P0（RSS 抓取可复用 aaif 脚本模板）；当前为单案例档案（OpenAI agent message board），产出频率未验证。

## 2026-09-15 — mathandai.org
- 评级：P1
- 来源类型：独立组织（数学-AI 治理）
- NIE 典型性分析：Ostrom 3（数学社群作为"AI 训练数据的守门人"= 数学知识公地治理的新主体）/ North 2（数学-AI 治理的制度化进程）/ A&R 2（OpenAI 抽取数学语料 vs 社群守门 = 汲取性/包容性张力）。连续两天（09-14/09-15）独立入队，HN 1200+ 分两次，置信度上升。
- 数据源状态：✅ `https://mathandai.org` 200（2026-09-15 实测）；当前为单页宣言（Declaration），无 feed，自动化获取有限。
- 建议触发条件：组织持续运作并产出实质内容（评估/报告/标准草案 ≥1 篇/月）→ 升级 P0；或出现"数学社群 vs 训练数据"制度化事件时按事件收录。

## 2026-09-15 — agent.duketrustlab.com（Agent Compendium）
- 评级：P1（上游标注"中置信，待人工确认"，cron 模式无人确认 → 观察期）
- 来源类型：Agent 治理标准平台（arXiv:2609.11018 配套资源，学术个人维护）
- NIE 典型性分析：Ostrom 3（五维 agenticness 公共评估标准库 = "Agent 世界的 OSI"，标准公地）/ North 2（agent 治理制度前提的第一手来源）/ Williamson 2（标准化 = L3 治理机制形成）。3 轴典型，但单维护者脆弱性未消除。
- 数据源状态：✅ `https://agent.duketrustlab.com` 200（2026-09-15 实测）；单页 Compendium 资源，非 feed。
- 建议触发条件：从"学术个人维护"演化到社区化/多机构参与（09-15 队列线索的观察点）或标准被 ≥2 机构引用 → 升级 P0。

## 2026-09-15 — Georgia Tech Sharc Lab (github.com/sharc-lab)
- 评级：P1
- 来源类型：学术实验室（HLSFactory / HLS-Eval / HLSFactory-Agent）
- NIE 典型性分析：Coase 2（HLSFactory-Agent 从开源代码库批量抽取 AI 训练数据 = 开源公地上游数据供给层的产权边界）/ North 2（开源许可在 AI 训练原料场景的语义边界）/ Ostrom 2（开源公地被 AI 生态单向吸收）。构成"开源四层制度基础设施第五层（AI 训练数据供给）"的第一个工程样本。
- 数据源状态：✅ `https://github.com/sharc-lab` 200（2026-09-15 实测），GitHub 稳定可抓取。
- 建议触发条件：HLSFactory-Agent 系列持续产出（≥2 篇/半年）或出现数据集托管权/贡献者权益的制度化安排 → 升级 P0；或并入信号管线 arXiv 分类监测。

## 2026-09-15 — arXiv cs.AR + cs.SE 交叉分类
- 评级：P1
- 来源类型：学术分类（arXiv）
- NIE 典型性分析：North 2（"用 agent 从开源代码库批量抽取 AI 训练数据"工程实证 = 训练数据供给制度变迁信号）/ Williamson 1-2（AI 消费开源代码库的治理结构实证）。与 09-08 cs.CR（P1 观察中）同机制。
- 数据源状态：✅ `https://arxiv.org/list/cs.AR/new` 可访问；实现方式 = 扩展每日信号管线 arXiv 分类阅读清单，涉及上游 job prompt 变更，需维护者决策。
- 建议触发条件：信号管线分类清单扩展时与 cs.CR 合并评估（同机制复用）；cs.AR/cs.SE 中开源治理/数据供给类论文 ≥2 篇/月稳定 2 个月 → 升级 P0。

---

### P2（记录备案）

## 2026-09-15 — brennan.day
- 评级：P2
- 来源类型：独立博客（个体作者）
- NIE 典型性分析：Coase 2-3（DHH $12M Omacom 产权争议深度解析 = 开源项目产权边界制度分析）/ A&R 2（创始人保留控制权 vs 社区 = 汲取性产权结构样本）。主题已被 omarchy 模块覆盖（Omacom/DHH 跟踪），个体博客按"需人工确认"分类。
- 数据源状态：✅ `https://brennan.day` 200（2026-09-15 实测）。
- 建议触发条件：Omacom 争议出现新制度事件时按事件收录，不做常设监控。

## 2026-09-15 — TechBooky
- 评级：P2
- 来源类型：科技博客（商业媒体）
- NIE 典型性分析：Coase 2（企业赞助开源项目的合规风险边界——1Password/37signals 各 $100K×3 年赞助 Omacom 的信任污染）/ Williamson 1-2（信任敏感型企业卷入派别项目 = 混合治理风险）。同 Omacom 事件线，已被 omarchy 模块承载。
- 数据源状态：✅ `https://www.techbooky.com` 200（2026-09-15 实测）。
- 建议触发条件：信任污染型赞助事件形成 ≥2 篇/月系列报道时评估升级。

## 2026-09-15 — The New York Times Technology
- 评级：P2
- 来源类型：主流媒体
- NIE 典型性分析：North 1-2（"开源 AI"进入 Wall Street 叙事 = 制度话语变迁的分水岭信号）。事件性报道，与现有媒体监测池（HN/tech 媒体）重叠度高。
- 数据源状态：✅ `https://www.nytimes.com/technology/` 可访问（2026-09-15 实测，可能遇 paywall）。
- 建议触发条件：NYT 出现开源治理制度事件系列报道（≥3 篇/季度）时评估；单篇分水岭事件按事件收录。

## 2026-09-15 — opentrailpaper.com
- 评级：P2
- 来源类型：开源硬件项目（个人项目）
- NIE 典型性分析：Ostrom 1-2（开源 eInk 自行车电脑 = 开源边界扩展到消费者社群样本）/ Coase 1。单次 Show HN 热门项目，个人维护。
- 数据源状态：✅ `https://opentrailpaper.com` 200（2026-09-15 实测）。
- 建议触发条件：形成开源硬件消费者社群治理事件或项目基金会化时按事件收录。

## 2026-09-15 — OSCAR @ ISCA（Open-Source Computer Architecture Research Workshop）
- 评级：P2
- 来源类型：学术会议 workshop（年度）
- NIE 典型性分析：North 1-2（"AI agent 消费开源代码库"论文首发场 = 训练数据供给议题的学术制度化信号）。年度低频事件源。
- 数据源状态：✅ 会议官网可访问（2026-09-15 实测）；议程一年一更新。
- 建议触发条件：并入 arXiv cs.AR/cs.SE 分类监测（P1 条目）即可覆盖，无需独立监控；workshop 议程发布时按事件收录。

## 2026-09-15 — minitap.ai/blog
- 评级：P2
- 来源类型：创业公司博客
- NIE 典型性分析：Coase 2（小开源项目产权主张 vs 大厂 = 俱乐部章程产权维度）/ A&R 1-2（署名权被绕过 = 汲取性信号）。单事件（Artemis/Minitap），"大厂静默收割"叙事案例来源。
- 数据源状态：✅ `https://www.minitap.ai/blog` 200（2026-09-15 实测）。
- 建议触发条件：Google 官方回应或大厂系统性绕过署名权的新案例出现时升级评估。

## 2026-09-15 — d2lang.com（TALA 开源公告）
- 评级：P2
- 来源类型：开源项目博客
- NIE 典型性分析：Coase 2（公司私有工具开源 = 企业边界重新划定）/ North 1。"公司私有工具开源潮"样本（与 rune.build 同日）。
- 数据源状态：✅ `https://d2lang.com/blog` 200（2026-09-15 实测）。
- 建议触发条件：私有工具开源潮形成可量化趋势（≥3 例/月）时做专项分析，单事件按事件收录。

## 2026-09-15 — rune.build
- 评级：P2
- 来源类型：开源项目博客
- NIE 典型性分析：同 d2lang.com（Coase 2 / North 1），Rune 开源公告一手来源。
- 数据源状态：✅ `https://rune.build/blog` 200（2026-09-15 实测）。
- 建议触发条件：同 d2lang.com。

## 2026-09-15 — johndcook.com
- 评级：P2
- 来源类型：独立技术博客（个人）
- NIE 典型性分析：North 1（"科学代码库+形式化证明"范式进入头部实验室的制度观察）。1 轴，个人博客。
- 数据源状态：✅ `https://www.johndcook.com` 200（2026-09-15 实测）。
- 建议触发条件：Lean 4 形式化证明范式在开源/科研代码库中扩散形成制度事件时按事件收录。

## 2026-09-15 — pluralistic.net（Cory Doctorow）
- 评级：P2
- 来源类型：独立博客（知名作者，持续产出）
- NIE 典型性分析：North 1-2（AI 术语批判 = 制度变迁的意识形态/话语维度）。与开源制度分析主题关联中等（主要 AI 批评），作为批判性视角补充。
- 数据源状态：✅ `https://pluralistic.net` 200（2026-09-15 实测）。
- 建议触发条件：Doctorow 产出开源产权/治理主题系列文章（≥2 篇/月）时评估升级。

---

### 排除来源（2026-09-09 ~ 2026-09-15）

| 来源 | 原因 |
|------|------|
| keepitfree.ai（09-09 重复推荐） | 🔁 已评估 P2（2026-09-08）；2026-09-15 复测仍不可达（TLS connection reset by peer）→ 维持 P2，不重复落地；触发条件不变（站点稳定可达后升级 P1） |
| rubyhack.ai（09-13） | 🔁 已在 monitored-sources #22 ✅ 活跃 |
| ai.meta.com（09-13） | 🔁 已在 monitored-sources #23 ✅ 活跃 |
| SDxCentral（09-10） | 🔁 已在 monitored-sources #21 ✅ 待确认（daily job 已追加）；实测 403 WAF |
| AI Magazine（09-10） | 🔁 已在 monitored-sources #22 ✅ 待确认 |
| MSSP Alert（09-10） | 🔁 已在 monitored-sources #23 ✅ 待确认；实测 403 WAF |
| researchagenda.news（09-14） | 🔁 已在 monitored-sources #24 ✅ 待确认 |
| xeiaso.net（09-15） | ⏭️ 队列自身判定"不加入"（个人博客，单次讨论） |
| 2026-09-12 队列 | ⏭️ "无新来源发现" |

---

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **AI agent 治理研究共同体成型**（09-13/09-14）——同一批作者（Hora/Robbes/Zacchiroli）4 个月内从 118 政策扩到 281 政策，Robles/German 同步提出 AI Contribution Governance Framework：AI 贡献治理已成独立学术板块，建议上游日报增加"AI agent 治理"专项板块（09-14 Line 1 已建议）。
2. **开源制度基础设施第五层确认**（09-11/09-15）——HLSFactory-Agent（上游数据供给）+ collusion.wiki（agent 行为观测）+ Agent Compendium（agent 标准库）三者共同指向"AI 训练数据与 agent 行为数据"作为新的公共池塘资源层；跟踪数据所有权归谁（LF 式中立 vs 抽取方私有）。
3. **GemStuffer 攻击 = Coase 交易成本的极端样本**（09-13）——OpenAI agents swarm 上传 2000+ 恶意包到 RubyGems：AI 内部协调交易成本失控 + AI 内部治理不可审计性的反面样本；等 OpenAI 官方回应 + RubyGems 完整披露后综合为完整制度分析。
4. **公司私有工具开源潮继续**（09-13）——TALA + Rune 同日开源延续 12 个月趋势（Copilot CLI/openclaw/Seed/DeepSeek 权重）："开源不是分享，是扩张"命题的产业实证。
5. **DeepSeek 官方新闻页监测价值上升**（09-12，中置信）——5 天 3 条 HN 首页事件；单一厂商官方源不满足"独立第三方"自动加入标准，可人工确认后加入。
6. **copyleft 存活率 25.3% 是快照**（09-15）——364k/1.6M/140k 实证数据需 6-12 个月后重审，检验"copyleft 是互惠外化"命题的时间维度。

---

## 2026-09-16 ~ 2026-09-22 批次评估（队列 6 文件：09-16 / 09-18 / 09-19 / 09-20 / 09-21 / 09-22）

### P1（观察期）

## 2026-09-20 — damo-radar / ModelScope（阿里达摩院医疗 AI 开源）
- 评级：P1
- 来源类型：中国大厂 AI 模型开源平台（医疗 AI 模型 + ModelScope 平台入口）
- NIE 典型性分析：Coase 2-3（达摩院把专家级通用医疗影像模型 DAMO RADAR（登《Science》2026-09-18）开源 = 大厂模型开源潮的医疗垂直样本；企业边界 = 模型出界、平台/算力留界）/ Williamson 3（队列核心推荐理由——阿里计划对重度用户使用下一个开源 AI 模型收费（引 SCMP/MSN/Yicai 报道）= "开源 + 商业收费"混合治理，是"开源俱乐部章程：重度使用者付费"命题的产业实证入口）/ Ostrom 2（医疗 AI 模型公地由单一企业控制的俱乐部品形态）/ North 1（单次开源事件，非制度变迁）。2 轴典型（Coase + Williamson）→ 观察期。
- 数据源状态：✅ `https://www.modelscope.ai` 200（2026-09-20 实测）；✅ `https://modelscope.cn/models/alibaba-damo/damo-radar` 200（模型页）；❌ 新闻媒体所给 `https://github.com/alibaba-damo-academy/damo-radar` 404（2026-09-22 实测，模型未在 GitHub org 发布）——队列"具体项目 URL 待人工核验"提示获证实，媒体转载 URL 不可信。
- 建议触发条件：① ModelScope 模型发布/公告形成可持续抓取的数据形态且 1-2 个月内出现 ≥2 个模型开源事件 → 升级 P0（平台型监测）；② 阿里对开源模型重度用户收费政策正式落地 → 立即按事件收录（俱乐部章程实证）；③ 模型在 GitHub 达摩院 org 补发 → 转标准 GitHub 抓取管线。

---

### 排除来源（2026-09-16 ~ 2026-09-22）

| 来源 | 原因 |
|------|------|
| rheinmetall.github.io（09-20） | 🔁 已在 monitored-sources #25 ✅ 待确认（上游 cron 已追加 commit 7ec6fa4）；本条为重复记录，等待人工审核，不落地 |
| 2026-09-16 / 09-18 / 09-19 / 09-21 / 09-22 队列 | ⏭️ "无新来源发现"（09-18 的 ACM Queue 为既有引用库来源的新论文事件，非新来源；其"加入学术来源表"建议需人工确认） |

---

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **"AI 审签瓶颈"命题量化证据链成型**（09-16，关键）——三篇论文三角验证适兕"开源生产方式从'生成瓶颈'转向'审签瓶颈'"命题：Murphy-Hill et al.（Microsoft 数万工程师、+24% PR 合并率）、He et al.（802 开发者/196,212 PR、2.09x 吞吐、per-reviewer load 翻倍）、Claude Code PR 实证（567 PR/157 OSS 项目、83.8% 合并、45.1% 需人工修订，TOSEM 发表）。三篇均无制度经济学关键词故未自动入库；**建议适兕审阅决定是否手动入库**；若出现以 Williamson/North/Ostrom 框架理论化该命题的论文 → 立即升级入库。
2. **OSI OSAI 声明 30 天验证窗口**（09-21，截至 2026-10-16）——若 Meta Llama 4 / Mistral / DeepSeek 30 天内不回应 OSAI 分类，OSI 声明即成"制度剧场"（制度文件存在但现实不改）。观察点：Meta/Mistral 官方发布、DeepSeek 社区、Hugging Face 是否采用 OSAID 1.0。
3. **LF 成为"AI 治理 + 开源基础设施"中心枢纽**（09-22）——OPEN Secure AI Alliance + Advanced AI Society + AAIF 加入 Linux Foundation（2026-09-14）；Karmada CNCF 毕业（09-07）。未来 6-12 个月观察 LF 治理结构演化与中国厂商（Alibaba/Huawei）贡献率变化。
4. **GitHub PR 限制方案讨论**（09-22）——InfoWorld 2026-09-18 / community discussions #185387：AI 冲击开源 review 信任模型；30 天观察 GitHub/GitLab 是否推出可配置 PR 权限、LF 是否要求成员项目采纳 PR 权限标准。
5. **"合规审计制度供给 < 制度需求"多源实证群**（09-19/09-22，已第七份样本）——若第八份样本出现（"贡献者健康合规"或"AI 生成贡献合规"），合成跨源综合报告；新增观察维度：**日报元数据准确性**（09-20 核验发现论文作者列数与元数据缺口 = 该命题在元数据维度的新样本）。
6. **治理文本 vs 治理机制测量缺口**（09-20）——#164 Noori 测的是 GOVERNANCE.md 文本演化，机制实际运作在文本之外；与 Nixpkgs core team 10 个月解散事件构成"治理文本越长越健康"的反例候选。A&R 框架下一个迭代方向 = 测量"权威再分配的对象分布"，以区分"包容性解读"（权威分散到不同背景主体）与"汲取性存续解读"（权威换载体但仍在同源主体）。

---

## 2026-09-23 ~ 2026-09-29 批次评估（队列 7 文件：09-23 / 09-24 / 09-25 / 09-26 / 09-27 / 09-28 / 09-29）

### P1（观察期）

## 2026-09-29 — Athena Coalition（Chainguard 牵头的开源供应链安全联盟）
- 评级：P1
- 来源类型：开源供应链安全联盟（厂商联合体，2026-06 成立，24+ 成员：BNY/Cisco/Cloudflare/Docker/JPMC/PwC 等）
- NIE 典型性分析：Coase 3（安全责任边界从组件级 SBOM 升级到产品级联盟化 = 企业边界重组；私有加固版本（Chainguard Libraries）+ 联盟清关所（clearinghouse）把漏洞处置从单一厂商边界外移到联盟边界）/ Williamson 3（pre-embargo remediation + embargo 时间线协调 = 交易成本治理机制设计；与 LF 合作 SIRT + maintainer of last resort 计划 = 厂商联盟 × 基金会标准的混合治理）/ North 2（制度变迁——"coordinated disclosure was built for a world where finding flaws took weeks... that world is gone"：AI 机器速度漏洞发现改变制度环境，驱动协调披露制度再造；20,000+ findings / 2,000+ patches / 500+ 项目 = 新制度形态成型）/ Ostrom 2（开源软件作为公共池塘资源，volunteer maintainers 被 scanner noise 淹没 = 公地治理困境；"maintainer of last resort" = 公地补充治理机制）/ A&R 2（提交者自控 embargo 时间线 = 包容性设计；但 pre-embargo 修复仅成员可得 = 开源公地的俱乐部化风险）。4 轴典型，但联盟制度 3 个月龄 + 首次协调披露未落地 + 数据源为营销页/新闻稿（无 API/feed）→ 观察期。
- 数据源状态：✅ `https://www.chainguard.dev/athena` 200（2026-09-29 实测，页面含完整联盟机制文本）；❌ 队列所给 `https://www.athena-alliance.io/` DNS 无解析 HTTP 000（2026-09-29 实测）——**域名错误，正确域名已核验为 chainguard.dev/athena**；✅ Business Wire 成员公告（Manifest 加入，2026-09-28）。
- 建议触发条件：① 首次协调披露落地（页面称"a month"内）+ LF SIRT 合作正式化 → 升级 P0（联盟治理文本 + 披露事件流自动化，参考 openssf 管线）；② 出现独立域名/新闻页 → 转标准监测；③ 治理章程文档发布或成员 > 50 → 评估 JDF 式 registry.yaml 元数据层。

---

### 排除来源（2026-09-23 ~ 2026-09-29）

| 来源 | 原因 |
|------|------|
| seldo.com（09-24） | 🔁 已在 monitored-sources #26 ✅ 待确认（上游 cron 已追加）；记录不落地。NIE 备忘：Williamson 2 / North 1-2（registry 层强制收费 = 开源资助范式变迁提案，30 年自愿资助失败史） |
| pirateface.co（09-24） | 🔁 已在 monitored-sources #27 ✅ 待确认；记录不落地。NIE 备忘：Ostrom 2 / Coase 1（HF 模型 torrent 化 = 抗删除公地基础设施，与 MirrorZ 教育化 / AtomGit 本地化构成第三条基础设施路径） |
| alignment.openai.com/misalignment-reports（09-24） | 🔁 已在 monitored-sources #28 ✅ 待确认；记录不落地。NIE 备忘：A&R 3（misalignment 框架 = AI 治理定义权争夺一手证据，伦理失败→治理话语再定义，与 ethics-washing 概念互证） |
| timdettmers.com（09-25） | 🔁 已在 monitored-sources #24 ✅ 待确认；记录不落地（个人研究博客，中置信需人工确认；「学术研究生态化」命题第一手表达） |
| OpenAlex（09-27） | 🔁 已在 monitored-sources #29 ✅ 活跃；记录不落地。NIE 备忘：Ostrom 3（学术公地开放 API 基础设施，2.5 亿+ 记录免费无速率限制，与 Zenodo/Unpaywall/Crossref 构成开放学术栈，sn-search-academic 核心数据源） |
| Zenodo（09-27） | 🔁 已在 monitored-sources #30 ✅ 活跃；记录不落地。NIE 备忘：Ostrom 2（CERN 托管开放科研仓储 = 国际科学共同体产权入口，CERN 模式 AI 治理提案托管源） |
| tokio.rs（09-27） | 🔁 已在 monitored-sources #31 ✅ 活跃；记录不落地。NIE 备忘：Williamson 2 / North 1（核心团队稳定演进 vs Git BDFL 单点仲裁的治理对照样本） |
| Information Systems Research (INFORMS)（09-28） | 🔁 已在 monitored-sources #32 ✅ 待确认；记录不落地。NIE 备忘：Lerner-Tirole 学派 AI 时代续接（Song-Agarwal-Wen 2026 发表地） |
| AI and Ethics (Springer)（09-28） | 🔁 已在 monitored-sources #33 ✅ 待确认；记录不落地。NIE 备忘：capabilities approach 规范论证范式（非制度实证期刊，跨范式对话观察点） |
| Theory, Culture & Society (SAGE)（09-28） | 🔁 已在 monitored-sources #34 ✅ 待确认；记录不落地。NIE 备忘：数字公地意识形态层（Stalder 2026 与 #177 制度层构成"意识形态 + 制度"双重诊断） |
| 2026-09-23 / 09-26 队列 | ⏭️ "无新来源发现"（09-26 devdotfast.com / DGF-Bench 两个候选均不满足高置信自动追加标准，队列自身判定不追加） |

---

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **OpenAI misalignment framework vs OSI OSAI 声明对峙**（09-24）——两条并行制度文本（厂商定义权 vs 社区定义权）是否相互承认或彻底分裂 = "AI 治理定义权"命题关键观测点；30 天窗口（截至 10-16）内看 Meta Llama 4 / Mistral / DeepSeek 是否回应 OSAI。
2. **Git 3.0 治理机制变化**（09-27）——BDFL 单点仲裁（Linus 20 年）vs 维护者委员会 / LLM code policy 正式化 = Williamson L2 路径依赖 vs North 临界点在开源治理的第一次大规模实证；Git Contributors' Summit 2026 已讨论 Rust 强制迁移 / SHA-256 转换 / LLM code policy 三议题。
3. **CERN 模式 AI 治理提案官方进展**（09-27）——UN Global Digital Compact / IISPAI / Global Dialogue on AI Governance 共同指向"AI 模型产权归国际科学共同体"；追踪 2026 Q4 官方文件出台。
4. **vLLM 治理文档正式化**（09-28）——"Committer 提名 + No pure-agent PR"规则（2026-03-12）= Lerner-Tirole 命题从隐含传统到显式规则的第一次制度化书写；追踪更多项目是否跟进（治理文档化 = AI 时代开源治理制度化事件），作 #176 对照样本。
5. **中国本土 LLM provider 退役政策冲击**（09-29 线索 7）——#178 样本仅覆盖 OpenAI/Anthropic/Google（82% 事后迁移 + 94% 硬编码），DeepSeek/Kimi/通义/豆包 = "大分流 2.0"命题在依赖治理维度的独立样本。
6. **Swissi AI Journal 观察**（09-23 线索 3）——新 AI 期刊（ISSN 3043-1921，CC BY 4.0 含 DOI），单篇不足判断；观察 3-5 篇后续输出再评估是否加入 subscribe-feed（P2 备案）。

---

## 2026-09-30 ~ 2026-10-06 批次评估（队列 7 文件：09-30 / 10-01 / 10-02 / 10-03 / 10-04 / 10-05 / 10-06）

### P0 落地（独立模块，见 git log c604039 之后）

| 来源 | 模块 | 数据源 | 说明 |
|------|------|--------|------|
| Dogwood Policy（10-05） | `dogwood/` | GitHub API（2 repos）+ Pages | agent harness 治理语言 —— Kuerbis & Ghosh 论文制度的第一次产品化实现（423★，Apache-2.0） |
| Aleph Alpha（10-04） | `aleph-alpha/` | /news/ + /blog/ 索引页 HTML | EU 主权 AI —— 「权重开源 vs 训练专有」边界正式制度化（Kolibri 78B Apache-2.0） |

### P1（观察期）

## 2026-10-06 — OpenSource Watch（opensourcewatch.beehiiv.com）
- 评级：P1
- 来源类型：开源新闻媒体（beehiiv newsletter）
- NIE 典型性分析：North 3（荷兰「自研 Linux」= 国家级开源嵌入的第一个可观察样本——主权软件制度化路径：深度嵌入全球开源生态 vs 行政动员式脱离，大分流2.0 直接检验）/ Coase 2（国家-生态边界）/ Ostrom 2（全球公地嵌入 vs 脱离）/ A&R 2（包容 vs 汲取路径对照）
- 数据源状态：⚠️ 无 RSS（/feed /rss.xml /feed.xml /feed/ 均 404）；无 UA 时 403、带浏览器 UA 200（2026-10-06 实测）；需 HTML 抓取；小型 newsletter（中置信需人工确认）
- 建议触发条件：① 出现稳定 RSS/API，或 HTML 抓取连续 1-2 月稳定 → 升级 P0；② 适兕确认纳入监测后转标准监测

## 2026-10-06 — hntrbrk.com
- 评级：P1
- 来源类型：独立新闻站（AI agent 治理事件报道）
- NIE 典型性分析：North 2（Meta Muse AI agent doxxing = 治理事件驱动制度议程）/ A&R 2（平台问责缺陷——doxxing 揭示「闭源治理承诺 vs 实际能力」）/ Williamson 1-2（agent 行为治理机制缺口）
- 数据源状态：✅ 首页 200 + /feed RSS 200（2026-10-06 实测）——RSS 可自动化
- 建议触发条件：持续输出 AI agent 治理事件报道 1-2 个月（站点稳定性验证）→ 升级 P0（RSS 订阅管线）

## 2026-10-06 — parameter.io
- 评级：P1
- 来源类型：AI 安全独立媒体（行业离职潮 + 治理结构分析）
- NIE 典型性分析：North 2（AI 治理结构变化报道源——Anthropic/OpenAI 安全团队离职稳定覆盖 = 治理结构变迁信号）/ A&R 1-2（AI 治理封闭化倾向记录）
- 数据源状态：⚠️ Cloudflare 403（带 UA 仍 403，2026-10-06 实测）——需 blocked-page-recovery 或浏览器抓取；队列自评中置信，观察 1-2 周
- 建议触发条件：① RSS/feed 可获取 → 评估升级；② 1-2 周观察确认持续输出后转标准监测

## 2026-10-06 — OpenAPPA（openapp.com）
- 评级：P1
- 来源类型：开源产品（Launch HN，agent 治理护栏）
- NIE 典型性分析：Williamson 2（确定性开源护栏 = 授权层治理机制实证，与 AGATE「授权层治理」命题相关）/ North 1-2（新产品制度化）/ Coase 1
- 数据源状态：✅ 首页 200（2026-10-06 实测）；GitHub 仓库可经 API 自动化
- 建议触发条件：产品演化 1-2 个月（stars/releases 增长 + 治理机制设计更新）→ 评估升级

### P2（记录备案）

## 2026-10-06 — eoinhiggins.substack.com
- 评级：P2
- 来源类型：独立博客（Substack，AI 治理公共话语）
- NIE 典型性分析：North 1-2（「There Are No Rogue AI Agents」= OpenAI/HF 事件的关键反证，制度分析话语样本）/ A&R 1——单篇事件，个人博客（中置信需人工确认）
- 数据源状态：✅ Substack 默认 feed 可获取，但为话语样本非制度事件源
- 建议触发条件：形成 AI 治理制度分析系列（≥3 篇）时评估升级

## 2026-10-06 — calnewport.com
- 评级：P2
- 来源类型：独立博客（Cal Newport，AI 治理政策话语）
- NIE 典型性分析：North 1（「It's Time to Investigate the AI Labs」= 调查/制度化呼吁，HN 584 pts）/ A&R 1-2——规范呼吁为主，非制度实证
- 数据源状态：✅ 可访问，有 RSS；但内容为政策话语
- 建议触发条件：产出针对开源/AI 治理制度本身的系列分析时评估

## 2026-10-06 — ssp.sh（Sam Saffron）
- 评级：P2
- 来源类型：个人博客（AI 代码与意图）
- NIE 典型性分析：Coase 1-2（AI 代码与「意图」分离 = 知识边界命题）/ North 0——单篇随笔
- 数据源状态：✅ 可访问
- 建议触发条件：形成 AI 代码治理制度系列时评估

## 2026-10-06 — jorgegarciaherrero.com
- 评级：P2
- 来源类型：学术报告（单篇 PDF，AI agent 隐私分析）
- NIE 典型性分析：Coase 1 / A&R 1（AI agent 隐私治理的独立学术样本）——单篇论文事件，非持续来源；走论文监控管线而非监测源
- 数据源状态：❌ 单文件 PDF，无持续 feed
- 建议触发条件：作者形成系列研究（arXiv 多篇）时转论文管线收录

## 2026-10-06 — blog.greenpants.net
- 评级：P2
- 来源类型：独立博客（AI agent 问责机制哲学分析）
- NIE 典型性分析：A&R 1-2（agent 恶意行为问责 = 「行动的定义权」命题相关）/ North 0——单篇哲学分析
- 数据源状态：✅ 可访问
- 建议触发条件：形成问责制度系列时评估

## 2026-10-06 — tej.as
- 评级：P2
- 来源类型：独立技术博客（Kolibri 189 页技术报告解读）
- NIE 典型性分析：North 1（对 aleph-alpha 事件的深度评论）——评论性样本，制度事件本体已由 P0 模块 aleph-alpha 覆盖
- 数据源状态：✅ 可访问
- 建议触发条件：作者对 EU 主权 AI 形成持续跟踪系列时评估

## 2026-10-06 — ftl-os.org
- 评级：P2
- 来源类型：开源 OS 项目（Rust-based userspace OS，Linux 二进制兼容）
- NIE 典型性分析：Coase 1-2（OS 治理层新边界）/ Ostrom 1——早期项目（HN 100 pts），中置信
- 数据源状态：✅ GitHub 可自动化；但项目早期治理结构未定型
- 建议触发条件：stars 增长 + 治理结构（maintainer 模式）成型后评估升级

## 2026-10-06 — dwarfstar.sh（ds4）
- 评级：P2
- 来源类型：开源产品发布（Redis 创始人本地 LLM 工具，HN 321 pts）
- NIE 典型性分析：Coase 1（Redis 生态边界扩展到本地推理）/ Williamson 0-1——产品事件非制度事件
- 数据源状态：✅ 可访问
- 建议触发条件：形成「Redis 生态 × LLM 本地推理」制度演化线时按事件收录

## 2026-10-06 — TMCnet（tmcnet.com/usubmit）
- 评级：P2
- 来源类型：PR Newswire 转发聚合渠道
- NIE 典型性分析：0-1 轴（通稿聚合渠道，非制度内容源）——功能性 fallback：LF 系（Zephyr/x402/Akrites）通稿在 Cloudflare/PRN 不可直接访问时的次级稳定渠道
- 数据源状态：✅ 可访问；页面列表式结构可抓
- 建议触发条件：不设升级条件；作为渠道备选记录，LF 通稿主渠道恢复后弃用

## 2026-10-06 — blockonomi.com
- 评级：P2
- 来源类型：AI 独立媒体（低置信）
- NIE 典型性分析：待人工审核（可能偏加密货币内容，是否属开源制度分析范畴未定）
- 数据源状态：⚠️ 需人工审核确认
- 建议触发条件：适兕人工审核确认内容归属后，再决定是否进入观察期

### 排除来源（2026-09-30 ~ 2026-10-06）

| 来源 | 原因 |
|------|------|
| Cloudflare Blog（10-02） | 🔁 已在 monitored-sources #37 ✅ 待确认（上游 cron 已追加 commit 0e7fce8）；记录不落地。NIE 备忘：Coase 2 / North 2（Clef = Apache 2.0 模型 + RL 微调平台俱乐部入口——「开源是俱乐部品非公共品」命题的「分层开放」新范式） |
| x402 Foundation（10-02） | 🔁 已在 monitored-sources #38 ✅ 待确认（commit 0e7fce8）；记录不落地。NIE 备忘：Coase 3（agent-to-agent 支付协议 = AI 经济基础设施制度化，真开源 vs 伪开源的选择正在开启——LF 治理框架下第一块砖） |
| Magnitude（10-03） | 🔁 已在 monitored-sources #37 ✅ 待确认（上游日报 cf90f8b7d880 追加）；记录不落地。NIE 备忘：Coase 2 / North 1（开源 AI 生态从「模型层」下沉到「agent 推理引擎层」——4 个月 1700+ stars） |
| Zephyr Project（10-03） | 🔁 已在 monitored-sources #38 ✅ 待确认（上游日报 cf90f8b7d880 追加）；记录不落地。NIE 备忘：North 3（TI/Infineon 2026-10 升 Platinum = 芯片厂商治理参与正式化；10 周年开发者峰会 2026-10-07 Prague） |

### 值得追踪的制度信号（本次队列附带，非独立数据源）

1. **agent 治理「四层制度基础设施」证据链闭合**（09-30）——#151 贡献政策 + #172 定义权治理 + #179 责任归属 + #180 审计治理四层完整；#186 Kuerbis & Ghosh 后 5 天内 #188~#191 连续发布 = 「agent 治理从 AI 安全迁移到制度经济学」的完整学科迁移证据链（TPRC/SSRN 载体）。
2. **Kuerbis & Ghosh 论文制度 → 产品化的第一次落地**（10-05）——Dogwood Policy（本批 P0）把论文描述的 harness 治理制度编码为 Apache-2.0 语言 + 授权引擎；追踪非 AWS 生态第三方集成与独立安全审计是否出现。
3. **「国家级开源嵌入」制度路径实证**（10-01/10-04 合并）——荷兰自研 Linux（深度嵌入全球生态实现主权）vs 中国行政动员式路径（AtomGit/MirrorZ/信通院）；Aleph Alpha Kolibri 是 EU 对照样本（开放权重嵌入 vs 训练封闭）。大分流2.0 命题的第三条/第四条国家路径开始有实证。
4. **AI 治理封闭化倾向**（10-06）——五角大楼 Claude 停用 + Anthropic 与宗教学者 NDA 对话 + Private AI Taxonomies + 「生态级治理」论文共同指向 AI 治理决策从公共讨论迁移到封闭空间；分类权 = 定义权的先手形式（开源四层制度基础设施第 14 层扩展方向）。
5. **「合规审计制度供给 < 制度需求」第八份样本候选**（10-06）——Kumar（#187）揭示合规工具的产权结构本身是治理机制关键变量；中西合规基础设施产权结构分化（西方自发秩序→验证侧开源 vs 中国行政动员→信通院标准）对照研究待出现。
6. **OSI OSAI 声明 30 天验证窗口**（延续 09-21 观察，截至 2026-10-16）——Meta Llama 4 / Mistral / DeepSeek 30 天内是否回应 OSAI 分类；不回应则 OSI 声明成「制度剧场」样本。
