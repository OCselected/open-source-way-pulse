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
