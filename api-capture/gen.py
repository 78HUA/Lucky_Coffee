#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从抓取到的数据生成:
  1) schema.sql        —— MySQL 建表 + 初始化数据
  2) 接口契约.md        —— 40 个接口的契约清单
  3) README.md          —— 本目录说明
"""
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

OUT = r"E:\Lucky_coffee\api-capture"
DOC = r"E:\Lucky_coffee\API接口文档.md"
seed = json.load(open(os.path.join(OUT, "seed-data.json"), encoding="utf-8"))


def q(v):
    """转义为 SQL 字面量"""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("\\", "\\\\").replace("'", "''")
    # MySQL 中换行需转义
    s = s.replace("\n", "\\n").replace("\r", "\\r")
    return "'" + s + "'"


def sql_time(iso):
    """ISO8601 -> MySQL DATETIME"""
    if not iso:
        return "NULL"
    return "'" + iso.replace("T", " ").replace("Z", "").split(".")[0] + "'"


# ---------------------------------------------------------------- schema.sql
lines = []
A = lines.append

A("-- ============================================================")
A("--  Lucky Coffee 教学 API —— 数据库结构 + 初始化数据")
A(f"--  数据来源: {seed['meta']['source']}")
A(f"--  抓取时间: {seed['meta']['captured_at']}")
A("--  说明: 表结构由真实接口返回数据反推;字段命名保持与接口一致")
A("-- ============================================================")
A("")
A("SET NAMES utf8mb4;")
A("")
A("-- ------------------------------------------------------------")
A("-- 1. banner 轮播图")
A("-- ------------------------------------------------------------")
A("DROP TABLE IF EXISTS `banner`;")
A("CREATE TABLE `banner` (")
A("  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',")
A("  `banner_img` VARCHAR(512) NOT NULL COMMENT '轮播图地址',")
A("  `name`       VARCHAR(128) NOT NULL COMMENT '商品名称',")
A("  `pid`        VARCHAR(64)  NOT NULL COMMENT '关联商品 pid',")
A("  `sort_order` INT          NOT NULL DEFAULT 0 COMMENT '排序(接口未返回,预留)',")
A("  PRIMARY KEY (`id`),")
A("  KEY `idx_banner_pid` (`pid`)")
A(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='首页轮播图';")
A("")
A("INSERT INTO `banner` (`banner_img`, `name`, `pid`, `sort_order`) VALUES")
rows = [f"  ({q(b['bannerImg'])}, {q(b['name'])}, {q(b['pid'])}, {i})"
        for i, b in enumerate(seed["banner"])]
A(",\n".join(rows) + ";")
A("")

A("-- ------------------------------------------------------------")
A("-- 2. product_type 商品分类")
A("-- ------------------------------------------------------------")
A("DROP TABLE IF EXISTS `product_type`;")
A("CREATE TABLE `product_type` (")
A("  `id`         BIGINT       NOT NULL COMMENT '主键(接口返回真实 id)',")
A("  `type`       VARCHAR(64)  NOT NULL COMMENT '分类标识,如 latte/coffee',")
A("  `type_desc`  VARCHAR(64)  NOT NULL COMMENT '分类中文名',")
A("  `created_at` DATETIME     NULL,")
A("  `updated_at` DATETIME     NULL,")
A("  PRIMARY KEY (`id`),")
A("  UNIQUE KEY `uk_type` (`type`)")
A(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类';")
A("")
A("INSERT INTO `product_type` (`id`, `type`, `type_desc`, `created_at`, `updated_at`) VALUES")
rows = [f"  ({t['id']}, {q(t['type'])}, {q(t['typeDesc'])}, {sql_time(t.get('createdAt'))}, {sql_time(t.get('updatedAt'))})"
        for t in seed["types"]]
A(",\n".join(rows) + ";")
A("")

A("-- ------------------------------------------------------------")
A("-- 3. product 商品")
A("--    注意: `desc` 是 MySQL 保留字,必须用反引号")
A("--    注意: 列表接口返回 smallImg/largeImg/isHot/typeDesc(小驼峰)")
A("--          详情接口额外返回 tem/milk/sugar/cream 四个客制化维度")
A("-- ------------------------------------------------------------")
A("DROP TABLE IF EXISTS `product`;")
A("CREATE TABLE `product` (")
A("  `id`         BIGINT       NOT NULL COMMENT '主键(接口返回真实 id)',")
A("  `pid`        VARCHAR(64)  NOT NULL COMMENT '商品业务 ID,如 coffee001',")
A("  `type`       VARCHAR(64)  NOT NULL COMMENT '所属分类标识',")
A("  `name`       VARCHAR(128) NOT NULL COMMENT '商品名',")
A("  `enname`     VARCHAR(128) NULL COMMENT '英文名',")
A("  `price`      DECIMAL(10,2) NOT NULL COMMENT '价格(接口返回字符串)',")
A("  `desc`       TEXT         NULL COMMENT '商品描述',")
A("  `small_img`  VARCHAR(512) NULL COMMENT '小图',")
A("  `large_img`  VARCHAR(512) NULL COMMENT '大图',")
A("  `is_hot`     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否热门 1/0',")
A("  `type_desc`  VARCHAR(64)  NULL COMMENT '分类中文名(冗余)',")
A("  `tem`        VARCHAR(64)  NULL COMMENT '温度选项,如 冷/热',")
A("  `tem_desc`   VARCHAR(32)  NULL COMMENT '温度标签',")
A("  `milk`       VARCHAR(128) NULL COMMENT '奶选项',")
A("  `milk_desc`  VARCHAR(32)  NULL COMMENT '奶标签',")
A("  `sugar`      VARCHAR(128) NULL COMMENT '糖选项',")
A("  `sugar_desc` VARCHAR(32)  NULL COMMENT '糖标签',")
A("  `cream`      VARCHAR(128) NULL COMMENT '奶油选项',")
A("  `cream_desc` VARCHAR(32)  NULL COMMENT '奶油标签',")
A("  `created_at` DATETIME     NULL,")
A("  `updated_at` DATETIME     NULL,")
A("  PRIMARY KEY (`id`),")
A("  UNIQUE KEY `uk_pid` (`pid`),")
A("  KEY `idx_product_type` (`type`),")
A("  KEY `idx_product_hot` (`is_hot`)")
A(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品';")
A("")

details = seed["product_details"]
A("INSERT INTO `product` (`id`,`pid`,`type`,`name`,`enname`,`price`,`desc`,`small_img`,`large_img`,"
  "`is_hot`,`type_desc`,`tem`,`tem_desc`,`milk`,`milk_desc`,`sugar`,`sugar_desc`,`cream`,`cream_desc`,"
  "`created_at`,`updated_at`) VALUES")
rows = []
for p in seed["products"]:
    d = (details.get(p["pid"]) or {}).get("result", [{}])
    d = d[0] if d else {}
    rows.append("  (" + ", ".join([
        str(p["id"]), q(p["pid"]), q(p["type"]), q(p["name"]), q(p.get("enname")),
        q(p["price"]), q(p.get("desc")), q(p.get("smallImg")), q(p.get("largeImg")),
        str(p.get("isHot", 0)), q(p.get("typeDesc")),
        q(d.get("tem")), q(d.get("tem_desc")), q(d.get("milk")), q(d.get("milk_desc")),
        q(d.get("sugar")), q(d.get("sugar_desc")), q(d.get("cream")), q(d.get("cream_desc")),
        sql_time(p.get("createdAt")), sql_time(p.get("updatedAt")),
    ]) + ")")
A(",\n".join(rows) + ";")
A("")
A("-- ============================================================")
A("-- 以下表结构根据 API接口文档.md 的接口语义【推测】，无真实数据")
A("-- 上线前请按接口实际返回字段核对")
A("-- ============================================================")
A("")
A("""-- 4. user 用户
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `phone`      VARCHAR(20)  NOT NULL COMMENT '手机号(登录账号)',
  `password`   VARCHAR(128) NOT NULL COMMENT '密码(务必加密存储)',
  `nick_name`  VARCHAR(64)  NOT NULL COMMENT '昵称',
  `desc`       VARCHAR(512) NULL COMMENT '个人简介',
  `avatar`     VARCHAR(512) NULL COMMENT '头像(接口以 base64 传输)',
  `user_bg`    VARCHAR(512) NULL COMMENT '个人背景图',
  `email`      VARCHAR(128) NULL,
  `is_destroy` TINYINT      NOT NULL DEFAULT 0 COMMENT '是否注销',
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- 5. user_like 收藏
DROP TABLE IF EXISTS `user_like`;
CREATE TABLE `user_like` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT      NOT NULL,
  `pid`        VARCHAR(64) NOT NULL,
  `created_at` DATETIME    NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_pid` (`user_id`, `pid`) COMMENT '保证同一用户对同一商品只能收藏一次',
  KEY `idx_like_pid` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品收藏';

-- 6. shopcart 购物车
DROP TABLE IF EXISTS `shopcart`;
CREATE TABLE `shopcart` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT      NOT NULL,
  `pid`        VARCHAR(64) NOT NULL,
  `count`      INT         NOT NULL DEFAULT 1 COMMENT '数量',
  `spec`       VARCHAR(256) NULL COMMENT '规格(温度/奶/糖/奶油快照)',
  `created_at` DATETIME    NULL,
  `updated_at` DATETIME    NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_pid_spec` (`user_id`, `pid`, `spec`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购物车';

-- 7. address 收货地址
DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `aid`        VARCHAR(64)  NOT NULL COMMENT '地址业务 ID(接口用 aid)',
  `user_id`    BIGINT       NOT NULL,
  `name`       VARCHAR(64)  NOT NULL COMMENT '收货人',
  `phone`      VARCHAR(20)  NOT NULL,
  `region`     VARCHAR(256) NULL COMMENT '省市区',
  `detail`     VARCHAR(512) NULL COMMENT '详细地址',
  `is_default` TINYINT      NOT NULL DEFAULT 0,
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_aid` (`aid`),
  KEY `idx_addr_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收货地址';

-- 8. orders 订单
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id`          BIGINT        NOT NULL AUTO_INCREMENT,
  `order_no`    VARCHAR(64)   NOT NULL COMMENT '订单号',
  `user_id`     BIGINT        NOT NULL,
  `address_id`  BIGINT        NULL,
  `total_price` DECIMAL(10,2) NOT NULL,
  `status`      TINYINT       NOT NULL DEFAULT 0 COMMENT '0待付款 1已付款 2已收货 3已取消',
  `pay_time`    DATETIME      NULL,
  `created_at`  DATETIME      NULL,
  `updated_at`  DATETIME      NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_order_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单';

-- 9. order_item 订单明细
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item` (
  `id`       BIGINT        NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT        NOT NULL,
  `pid`      VARCHAR(64)   NOT NULL,
  `name`     VARCHAR(128)  NOT NULL COMMENT '商品名快照',
  `price`    DECIMAL(10,2) NOT NULL COMMENT '下单时单价快照',
  `count`    INT           NOT NULL,
  `spec`     VARCHAR(256)  NULL COMMENT '规格快照',
  PRIMARY KEY (`id`),
  KEY `idx_item_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细';
""")

with open(os.path.join(OUT, "schema.sql"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines))
print(f"OK  schema.sql  ({len(chr(10).join(lines)):,} 字符)")

# ------------------------------------------------------- 接口契约.md
doc = open(DOC, encoding="utf-8", errors="replace").read()
# 抓取每个接口块
blocks = re.split(r"(?=请求地址：)", doc)
contracts = []
for b in blocks:
    m = re.search(r"请求地址：\s*(\S+)", b)
    if not m:
        continue
    url = m.group(1)
    path = "/" + url.rstrip("/").split("/")[-1].split("?")[0]
    meth = re.search(r"请求类型：\s*(\w+)", b)
    params = re.search(r"请求参数：\s*\{(.*?)\}", b, re.S)
    contracts.append({
        "path": path,
        "method": (meth.group(1) if meth else "?").upper(),
        "params": " ".join(params.group(1).split()) if params else "",
        "url": url,
    })
# 去重(保留首次)
seen, uniq = set(), []
for c in contracts:
    if c["path"] in seen:
        continue
    seen.add(c["path"])
    uniq.append(c)

USED = {"/banner", "/type", "/typeProducts", "/productDetail", "/search",
        "/register", "/login", "/like", "/notlike", "/findlike"}
CAPTURED = {"/banner", "/type", "/typeProducts", "/productDetail", "/search"}

MODULES = [
    ("用户与鉴权", ["/register", "/login", "/logout", "/destroyAccount", "/updatePassword",
                    "/retrievePassword", "/emailValidCode", "/checkValidCode",
                    "/updateNickName", "/updateDesc", "/updateAvatar", "/updateUserBg"]),
    ("商品", ["/banner", "/type", "/typeProducts", "/productDetail", "/search"]),
    ("收藏", ["/like", "/notlike", "/findlike", "/findAllLike"]),
    ("购物车", ["/addShopcart", "/shopcartCount", "/findAllShopcart",
                "/modifyShopcartCount", "/removeShopcart", "/deleteShopcart", "/shopcartRows"]),
    ("收货地址", ["/addAddress", "/deleteAddress", "/findAddress", "/editAddress", "/findAddressByAid"]),
    ("订单与支付", ["/commitShopcart", "/pay", "/findOrder", "/receive", "/removeOrder"]),
    ("个人中心", ["/findMy", "/findAccountInfo"]),
]

by_path = {c["path"]: c for c in uniq}

L = []
A = L.append
A("# Lucky Coffee 接口契约清单")
A("")
A(f"> 来源:`{seed['meta']['source']}` / 抓取时间:`{seed['meta']['captured_at']}`")
A("> 原始文档:`API接口文档.md`")
A("")
A("## 图例")
A("")
A("| 标记 | 含义 |")
A("|---|---|")
A("| ✅ 已抓取 | 只读接口,响应样本已存档于 `raw/` |")
A("| 🔵 已使用 | 你的 HarmonyOS app 当前实际调用的接口 |")
A("| ⚪ 未使用 | 文档已定义,但 app 尚未调用(共 30 个) |")
A("| 🔒 写操作 | 会修改数据,**未调用**,仅记录契约 |")
A("")
A("## 总览")
A("")
A(f"文档定义接口总数 **{len(MODULES and uniq)}** 个;你目前只用了 **{len(USED)}** 个。")
A("")
for mod, paths in MODULES:
    exist = [p for p in paths if p in by_path]
    if not exist:
        continue
    A(f"### {mod}（{len(exist)} 个）")
    A("")
    A("| 接口 | 方法 | 参数 | 状态 |")
    A("|---|---|---|---|")
    for p in exist:
        c = by_path[p]
        marks = []
        if p in CAPTURED:
            marks.append("✅ 已抓取")
        if p in USED:
            marks.append("🔵 已使用")
        else:
            marks.append("⚪ 未使用")
        if c["method"] == "POST":
            marks.append("🔒 写操作")
        A(f"| `{p}` | {c['method']} | {c['params'] or '—'} | {' '.join(marks)} |")
    A("")

A("## 关键约定（实现时必须严格一致）")
A("")
A("1. **所有请求都要带 `appkey`**,GET 放 query,POST 放 body。")
A("2. **POST 参数格式是 `application/x-www-form-urlencoded`**（`a=1&b=2`），**不是 JSON**。")
A("   → Spring Boot 用 `@RequestParam` / `@ModelAttribute`，**不要用 `@RequestBody`**。")
A("3. **响应统一为 JSON，用自定义 `code` 判断成功**，不是 HTTP 状态码。")
A("4. **登录态通过 `tokenString` 参数传递**，不是 `Authorization` 头。")
A("")
A("### 已观测到的 code 值")
A("")
A("| 接口 | code | msg |")
A("|---|---|---|")
A("| `/register` | 100 | 注册成功（见 `Api.ets` 注释） |")
A("| `/login` | 200 | 登录成功，返回 `token`（见 `Api.ets` 注释） |")
A("| `/typeProducts` | 500 | — |")
A("| `/search` | `\"Q001\"` | 搜索商品成功 **← 注意是字符串，不是数字** |")
A("| `/productDetail` | 600 | 查询商品详情成功 |")
A("")
A("> ⚠️ `code` 的类型在不同接口间不一致（数字 / 字符串），后端复刻时必须逐一核对。")
A("")
A("### 字段命名陷阱")
A("")
A("**列表接口和详情接口的字段命名不同**,必须分别处理:")
A("")
A("| 语义 | 列表接口(`/typeProducts`) | 详情接口(`/productDetail`) |")
A("|---|---|---|")
A("| 小图 | `smallImg` | `small_img` |")
A("| 大图 | `largeImg` | `large_img` |")
A("| 热门 | `isHot` | `is_hot` |")
A("| 分类名 | `typeDesc` | `type_desc` |")
A("")
A("详情接口还**额外返回 4 个客制化维度**(列表接口没有):")
A("`tem`/`tem_desc`(温度)、`milk`/`milk_desc`(奶)、`sugar`/`sugar_desc`(糖)、`cream`/`cream_desc`(奶油)。")
A("")
A("## 已抓取的数据")
A("")
A("| 数据 | 数量 | 文件 |")
A("|---|---|---|")
A(f"| 轮播图 | {len(seed['banner'])} | `raw/banner.json` |")
A(f"| 商品分类 | {len(seed['types'])} | `raw/type.json` |")
A(f"| 商品 | {len(seed['products'])} | `raw/typeProducts-*.json`、`raw/productDetail-*.json` |")
A(f"| 搜索样本 | 4 组 | `raw/search-*.json` |")
A("")

with open(os.path.join(OUT, "接口契约.md"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(L))
print(f"OK  接口契约.md  (接口 {len(uniq)} 个)")

# ------------------------------------------------------- README.md
R = f"""# api-capture —— 教学 API 契约与数据存档

抓取时间:**{seed['meta']['captured_at']}**
来源:`{seed['meta']['source']}`(第三方教学服务器)

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
| `capture.py` | 抓取脚本(可重复执行以刷新数据) |
| `raw/` | 每个接口的**原始 JSON 响应**,未经处理 |
| `capture-summary.json` | 抓取统计 |
| `raw/_request-log.json` | 全部请求记录(接口/参数/状态码) |

## 数据规模

- 轮播图 **{len(seed['banner'])}** 条
- 商品分类 **{len(seed['types'])}** 个(latte / coffee /rena_ice / fruit_tea)
- 商品 **{len(seed['products'])}** 个,**详情全部抓到**
- 搜索样本 4 组

## 安全与合规说明

- 本目录**只调用了只读接口(GET)**,未触碰任何写操作接口,不会污染教学环境数据。
- `appkey` 是教学环境公开的共用标识,你的工程里本来就有(`entry/src/main/ets/api/Request.ets`)。
- 商品图片为原站外链,未下载到本地;若要离线,请另行抓取 `images/` 目录。

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
"""
with open(os.path.join(OUT, "README.md"), "w", encoding="utf-8", newline="\n") as f:
    f.write(R)
print("OK  README.md")

# 清理临时脚本
tmp = os.path.join(OUT, "_inspect.py")
if os.path.exists(tmp):
    os.remove(tmp)
print("\n完成。目录内容:")
for name in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, name)
    if os.path.isdir(p):
        print(f"  {name}/  ({len(os.listdir(p))} 个文件)")
    else:
        print(f"  {name}  ({os.path.getsize(p):,} bytes)")
