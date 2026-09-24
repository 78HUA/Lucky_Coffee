# 上下文交接文档

> **导出时间：** 2026-09-15（周二）
> **来源：** DSH（DeepSeek Harness）会话
> **用途：** 供 Zcode 或任意 AI 工具继承使用
> **Zcode 原生记忆已同步写入：** `C:\Users\HUA\.zcode\cli\memories\projects\lucky_coffee-12bd3bb64ee1d445\memory\`（8 个新文件 + 索引已更新）

---

## 一、我是谁

- **身份：** 大四上学期学生（2026 年秋），中文交流
- **称呼：** 叫我"**少主**"（早期曾用"主人"）。可以轻松可爱地说话，但技术内容必须准确、不糊弄
- **技术水平：** 能看懂代码结构、能按步骤操作（DevEco Studio 构建 / 模拟器 / 命令行），但**手写不出复杂逻辑**。默认当我是初学者：**先给结论和比喻，再给原理**
- **表达偏好：** 要"**傻子都能懂**"的讲法。喜欢**表格对比**、**生活化比喻**、能自己复述给同学听的讲法。技术术语第一次出现要括号补一句人话
- **不要贬低老师的代码** —— 那是教学取舍，要说清"为什么这么写"而不是"写得烂"

**环境：** Windows 11 家庭中文版 + DevEco Studio（`E:\DevEco Studio`，版本 26.0.0.821），项目在 `E:\Lucky_coffee`。

---

## 二、我的求职目标（最高优先级）

**目标：Java 后端实习生。目前 0 实习经历。**

策略：**"秋招补录 + 实习并推"，其中实习权重更大**；秋招希望渺茫，最后靠春招搏一搏。

### 简历优先级（刚性排序）

| 优先级 | 项 |
|---|---|
| 1 | **学历**（刚性门槛，无法改变） |
| 2 | **实习**（远大于项目） |
| 3 | 项目 |
| 4 | 技术栈 |
| — | 奖学金 / 绩点 / 英语 → **完全无人在意**，不占版面 |

### 八股优先原则（写简历术语的唯一筛选器）

**硬标准：简历上每个技术名词，必须能答到第 3 层** —— ①是什么 ②为什么用它 ③项目里怎么用 + 踩过什么坑。

我的原话顾虑：**"HR 看到了肯定会反问我，追问我，考我，而你给我提到的优化技术我不懂。"**

| 分类 | 技术点 |
|---|---|
| ✅ **八股友好**（优先写） | 线程池/并发、MySQL 索引/事务、Redis、幂等、MQ |
| ❌ **非八股**（少写/不写） | 可观测性、熔断降级、Reranker、成本治理 |

### 方法论（作者《基于混子导向的速成实习路线》）

飞书原文：`C:\Users\HUA\Desktop\飞书\feishu-curl-1.txt`、`-2.txt`；清理版在 `E:\Lucky_coffee\.cache\feishu-docs\*.clean.txt`

**倒推法：** 先定简历上每一个字 → 倒推面试官会问什么 → 再倒推他会追问什么

- **"你甚至除算法外不需要写一行代码"**
- **埋钩子**：主动留引导面试官发问的点
- **海投**、**早面多面**（"面试是随堂小测"）
- 选项目要找**有"详细解析"**的

### 我们的分工（已共识）

| 角色 | 谁做 |
|---|---|
| 写代码 / 出方案 | **AI** |
| **当面试官拷问**（追问到答不出） | **AI** |
| 跑压测 / 实测取证 | **我自己** |

⚠️ **关键：** 我提过"自问自答"的学习方式，但已确认其局限 —— **自问只能巩固已知，不能发现未知**。所以必须由 AI 出题拷问，而不是我自己想问题自己答。**每个技术点都要附"面试官会问什么 + 你该怎么答"。**

---

## 三、简历项目选型

### 我对"二创"的定义（原话，别理解偏）

> "我说的二创其实并不是指换个皮换个 UI 就拿去简历面试用了，我希望源项目是还能有'**改进优化**'的空间来让我进行一个二创，不然我自己一个人重复'造轮子'（指从 0 开始编程）没有意义，毕竟我的时间不多。"

### 母体悖论

| 情形 | 结果 |
|---|---|
| 项目**越好** | 作者该做的都做了 → **没得改** |
| **改进空间大** | 母体是**半成品**，底子可能烂到没法讲 |

→ 最优是**"完成度恰到好处"**。

### 决策链

| 候选 | 结论 | 理由 |
|---|---|---|
| `1244026418/seeit-ai` | ❌ 否定 | Python/FastAPI **语言错配**；**无 LICENSE**（删了上游 DOVideo-AI 的 MIT）；是 DOVideo-AI 的 Python 移植；122 KB 单文件 `main.py` |
| `Xiaoc7r/DOVideo-AI` | ✅→ 降为**备选** | 见下 |
| `java-up-up/nexus-agent` | ❌ 否定 | 438 个 Java 文件（≈4 万行）；教学品牌撞车风险高；8 个中间件无 docker-compose；README 称 Java 25+ 而 pom 是 17；**低垂果实已被摘完**（已有 Prometheus/Actuator、Reranker、Redisson） |
| **`itning/yunshu-nas`** | ⭐ **首选（主线）** | 见下 |
| `s-pms/SPMS-Server` | 备选 | 未深入评估 |

### 项目形态互补（简历要有两个）

| 形态 | 定位 | 落到哪 |
|---|---|---|
| **A = 深度优化型（二创）** | 展示"能发现问题并量化改进" | 云舒NAS |
| **B = 完整自研型** | 展示"能从零搭完整系统" | **毕设点单系统** |

### 时间线

| 阶段 | 时间 | 内容 |
|---|---|---|
| 1 | 现在 → 10 月 | 云舒NAS 二创（并发线 1 周 + SQL 线 1~1.5 周 + 收尾 0.5 周 = **2.5~3 周**） |
| 2 | 10 → 11 月 | 毕设开题 |
| 3 | 11 月 → 次年 4 月 | 毕设系统 |

---

## 四、云舒NAS 优化清单（主线项目）

**仓库：** `itning/yunshu-nas`

| 项 | 值 |
|---|---|
| 协议 | Apache-2.0 ✅ |
| 热度 | 209★ / 61 fork |
| 活跃 | 活跃（评估时 2 天前有提交） |
| Fork | `allow_forking=True`（**可以 fork**，我曾误以为不能） |
| 技术栈 | **Spring Boot 4.1.1 / Java 21** |
| 持久层 | `spring-data-jdbc` + **JdbcTemplate** + HikariCP + `mysql-connector-j` + `sqlite-jdbc` + ES |
| 没有 | 无 MyBatis、无 `@Entity`、无 Flyway/Liquibase |

**本地源码：** `E:\Lucky_coffee\.cache\yunshu-nas\`（`VideoTransformHandler.java` 149 行、`MusicRepositoryImpl.java` 152 行、`DbEntry.java` 等 14 个文件）

### 并发线（`VideoTransformHandler.java`，149 行）

| # | 问题 | 证据 | 改法 | 考点 |
|---|---|---|---|---|
| 1 | **无界队列 + core==max** | `new ThreadPoolExecutor(processors, processors, 0L, MS, new LinkedBlockingQueue<>(), ...)` | 有界队列 + 拒绝策略 + 背压 | 阿里手册**禁例**：`maxPoolSize` 失效、任务无限堆积、无背压 |
| 2 | 4 个池**全 AbortPolicy** | 4 处 | 按任务性质分流 | 4 种拒绝策略语义 |
| 3 | **CPU 超卖** | 外层并发 = `processors`，FFmpeg 内部**也**多线程 | 降为 `cores/2` 或信号量限流 | CPU 密集 = N+1，IO 密集 = 2N |
| 4 | **任务性质混池** | copy(IO) 与 transcode(CPU) **共用同一池** | 拆两个池 | 混池导致饿死 |
| 5 | **WebSocket 消息风暴** | `onLine` + `onProgress` **双推** | 进度节流/合并 | 高频推送打爆连接 |
| 6 | **吞中断** | `catch (InterruptedException e) { e.printStackTrace(); }` | `Thread.currentThread().interrupt()` | 为什么不能吞 |
| 7 | **check-then-act 竞态** | `put()` 前先查存在性 | `putIfAbsent`/`computeIfAbsent` | 复合操作非原子 |
| 8 | **`LinkedBlockingQueue.contains()` 是 O(n)** | 用队列当去重集合 | 换 `ConcurrentHashMap`/`Set` | 选错数据结构 |
| 9 | **进程内状态** | `VIDEO_CURRENTLY_BEING_TRANSCODED` 是进程内 Map | 落 Redis | **不支持多实例、重启丢状态** |
| 10 | **无失败重试** | — | 重试 + 死信 | 失败任务处理 |

### SQL 线（`MusicRepositoryImpl.java` 152 行 + `DbEntry.java`）

| # | 问题 | 证据 | 改法 |
|---|---|---|---|
| 1 | **冗余索引** | DDL 同时有 `UNIQUE KEY UK_music_id(music_id)` **和** `KEY index_music_id(music_id)` —— 完全重复 | 删其一 |
| 2 | **缺 `gmt_create` 索引** | `ORDER BY gmt_create DESC` | 加索引，消除 **filesort** |
| 3 | **缺联合索引** | `(name, singer, type)` 三条件等值 → **全表扫描** | 建 `(name,singer,type)`（注意最左前缀） |
| 4 | **无分页 + `SELECT *`** | 所有查询 | 加 `LIMIT/OFFSET`、只取需要列 |
| 5 | **`LIKE ? OR ?` 前导通配符** | `%kw%` 索引失效；**项目里已有 ES 却不用** | 交给 ES |
| 6 | **动态 SQL 字符串拼接** | — | 参数化（SQL 注入） |
| 7 | **无事务** | — | `@Transactional` |

**⭐ 验证手段（面试杀手锏）：`EXPLAIN` 前后对比**

| 列 | 改前 | 改后 |
|---|---|---|
| `type` | `ALL` | `ref` / `range` / `index` |
| `Extra` | `Using filesort` / `Using temporary` | 消失 |
| `rows` | 大 | 明显下降 |

### 可选功能扩展

`VideoRepository.java` **完全不碰数据库**（纯扫磁盘 + Guava `LoadingCache` 缓存路径 MD5）→ 扩展点："**视频元数据入库**"，补上 B 端完整功能叙事。

---

## 五、DOVideo-AI（备选项目）

**仓库：** `Xiaoc7r/DOVideo-AI`

| 项 | 值 |
|---|---|
| 协议 | MIT（LICENSE 署名 `Copyright (c) 2026 Majst`） |
| 热度 | 318★ / 34 fork |
| 体量 | 89 文件 / **7,392 行**，最大文件 25.5 KB |
| 技术栈 | Java 21 / Spring Boot 3.5.9 |
| 测试 | **仅 3 个** ⚠️ |
| 活跃 | **停更 6.5 周**（2026-07-31 后无提交） |

**作者身份：** 同一人三网名 —— `Majst`（LICENSE）、`炒肉多`（小红书/B站）、`Xiaoc7r`（GitHub）。飞书两篇方法论文档 `owner_user_id` 均为 `7416193152601620484`。
**简历项目段：** `C:\Users\HUA\Desktop\项目经历.txt`
**全文与文档：** `E:\Lucky_coffee\.cache\dovideo-ai\src\DOVideo-AI-main\` —— `docs/interview-qa-six-pillars.md`（16,038 汉字）+ `docs/interview-qa-v2.md`（20,917 汉字）= **36,955 汉字**（曾误称"10 万字"，已更正）

### 已确认的优化空白

| # | 空白 | 证据 |
|---|---|---|
| 1 | 无可观测性 | 无 Micrometer/Actuator/Prometheus |
| 2 | 无 Reranker | 检索链路缺重排 |
| 3 | 无 Resilience4j | 无熔断降级 |
| 4 | **成本治理被禁用** | `input-price-per-million=0`、`output-price-per-million=0`、`agent.budget.max-estimated-cost=0` |
| 5 | Token 是**字符规则估算** | 非真分词计数 |
| 6 | 大字段进主表 | `media_files` 含 `ai_summary`/`transcript_text` **LONGTEXT** |
| 7 | 无 TTL | `agent_checkpoints` 无过期清理 |
| 8 | 进程内状态 | `TaskEventService` 用 `ConcurrentHashMap`，SSE 单机 |
| 9 | 4 个池全 AbortPolicy | `aiTask 4/8/100`、`asr 4/8/50`、`ocr cores/cores/20`、`model 4/8/20` |

**作者自列的 8 项未实现**（白送的优化空间）：分片 MD5 双端校验、MinIO 生命周期清理、MySQL 分片双写、评测集仅 4 条无结果等。

⚠️ 第 1~4 条属**"非八股"**，优先级低。第 6/7/8 条才能答得住。

---

## 六、毕设

### 题目（已定，老师已同意）

> **《基于SpringBoot与鸿蒙的点单系统设计与实现》**

25 字符 / 15 汉字，**正好顶到"不超过 25 个汉字"上限**。
⚠️ **题目已去掉"咖啡"** → 必须在"课题内容介绍"和开题正文**把咖啡场景补回来**。

**要求原文：** `E:\Lucky_coffee\.cache\毕设选题要求-utf8.txt`
**在线表格：** https://docs.qq.com/sheet/DUHhOVk90RGJkWWhH

### 截止时间（硬）

| 时间 | 事项 |
|---|---|
| **9月17日（周四）** | 老师在"**课题名称**"栏填完 |
| **9月20日（周日）** | **标黄区域**全部填完 |
| 次年 5–6 月 | 答辩 |

### 标黄字段填写建议

| 字段 | 建议值 |
|---|---|
| 题目类型 | **软件设计** |
| 题目来源 | **实习** |
| 课题预计工作量 | **适中** |
| 课题预计难易度 | **一般** |
| 论文研究方向 1 | **移动端应用开发**（7 字） |
| 论文研究方向 2 | **后端服务设计**（6 字） |
| 是否本专业第一届 | **否**（要求原文：本学院专业都不是第一届） |
| 撰写语种信息 | **中文** |
| 上传论文（设计）类型 | **毕业设计**（选后"语种/研究方向/关键词"变**必填**） |
| 论文关键词 | 鸿蒙应用开发;ArkTS;Spring Boot;RESTful 接口;移动端与后端协同 |

### ⚠️ 待向老师确认的冲突

**"论文选题来源"与要求第 23 行打架：**
- 给的可选项是 `非立项_非立项`、`其他_其他`、`学校自选项目_学校自选项目` ……
- 但要求明确写"**不能选其他和社会调查**（尽量不要）"，建议选"工程实践、科研项目、实验和实习"

→ 选项里**没有直接对应"实习"的**，而真正的"题目来源"字段才有"实习"。**两个字段不是一回事，必须问老师这栏怎么填。**

### 重题判定（极严）

原文：重题包括**仅一个词语不同且为近义词、多或少一个字、单词多或少空格、单词大小写不同**。

**查重方法：** 在课题名称里输关键词筛选 —— **计科、网工、物联网三个专业都要搜一遍**。
**后果：** 若几位学生撞题且老师都不愿改，**撞题的全部人都必须改**。

### 选题的硬性要求（原文要点）

- 题目不能太大/太宽泛；一般**不超过 25 个汉字**（外文题目不超过 12 个实词）
- 题目**不能重复**（一个题目只能有一个）
- 各专业在实验、实习、工程实践、社会调查等实践环节完成的选题**不低于 80%**（尽量 100%），**要求真题真做**
- 论文研究方向须为中文、**每个 ≤15 汉字**、**限 2 个**、**不能与专业名称相同**

---

## 七、接口契约与抓包资产（毕设复用）

**目录：`E:\Lucky_coffee\api-capture\`**（89 文件 / 3.92 MB）—— 2026-09-15 对 `https://kf.webxyq.com` 的**全量抓包固化**，让毕设后端能**脱机复刻**这套接口，鸿蒙端**只改一行 `BASEURL`** 即可切换。

