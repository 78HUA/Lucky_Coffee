//轮播图
export interface BannerItem {
  bannerImg: string;
  name: string;
  pid: string;
}

export  interface  BannerResponseBody{
  result: BannerItem[]
}

//首页商品列表
export interface HomeGoodsItem {
  createdAt: string;
  desc: string;
  enname: string;
  id: number;
  isHot: number;
  largeImg: string;
  name: string;
  pid: string;
  price: string;
  smallImg: string;
  type: string;
  typeDesc: string;
  updatedAt: string;
}

export  interface HomeGoodsResponseBody{
  result: HomeGoodsItem[]
}

//商品的分类
export interface  SideMenuResponseBody{
  code: number;
  result: SideMenu[];
}

export interface SideMenu {
  createdAt: string;
  id: number;
  type: string;
  typeDesc: string;
  updatedAt: string;
}

// ===== 账号：注册 / 登录（对应 API接口文档.md） =====

// 注册请求参数（appkey 由 Request 统一附加）
export interface RegisterRequestBody {
  nickName: string;
  phone: string;
  password: string;
}

// 登录请求参数
export interface LoginRequestBody {
  phone: string;
  password: string;
}

// 账号类接口通用响应（实测：注册成功 code=100；登录成功 code=200；失败返回 code!=成功码 并携带 msg）
export interface AccountResponseBody {
  code: number;
  msg: string;
}

// 登录成功响应：额外携带 token（token 字段实测来自后端 /login）
export interface LoginResponseBody {
  code: number;
  msg: string;
  token: string;
}

// ===== 商品详情（/productDetail） =====

// 注意：这个接口后端返回的是 snake_case 字段（small_img / is_hot / tem_desc ...），
// 而 /typeProducts 返回的是 camelCase（smallImg / isHot / typeDesc），同一个后端两套命名，
// 所以这里的字段名必须按后端原样写，不要改成驼峰。
// 另外规格字段有个坑：选项字段可能是空字符串（如某商品的 milk 为 ""），
// 但它的 *_desc 仍然有值，取值时要判断"非空才算一组规格"。
export interface ProductDetailItem {
  pid: string;
  type: string;
  type_desc: string;
  name: string;
  enname: string;
  desc: string;
  price: string;
  small_img: string;
  large_img: string;
  is_hot: number;
  // 规格：值是用 "/" 分隔的选项（可能为空串），*_desc 是这组规格的名字（如"温度"）
  tem: string;
  tem_desc: string;
  milk: string;
  milk_desc: string;
  sugar: string;
  sugar_desc: string;
  cream: string;
  cream_desc: string;
}

// 商品详情响应（实测：成功码 code=600，且 result 是数组，要取 [0]）
export interface ProductDetailResponseBody {
  code: number;
  result: ProductDetailItem[];
}

// ===== 收藏（/findlike、/like、/notlike） =====

// 收藏状态响应：result 是"已收藏的商品"数组，长度 > 0 表示这个商品已被收藏。
// 未收藏时后端可能给空数组、也可能给 null，所以声明成可选，取值时用 ?? [] 兜底。
export interface FavoriteStatusResponseBody {
  code: number;
  msg?: string;
  result?: Object[];
}

// 收藏 / 取消收藏响应（成功码：800 = 已收藏，900 = 已取消收藏）
export interface FavoriteResponseBody {
  code: number;
  msg?: string;
}

// 收藏列表响应（/findAllLike，成功码 2000）
// 实测：result 是**商品数组**且字段与首页商品（HomeGoodsItem）完全一致 →
// 收藏页可以直接把它喂给 CommodityCard，不需要另外映射
export interface FavoriteListResponseBody {
  code: number;
  msg?: string;
  result?: HomeGoodsItem[];
  userId?: string;
}

// ===== 购物车（/addShopcart、/shopcartCount） =====

// 加入购物车的请求参数
export interface SaveShopCartProduct {
  pid: string;
  count: number;
  rule: string; // 规格，如 "冷/全糖/默认奶油"（各规格的选中值按 温度→奶→糖→奶油 的顺序用 / 连接）
  tokenString: string;
}

// 加入购物车响应（成功码 3000；status/sid 后端也返回，暂时用不到）
export interface AddShopCartResponseBody {
  code: number;
  msg?: string;
  status?: number;
  sid?: string;
}

// 购物车数量响应（成功码 4000；result 是数量，没登录或空车时可能是 null）
export interface ShopCartCountResponseBody {
  code: number;
  msg?: string;
  result?: number;
}

// ===== 购物车列表（/findAllShopcart、/removeShopcart） =====

// 购物车条目（注意：snake_case 字段；定位用 sid（条目 id），不是商品 pid）
export interface CartItem {
  sid: string;
  pid: string;
  name: string;
  enname: string;
  desc: string;
  price: string; // 后端是字符串
  small_img: string;
  rule: string; // 加购时拼的规格，如 "冷/全糖/默认奶油"
  count: number;
  status: number;
  is_remove: number;
}

// 查询购物车列表响应（成功码 5000）
export interface CartListResponseBody {
  code: number;
  msg?: string;
  result: CartItem[];
}

// 删除购物车响应（成功码 7000；/removeShopcart 是逻辑删除，数据还在库里只是查不到）
export interface CartOpResponseBody {
  code: number;
  msg?: string;
}

// ===== 个人资料（/findMy、/findAccountInfo） =====
// 字段名与返回结构均为 2026-09-23 测试账号实测：
//   - 两个接口的成功码都是**字符串**（'A001' / 'B001'）
//   - 两个接口的 result 都是**数组**（取 [0]）
//   - 头像字段叫 userImg、背景叫 userBg（不是 avatar/bg）
//   - userId 和 phone 只在 /findAccountInfo 里有 → 个人资料页用后者

