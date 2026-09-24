# Lucky Coffee · 鸿蒙咖啡点单应用

一个用 **HarmonyOS（ArkTS + ArkUI 声明式开发）** 实现的咖啡点单 App，覆盖"**从注册登录到下单结算**"的完整业务闭环，并包含个人中心、订单、收藏、地址、安全中心等模块。

> 本项目为课程实训作品：在老师提供的课程后端接口之上，独立完成**前端页面开发、接口联调与问题排查**。

---

## 一、项目概览

| 项 | 值 |
| --- | --- |
| 应用包名 | `com.example.lucky_coffee` |
| 版本 | 1.0.0 |
| 开发框架 | HarmonyOS Stage 模型 + ArkTS + ArkUI 声明式 |
| 编译 SDK | `targetSdkVersion 26.0.0`，`compatibleSdkVersion 6.1.0(23)`（**按 API 23 兼容写码**） |
| 运行设备 | phone（模拟器 / 真机） |
| 状态管理 | ArkUI V1：`@State` / `@Prop` / `@Watch` |
| 本地存储 | `@kit.ArkData` 的 Preferences |
| 网络 | `@kit.NetworkKit` 的 http |
| 第三方依赖 | **无**（仅系统 SDK 与单元测试库） |

---

## 二、功能清单

### 主流程

| 模块 | 页面 | 功能 |
| --- | --- | --- |
| 登录注册 | `pages/LoginPage` | 手机号/密码/昵称校验（抽到 `utils/validForm.ets`）、字段级红字报错、接真实接口、登录态本地持久化与自动登录 |
| 首页 | `views/Home` | 轮播图、热卖商品网格（`Grid` 两列）、搜索入口 |
| 分类 | `views/Menu` | 左侧分类栏 + 右侧商品网格、点卡片进详情 |
| 搜索 | `pages/SearchPage` | 关键词搜索、**搜索历史**（持久化、单条删除、一键清空） |
| 商品详情 | `pages/ShopDetail` | 商品详情、**规格选择**（温度/奶/糖/奶油动态生成）、数量加减、收藏、加入购物袋、购物袋数量角标 |
| 购物车 | `views/ShopBag` | 勾选、数量增减、左滑删除、编辑模式批量删除、全选与实时合计、未登录/空态兜底 |
| 订单结算 | `pages/OrderConfirm` | 待购商品清单、**选择收货地址（底部弹窗）**、订单金额汇总、立即结算下单 |
| 收货地址 | `pages/AddressList` / `pages/AddressEdit` | 地址列表、新增/编辑/删除；**省市区三列选择器**（内置真实行政区划代码） |

### 个人中心

| 模块 | 页面 | 功能 |
| --- | --- | --- |
| 我的 | `views/My` | 头像/昵称/简介、五项功能入口 |
| 个人资料 | `pages/ProfilePage` | 头像、用户 id、手机号、昵称、简介（只读） |
| 我的订单 | `pages/OrderList` | 全部 / 进行中 / 已完成三个页签、**按订单号分组**展示、确认收货、删除订单（二次确认）、空态 |
| 我的收藏 | `pages/FavoriteList` | 收藏商品两列网格、**一键取消收藏**、空态 |
| 安全中心 | `pages/SecurityCenter` | 修改密码（底部弹窗 + 明文切换）、注销账号、退出登录（均带确认弹窗） |
| 忘记密码 | `pages/ForgotPasswordPage` | 手机号 + 新密码 + 邮箱验证码、发送验证码、重置密码后回登录页 |

---

## 三、项目结构

```
Lucky_Coffee
├── AppScope/                        # 应用级配置（包名、图标、版本）
├── entry/src/main/
│   ├── ets/
│   │   ├── api/
│   │   │   ├── Request.ets          # 网络请求封装（自动附 appkey、POST 表单串序列化）
│   │   │   └── Api.ets              # 全部接口函数（34 个）
│   │   ├── components/
│   │   │   ├── CommodityCard.ets    # 商品卡片（首页/分类/搜索/收藏共用）
│   │   │   └── FormField.ets        # 公共表单行（地址表单等复用）
│   │   ├── models/request.ets       # 接口请求/响应类型定义
│   │   ├── pages/                   # 12 个 @Entry 页面
│   │   ├── views/                   # Index 的四个页签子视图
│   │   ├── utils/
│   │   │   ├── validForm.ets        # 手机号/密码/昵称/邮箱校验
│   │   │   ├── Session.ets          # 登录态本地存储（token / 手机号）
│   │   │   ├── SearchHistory.ets    # 搜索历史本地存储
│   │   │   └── RegionData.ets       # 省市区数据（含真实行政区划代码）
│   │   ├── entryability/            # UIAbility 入口
│   │   └── entrybackupability/      # 备份扩展
│   └── resources/                   # 颜色、字符串、图片等资源
├── API接口文档.md                    # 课程后端全部接口说明
└── README.md
```

---

## 四、快速开始