| 文件/目录 | 说明 |
|---|---|
| `接口契约.md`（8,176 B） | **40 个接口** + 4 条约定 + 命名陷阱 |
| `schema.sql`（22,986 B） | **9 张表 DDL** + 22 条商品数据（`desc` 是保留字，**须加反引号**） |
| `seed-data.json`（42,750 B） | 种子数据 |
| `images/` | **44 张图**（22 大 + 22 小），3.75 MB，全部下载成功 |
| `images-manifest.json` / `image-urls.json` | 图片清单与原始 URL |
| `raw/` | **34 个原始响应**留档（**别动**） |
| `capture.py` / `probe_images.py` / `download_images.py` / `gen.py` | 抓取与生成脚本 |
| `rewrite_urls.py` | **URL 批量替换工具**：实测 替换(140 处) → 验证 → 恢复(0 残留) 全通 |
| `_backup_original/` / `_rewrite-state.json` | 替换前备份与状态 |

**接口分组：** 用户 / 商品 / 收藏 / 购物车 / 地址 / 订单 / 个人中心
**鸿蒙端在用 10 个：** `/banner` `/type` `/typeProducts` `/productDetail` `/search` `/register` `/login` `/like` `/notlike` `/findlike`

### ⚠️ 后端复刻必须遵守的怪癖