// /findMy 返回的个人信息（首页"我的"页用）
export interface MyInfoItem {
  nickName?: string;
  userImg?: string;
  userBg?: string;
  desc?: string;
  vip?: number;
}

export interface MyInfoResponseBody {
  code: string;
  msg?: string;
  result?: MyInfoItem[];
}

// /findAccountInfo 返回的账号信息（个人资料页用，字段最全）
export interface AccountInfoItem {
  userId?: string;
  phone?: string;
  nickName?: string;
  userImg?: string;
  desc?: string;
  vip?: number;
}

export interface AccountInfoResponseBody {
  code: string;
  msg?: string;
  result?: AccountInfoItem[];
}

// ===== 订单（/findOrder、/receive、/removeOrder） =====

// 一条订单记录 —— 注意：**每件商品一条记录**，同一个订单的多件商品 oid 相同，
// 所以订单列表页要按 oid 分组成"一个订单一张卡片"。
// 实测字段（camelCase）
export interface OrderRecord {
  id: number;
  oid: string; // 订单编号，如 NO1790093522501
  pid: string;
  price: string;
  smallImg: string;
  name: string;
  enname: string;
  count: number;
  rule: string;
  userId: string;
  status: number; // 1 = 进行中，2 = 已完成
  isRemove: number;
  address: string;
  phone: string;
  receiver: string;
  createdAt: string; // UTC 时间，形如 2026-09-22T16:12:02.000Z
  updatedAt: string;
}

// 查订单响应（成功码 70000；status 过滤：0 全部、1 进行中、2 已完成）
export interface OrderListResponseBody {
  code: number;
  msg?: string;
  result?: OrderRecord[];
}

// 订单操作响应（/receive 成功码 80000、/removeOrder 成功码 90000）
export interface OrderOpResponseBody {
  code: number;
  msg?: string;
}

// ===== 安全中心（/updatePassword、/logout、/destroyAccount） =====
// 实测（2026-09-23）：这三个接口的成功码都是**字符串** ——
//   /updatePassword = 'E001'（改密码后旧密码立刻失效，新密码可登录）
//   /logout         = 'F001'（退出后旧 token 立刻失效）
//   /destroyAccount = 'G001'
export interface SecurityOpResponseBody {
  code: string;
  msg?: string;
}

// ===== 搜索商品（/search） =====

// 实测：参数名是 name；成功码是**字符串** 'Q001'（这个后端连 code 的类型都不统一，
// 首页/详情那些是数字，这里是字符串，比较时别写错类型）；
// result 是商品数组，字段与首页商品（HomeGoodsItem）完全一致。
export interface SearchResponseBody {
  code: string;
  result: HomeGoodsItem[];
}

// ===== 收货地址（/findAddress、/addAddress、/editAddress、/deleteAddress、/findAddressByAid） =====
// 字段名全部来自 2026-09-23 的测试账号实测

// 一条收货地址
export interface AddressItem {
  id: number;
  aid: string; // 地址唯一标识，形如 "_address1790093075454"
  userId: string;
  name: string;
  tel: string;
  province: string;
  city: string;
  county: string;
  addressDetail: string;
  areaCode: string; // 行政区划代码（实测非必填，可传空串）
  postalCode: string; // 实测非必填
  isDefault: number; // 1 = 默认地址，0 = 非默认
  isRemove: number;
  createdAt: string;
  updatedAt: string;
}

// 查地址响应：/findAddress 成功码 20000、/findAddressByAid 成功码 40000，
// 两者 result 都是**数组**（按 aid 查也返回数组，要取 [0]）
export interface AddressListResponseBody {
  code: number;
  msg?: string;
  result?: AddressItem[];
}

// 新增地址请求（成功码 9000；areaCode / postalCode 实测可省）
export interface AddAddressBody {
  tokenString: string;
  name: string;
  tel: string;
  province: string;
  city: string;
  county: string;
  addressDetail: string;
  areaCode: string;
  postalCode: string;
  isDefault: number;
}

// 编辑地址请求（成功码 30000）
export interface EditAddressBody {
  tokenString: string;
  aid: string;
  name: string;
  tel: string;
  province: string;
  city: string;
  county: string;
  addressDetail: string;
  areaCode: string;
  postalCode: string;
  isDefault: number;
}

// 地址新增/编辑/删除的通用响应（9000 / 30000 / 10000）
export interface AddressOpResponseBody {
  code: number;
  msg?: string;
}

// ===== 结算下单（/commitShopcart、/pay） =====

// 待购商品：/commitShopcart 返回（成功码 50000）。
// 实测它直接带 sid / rule / count，所以订单结算页不需要另传购物车快照。
// 注意字段是 snake_case 混 camelCase（enname 是驼峰、small_img 是下划线），按后端原样写。
export interface OrderItem {
  sid: string;
  pid: string;
  name: string;
  enname: string;
  price: string; // 字符串
  rule: string; // 规格，如 "冷/全糖"
  count: number;
  small_img: string;
  large_img: string;
  type: string;
  type_desc: string;
  is_hot: number;
  desc: string;
  user_id: string;
  status: number;
  is_remove: number;
  created_at: string;
  updated_at: string;
}

export interface OrderItemsResponseBody {
  code: number;
  msg?: string;
  result?: OrderItem[];
}

// 下单请求（/pay，成功码 60000；sids 要 JSON 数组串）
export interface PayBody {
  tokenString: string;
  sids: string;
  phone: string;
  address: string;
  receiver: string;
}

export interface PayResponseBody {
  code: number;
  msg?: string;
}