1. 用 **DevEco Studio** 打开本目录；
2. 首次运行需配置签名（`File → Project Structure → Signing Configs` 勾选自动签名）；
3. 选择模拟器或真机，点击 **Run**；
4. 没有账号可在登录页点「注册」自助注册（后端不校验短信验证码）。

> 命令行构建（可选）：
> ```bash
> set DEVECO_SDK_HOME=E:\DevEco Studio\sdk
> "E:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap
> ```
> 注意 `DEVECO_SDK_HOME` 必须设置，否则报 `00303217 Invalid value of 'DEVECO_SDK_HOME'`。

---

## 五、后端约定

- 接口基地址：`https://kf.webxyq.com`，全部接口需附带 `appkey`（已写在 `api/Request.ets`）。
- POST 参数必须是 `参数1=值1&参数2=值2` 的 **x-www-form-urlencoded 字符串**（不是 JSON），键值都要 `encodeURIComponent`。
- 完整接口清单见 [`API接口文档.md`](./API接口文档.md)。

### ⚠️ 成功码全表（实测整理）

同一个后端的**每个接口都有自己的成功码，且类型不统一**，判断成功时必须逐一对照，不能套用同一个值：

| 接口 | 成功码 | 接口 | 成功码 |
| --- | --- | --- | --- |
| `/register` 注册 | `100` | `/findAddress` 地址列表 | `20000` |
| `/login` 登录 | `200` | `/addAddress` 新增地址 | `9000` |
| `/banner` 轮播图 | `300` | `/editAddress` 编辑地址 | `30000` |
| `/productDetail` 商品详情 | `600` | `/deleteAddress` 删除地址 | `10000` |
| `/like` 收藏 | `800` | `/findAddressByAid` 按 id 查地址 | `40000` |
| `/notlike` 取消收藏 | `900` | `/commitShopcart` 待购商品 | `50000` |
| `/addShopcart` 加购 | `3000` | `/pay` 立即结算 | `60000` |
| `/shopcartCount` 购物车数量 | `4000` | `/findOrder` 订单列表 | `70000` |
| `/findAllShopcart` 购物车列表 | `5000` | `/receive` 确认收货 | `80000` |
| `/removeShopcart` 删除购物车 | `7000` | `/removeOrder` 删除订单 | `90000` |
| **`/search` 搜索** | **`'Q001'`（字符串）** | **`/findMy` 我的** | **`'A001'`（字符串）** |
| **`/findAccountInfo` 账号信息** | **`'B001'`（字符串）** | **`/updatePassword` 改密码** | **`'E001'`（字符串）** |
| **`/logout` 退出登录** | **`'F001'`（字符串）** | **`/destroyAccount` 注销账号** | **`'G001'`（字符串）** |
| `/retrievePassword` 找回密码 | `'L001'`（字符串） | `/checkValidCode` 验证码校验 | 错误码 `'K002'` |

常见失败码：`102` 手机号已注册、`201` 手机号未注册、`202` 手机号或密码不正确、`700` token 检验无效（需重新登录）。

---

## 六、开发笔记（踩坑与约定）

都是本项目实际踩到并解决的问题，记录在此避免重复：

**1. `ForEach` 的键值必须包含"会变化的字段"**
列表项内容变化但键值不变时，ArkUI 会**复用旧组件**、不重跑渲染函数，表现为"数据变了但界面不刷新"。
例：购物车行若只用 `sid` 做键值，点 `+` 后行内数量不变（而底部合计却会变）。正确做法是键值里带上会变的字段：

```ts
}, (row: CartRow) => `${row.sid}_${row.count}_${row.selected ? 1 : 0}`)
```

**2. GET 参数里的数字 `0` 会被丢掉**
GET 的参数是交给 http 模块拼进 URL 的，它会跳过"假值"。`/findOrder` 的 `status=0`（全部）直接传数字会被丢弃，而后端在缺少该参数时返回**成功码 + 空列表**，界面就误显示"没有订单数据"。解决：传字符串 `String(status)`。

**3. V1 的状态只观测第一层**
`@State` 数组里改对象内部字段（如 `arr[i].count = 1`）不会触发刷新，需要"**整项替换 + 数组整体重新赋值**"。

**4. `@Builder` 的参数是"值快照"**
需要跟随父组件状态刷新的列表行/交互控件，要用 `@Component` + `@Prop`，不能用 `@Builder`。

**5. ArkUI 保留名**
`isDeleting`、`tabIndex` 等名字不能用作 `@Component` 的成员名，会直接编译报错，需改名（如 `isRemoving`、`currentTab`）。

**6. 部分 API 有版本门槛**
`Circle` 的 `fill` / `stroke` 需要 SDK 26，本项目按 API 23 兼容，因此圆形勾选/加减按钮统一用"**圆角 Text + border**"实现。

---

## 七、说明

- 本项目为课程实训作品，后端接口与 `appkey` 由课程提供，仅用于教学与练习。
- 项目按"**先实测、再写码**"的方式开发：接口的成功码、参数格式与返回字段均逐个实测确认，并记录在代码注释中。