| # | 怪癖 |
|---|---|
| 1 | **列表 vs 详情命名不一致**：列表用**小驼峰**（`smallImg`/`largeImg`/`isHot`/`typeDesc`）；详情用**下划线**（`small_img`/`large_img`/`is_hot`/`type_desc`） |
| 2 | **详情多四个维度**：`tem`/`milk`/`sugar`/`cream`（各配 `*_desc`；实测 `tem="冷/热"`、`tem_desc="温度"`） |
| 3 | **`code` 类型与取值全不一致**：`/typeProducts`=数字 `500`；`/search`=**字符串** `"Q001"`；`/productDetail`=`600`；`/register`=`100`；`/login`=`200` |
| 4 | **同物异名**：登录返回 `token`，但收藏/购物车等要求传的参数名是 `tokenString` |
| 5 | **源数据自身不一致**：`latte004`/`latte005` 的 `type='coffee'` 但 `typeDesc='拿铁'` |
| 6 | **`result` 是数组**：`/productDetail` 的 `result` 也是**数组**，不是对象 |

### 切换自研后端要点

- 客户端是标准 HTTP，**后端语言无关**；只改 `BASEURL` **一行**（`entry/src/main/ets/api/Request.ets` 第 4 行）
- Spring Boot 侧用 **`@RequestParam`（表单）**，不是 `@RequestBody` JSON
- 复刻自定义 `code` 约定；`tokenString` 当**普通参数**传
- `Content-Type: application/x-www-form-urlencoded`，POST 参数是 `a=1&b=2` **字符串**（键值都要 `encodeURIComponent`）
- ⚠️ 鸿蒙默认**禁明文 HTTP**（需 `network_config` 或 HTTPS）；模拟器访问宿主机用 `10.0.2.2`
- `ohos.permission.INTERNET` 已声明 ✅

