# api-capture —— 教学 API 契约与数据存档

抓取时间:**2026-09-15 21:41:18**
来源:`https://kf.webxyq.com`(第三方教学服务器)

## 为什么要有这个目录

该 API 由**第三方教学机构**提供,你和它没有服务协议,它**随时可能关停、改接口或重置数据**。
本目录把**接口契约和全量基础数据**落盘,这样:

- 即使原 API 下线,你仍有完整的规格说明书可用于自研后端
- 全量真实数据可直接作为数据库初始化脚本,不必自己编造商品
- 答辩演示不再依赖外部服务

## 文件说明

| 文件 | 内容 |
|---|---|
| `接口契约.md` | 全部接口清单 + 关键约定 + 字段命名陷阱 |
| `schema.sql` | MySQL 建表语句 + 初始化数据(可直接执行) |
| `seed-data.json` | 整理后的结构化数据(banner/分类/商品/详情) |
| **`images/`** | **44 张商品图片实体文件(3.75 MB)** |
| **`images-manifest.json`** | 图片清单:原始 URL ↔ 本地路径 ↔ 被哪些字段引用 |
| `image-urls.json` | 图片 URL 探测记录(大小/类型/引用来源) |
| `capture.py` | 抓取脚本(可重复执行以刷新数据) |
| `probe_images.py` | 统计并探测图片 URL |
| `download_images.py` | 下载图片 |
| **`rewrite_urls.py`** | **图片 URL 批量替换工具(见下节)** |
| `raw/` | 每个接口的**原始 JSON 响应**,未经处理 |
| `capture-summary.json` | 抓取统计 |
| `raw/_request-log.json` | 全部请求记录(接口/参数/状态码) |
| `_backup_original/` | 替换前的原始文件备份(首次替换时自动生成) |

## 数据规模

- 轮播图 **4** 条
- 商品分类 **4** 个(latte / coffee / rena_ice / fruit_tea)
- 商品 **22** 个,**详情全部抓到**
- **商品图片 44 张(22 张大图 + 22 张小图),全部下载到本地**
- 搜索样本 4 组

## ⚠️ 重要:JSON 里存的仍是**远程 URL**

`seed-data.json` 和 `schema.sql` 里 `smallImg`、`largeImg`、`bannerImg` 的值仍然是
`https://kf.webxyq.com/images/...` 这样的**远程地址**。

图片文件虽然已经下载到 `images/`,但**数据库里的 URL 不会自动指向本地**。
自研后端上线前需二选一:

| 方案 | 做法 | 适用场景 |
|---|---|---|
| **A. 保持远程 URL** | 什么都不改 | 原服务器还在时快速跑通 |
| **B. 改为自建 URL** | 把 `https://kf.webxyq.com/images/` 批量替换为你的地址(如 `http://你的后端/img/`),并把 `images/` 上传到对象存储 | **答辩演示,彻底不依赖外部服务** |

`images-manifest.json` 保留了完整的 `原始URL → 本地路径` 映射,可直接用于批量替换。

### 用 `rewrite_urls.py` 一键切换

```bash
# 查看当前状态(不做修改)
py -3.13 rewrite_urls.py --report

# 预览会改哪些(不写入)
py -3.13 rewrite_urls.py --to http://localhost:8080/images/ --dry-run

# 正式替换成自建后端
py -3.13 rewrite_urls.py --to http://localhost:8080/images/

# 替换成对象存储 / CDN
py -3.13 rewrite_urls.py --to https://cdn.example.com/lucky/images/

# 恢复成原始远程地址
py -3.13 rewrite_urls.py --restore
```

**行为说明:**

| 特性 | 说明 |
|---|---|
| 默认范围 | 只改 `schema.sql` + `seed-data.json`(共 140 处) |
| `raw/` | **默认保持原样**,作为未经改动的基准;需要时加 `--include-raw`(总计 276 处) |
| 自动备份 | 首次替换前把原文件备份到 `_backup_original/`,**不覆盖已有备份** |
| 可恢复 | `--restore` 一键还原 |
| 状态记录 | `_rewrite-state.json` 记录当前前缀与操作历史 |

## 安全与合规说明

- 本目录**只调用了只读接口(GET)**,未触碰任何写操作接口,不会污染教学环境数据。
- `appkey` 是教学环境公开的共用标识,你的工程里本来就有(`entry/src/main/ets/api/Request.ets`)。
- 图片已下载到本地 `images/` 目录,供自研后端离线使用。

## 如何使用

```bash
# 1) 建库导数据
mysql -uroot -p your_db < schema.sql

# 2) 刷新数据(原 API 仍可用时)
py -3.13 capture.py
```

## 自研后端注意

前端 `Request.ets` 只需改第 4 行的 `BASEURL` 即可切到你的后端。
后端必须严格匹配 `接口契约.md` 里的 4 条约定,否则前端要跟着改。