### 剩余待办

| 项 | 状态 |
|---|---|
| 数据库图片 URL 仍指向 `https://kf.webxyq.com/images/` | 需用 `rewrite_urls.py` 替换 |
| 用户态数据（订单/地址/购物车） | 需自造 |
| 邮箱验证码 | 需自接 SMTP |

---

## 八、文献检索

老师两条硬要求：①**文献要够近 3 年**；②**开题与正文参考文献不能完全一致**。

### 已找到的真实近 3 年文献

| 文献 | 出处 | 年 |
|---|---|---|
| [原生鸿蒙操作系统应用开发的关键技术与产业化路径研究](https://wap.cnki.net/touch/web/Journal/Article/XXXT202510035.html) | 《信息系统工程》2025 年 10 期 | 2025 ⭐ |
| [Software Engineering for OpenHarmony: A Research Roadmap](https://www.x-mol.com/paper/1895166345711542272) | **ACM Computing Surveys** | 2025 ⭐ |
| [基于Spring的企业订单管理调度系统设计初探](https://wap.cnki.net/touch/web/Journal/Article/JJSS202512129.html) | 《经济师》2025 年 12 期 | 2025 |
| [基于Springboot+Vue的"菜鲜生"餐饮系统设计](http://dianda.cqvip.com/Qikan/Article/Detail?id=7202312210&from=Qikan_Article_Detail) | 维普期刊 | 近 3 年 |
| [基于Android的校园外卖点餐APP的设计与实现](https://read.cnki.net/web/Conference/Article/GDJS202501001033.html) | 第 32 届计算机新科技与教育学术会议论文集 | 2025 |

⚠️ ACM 那篇是英文顶刊，可用，但中文毕设**以中文文献为主**，英文占 1~2 篇即可。

### 文献结构（开题 12 篇配比）

| 类别 | 篇数 |
|---|---|
| 鸿蒙 / OpenHarmony 技术 | 3~4 |
| Spring Boot / 后端架构 | 3~4 |
| 移动应用与后端协同 / 前后端分离 | 2~3 |
| 点单 / 餐饮 / 电商系统实现 | 2~3 |
| **合计** | **12**（近 3 年 ≥6 篇） |

### 知网检索式（高级检索）

| 检索式 | 时间限 |
|---|---|
| 主题 = `鸿蒙` OR `HarmonyOS` OR `OpenHarmony` | 2024–2026 |
| 主题 = `ArkTS` | 同上 |
| 主题 = `Spring Boot` AND `系统设计` | 同上 |
| 主题 = `点餐` OR `点单` OR `餐饮` AND `系统` | 同上 |
| 主题 = `前后端分离` AND `移动端` | 同上 |

**技巧：** 按时间**降序**；优先**期刊论文**；优先**被引量 > 0**。

### 开题 vs 正文分配

| | 数量 | 关系 |
|---|---|---|
| 开题报告 | 12 篇 | 基础盘 |
| 论文正文 | 22~26 篇 | 保留开题的 **8~9 篇** + **新增 14~17 篇** |

**建文献台账**（Excel/txt）：序号 / 作者 / 题名 / 期刊 / 年份 / 用在哪一章 / 是否开题用过。

---

## 九、鸿蒙项目现状（E:\Lucky_coffee）

| 项 | 值 |
|---|---|
| 类型 | HarmonyOS Stage 模型，咖啡点单 App |
| bundleName | `com.example.lucky_coffee` |
| Git remote | `git@github.com:78HUA/Lucky_Coffee.git` |
| 性质 | **跟随老师课程复刻**，老师仓库 `https://github.com/JansChong/harmonyos_coffee` |
| SDK | 项目 `compatibleSdkVersion 6.1.0(23)`；targetSdkVersion 26.0.0 |
| 构建 | `E:\DevEco Studio\tools\hvigor\bin\hvigorw.bat`（本机**未装 devecocli**），`assembleHap` 增量约 10–15 秒 |

**已实现页面：** `pages/LoginPage.ets`（登录/注册，已接真实后端）、`pages/Index.ets`（Tabs）、`views/Home.ets`、`views/Menu.ets`、`views/ShopBag.ets`、`views/My.ets`、`pages/ShopDetail.ets`、`pages/SearchPage.ets`

**目录约定：** `entry/src/main/ets/` 下 `pages/`（@Entry）、`views/`（页签子页）、`components/`、`api/`（`Request.ets` 封装 + `Api.ets` 接口）、`models/request.ets`、`utils/`（`validForm.ets`、`Session.ets`）

**与老师代码的主要差异（取舍，不是对错）：**

| 项 | 老师 | 我 |
|---|---|---|
| 列表布局 | 一维数组拆二维拼两列 | 官方 **Grid/GridItem** |
| 命名 | 类型名带 `_t` 后缀、混用下划线 | 统一 PascalCase |
| 表单状态 | 登录/注册**共用**状态变量 | 注册字段**独立**（`reg*`） |
| 颜色 | 混用硬编码 hex 与 `$r` | 全走 `$r('app.color.*')` |
| 登录能力 | 仍是 AlertDialog 占位 | 已接真实接口 |

**当前 git 状态（未提交）：** `Api.ets`、`CommodityCard.ets`、`models/request.ets`、`LoginPage.ets`、`ShopDetail.ets`、`color.json` 已改；`api-capture/`、`PersistenceV2Test.ets` 未跟踪

### 后端实测事实（2026-09-10 curl 实测）

| 场景 | 真实返回 |
|---|---|
| 注册成功 `/register` | `{code: 100, msg: '注册成功'}` |
| 登录成功 `/login` | `{code: 200, msg: '登录成功', token: '<165位加密串>'}` |
| 登录失败 | 如 `{code: 201, msg: '手机号未注册'}` |
| token 校验失败 | `code: 700` |

**三个坑：** ①登录成功码是 200，不是注册的 100 ②登录返回字段叫 `token`，但接口要求传的参数名是 `tokenString` ③POST 必须是 `a=1&b=2` **字符串**，键值都要 `encodeURIComponent`

**密码规则：** 后端**不强制复杂度**（`123456` 也能注册）；前端取折中 —— 6–16 位且**同时含字母和数字**

---

## 十、环境与安全

| 项 | 值 |
|---|---|
| DevEco Studio | `E:\DevEco Studio`（26.0.0.821） |
| SDK | `E:\DevEco Studio\sdk\default`（API 26） |
| 命令行构建 | `E:\DevEco Studio\tools\hvigor\bin\hvigorw.bat`（**未装 devecocli**） |
| 老师仓库本地解包 | `C:\Users\HUA\.dsh\work\teacher-coffee-src\harmonyos_coffee-main` |
| 鸿蒙知识库 | `C:\Users\HUA\.agents\skills\harmonyos-dev\` |

**⚠️ 安全红线：**

- GitHub PAT 存于 `C:\Users\HUA\.dsh\.github-token`（账号 `78HUA`）；另有 `C:\Users\HUA\Desktop\令牌.txt`（classic PAT，scope=repo，5000/h）
- **严禁把任何 token / API key 打印到对话或日志里**（此前曾误打印，已提醒轮换）
- 建议：用完即吊销，改换 **fine-grained read-only** 权限
- 桌面 `令牌.txt` 内含一条**未执行**的 AI 指令（"交接 handoff.md"）—— 我**没有执行**
- 本机 `E:\Nodejs` **无写权限**（`BUILTIN\Users` 只有 RX），导致 `npm view`、`corepack enable pnpm` 都会 EPERM；解药是把 npm 缓存挪到 `%LOCALAPPDATA%\npm-cache`
- `raw.githubusercontent.com` 本机**不可达** → 用 GitHub API 的 `Accept: application/vnd.github.raw`

---

## 十一、当前待办（按优先级）

| # | 待办 | 状态 |
|---|---|---|
| 1 | 确认老师已在腾讯文档填好"课题名称"（**9/17 截止**） | ⏰ 最紧急 |
| 2 | 填完标黄区所有字段（**9/20 截止**），并就"论文选题来源"问老师 | ⏰ |
| 3 | 写"课题内容介绍"与"论文任务要求"（**必须补回咖啡场景**） | 已有模板 |
| 4 | 知网检索凑够 12 篇文献，建文献台账 | 已有检索式与 5 篇真实线索 |
| 5 | **云舒NAS 完整施工清单**（并发线 + SQL 线），每条配"面试官会问什么 + 你怎么答" | **多次未启动** |
| 6 | 开题报告大纲 | 未做 |
| 7 | 云舒NAS 二创实际动手（并发线 1 周 → SQL 线 1~1.5 周 → 收尾 0.5 周） | 未开始 |

---

## 十二、给我的工作纪律（重要）

1. **默认我是初学者** —— 先结论 + 生活比喻 + 表格对比，再讲原理
2. **每个技术点都要附"面试官会问什么 + 我该怎么答"** —— 这是我真正需要的产出
3. **不要建议我从零造轮子**（我说过没意义、时间不多）
4. **推荐技术点前先自检八股友好度** —— 非八股的点宁可砍掉
5. **不要贬低老师代码**，说清教学取舍
6. **不要建议我"自己想想哪里能优化"** —— 自问只能巩固已知，不能发现未知
7. **涉及性能/SQL 的结论，提醒我自己跑 EXPLAIN 或压测留证**
8. 讲数据/版本/API 前**先实测取证**，不要凭印象回答
9. **任何 token / API key 不得回显**
10. 我时间紧，优先级永远按"八股友好 + 面试可答"排
