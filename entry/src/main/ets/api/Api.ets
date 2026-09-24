import Request from "./Request"
import { http } from "@kit.NetworkKit";
import {
  LoginRequestBody, RegisterRequestBody, SaveShopCartProduct,
  AddAddressBody, EditAddressBody, PayBody
} from "../models/request";

//发起网络请求
let getBanner = (): Promise<http.HttpResponse> => {
  return Request("/banner")
}
//获取热门商品列表
let getHomeProductList = (): Promise<http.HttpResponse> => {
  return Request("/typeProducts", "GET", Object({
    key: "isHot",
    value: "1"
  }))
}

// let getHotGoods = (): Promise<http.HttpResponse> => {
//   const params: Record<string, string> = {
//     "key": "isHot",
//     "value": "1"
//   }
//   return Request("/typeProducts","GET",params);
// }

//拉取商品分类
let getProductType = (): Promise<http.HttpResponse> => {
  return Request("/type", "GET");
}
//通过分类拉取商品列表
/**
 *
 * @param value 要获取商品的分类
 * @returns Promise<http.HttpResponse>
 */
let getProductListByType = (value: string): Promise<http.HttpResponse> => {
  return Request("/typeProducts", "GET", Object({
    key: "type",
    value
  }));
}

//注册账号（实测成功码 code=100）
let registerAccount = (data: RegisterRequestBody): Promise<http.HttpResponse> => {
  return Request("/register", "POST", data);
}

//登录账号（实测成功码 code=200，返回体携带 token）
let loginAccount = (data: LoginRequestBody): Promise<http.HttpResponse> => {
  return Request("/login", "POST", data);
}

//查询商品详情（实测成功码 code=600，result 是数组）
/**
 *
 * @param pid 商品 id
 * @returns Promise<http.HttpResponse>
 */
let getProductDetail = (pid: string): Promise<http.HttpResponse> => {
  return Request("/productDetail", "GET", Object({
    pid: pid
  }));
}

//查询某商品是否已收藏（tokenString 就是登录返回的 token）
let getFavoriteStatus = (pid: string, tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findlike", "GET", Object({
    pid: pid,
    tokenString: tokenString
  }));
}

//收藏商品（成功码 800）
let likeProduct = (pid: string, tokenString: string): Promise<http.HttpResponse> => {
  return Request("/like", "POST", Object({
    pid: pid,
    tokenString: tokenString
  }));
}

//取消收藏（成功码 900）
let unlikeProduct = (pid: string, tokenString: string): Promise<http.HttpResponse> => {
  return Request("/notlike", "POST", Object({
    pid: pid,
    tokenString: tokenString
  }));
}

//查询用户所有收藏商品（成功码 2000，result 是商品数组，字段与首页商品一致）
let findAllLike = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findAllLike", "GET", Object({
    tokenString: tokenString
  }));
}

//加入购物车（成功码 3000）
let saveToShopCart = (data: SaveShopCartProduct): Promise<http.HttpResponse> => {
  return Request("/addShopcart", "POST", data);
}

//查询购物车里的商品总数量（成功码 4000）
let fetchShopCartCount = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/shopcartCount", "GET", Object({
    tokenString: tokenString
  }));
}

//查询购物车所有商品（成功码 5000）
let fetchAllShopcart = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findAllShopcart", "GET", Object({
    tokenString: tokenString
  }));
}

//删除购物车商品，支持一个或多个（逻辑删除，成功码 7000）
//注意：sids 必须是 JSON 数组字符串，如 '["s1","s2"]'（后端要求 JSON.stringify 后的形态）
let removeShopcart = (tokenString: string, sids: string[]): Promise<http.HttpResponse> => {
  return Request("/removeShopcart", "POST", Object({
    tokenString: tokenString,
    sids: JSON.stringify(sids)
  }));
}

//查询个人资料（/findMy：成功码是字符串 'A001'，result 是数组，头像字段叫 userImg）
let getMyInfo = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findMy", "GET", Object({
    tokenString: tokenString
  }));
}

//查询账号信息（/findAccountInfo：成功码是字符串 'B001'，result 是数组，比 /findMy 多了 userId 和 phone）
let getAccountInfo = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findAccountInfo", "GET", Object({
    tokenString: tokenString
  }));
}

// ===== 订单（成功码均为 2026-09-23 测试账号实测） =====

//查询订单（成功码 70000；status：0 全部、1 进行中、2 已完成）
//⚠️ status 一定要转成字符串再传：
//   GET 的参数是交给 http 模块拼进 URL 的，它会跳过"假值"——直接传数字 0 会被丢掉；
//   而参数一旦缺失，后端返回的是"成功码 + 空列表"，界面就成了"没有订单数据"（2026-09-24 实测确认）
let findOrder = (tokenString: string, status: number): Promise<http.HttpResponse> => {
  return Request("/findOrder", "GET", Object({
    tokenString: tokenString,
    status: String(status)
  }));
}

//确认收货（成功码 80000；收货后订单从"进行中"变"已完成"）
let receiveOrder = (tokenString: string, oid: string): Promise<http.HttpResponse> => {
  return Request("/receive", "POST", Object({
    tokenString: tokenString,
    oid: oid
  }));
}

//删除订单（成功码 90000）
let removeOrder = (tokenString: string, oid: string): Promise<http.HttpResponse> => {
  return Request("/removeOrder", "POST", Object({
    tokenString: tokenString,
    oid: oid
  }));
}

// ===== 安全中心（成功码均为字符串，2026-09-23 测试账号实测） =====

//修改密码（成功码 'E001'；改完旧密码立刻失效，需要用新密码重新登录）
/**
 *
 * @param tokenString 登录 token
 * @param password 新密码
 * @param oldPassword 旧密码
 * @returns Promise<http.HttpResponse>
 */
let updatePassword = (tokenString: string, password: string,
  oldPassword: string): Promise<http.HttpResponse> => {
  return Request("/updatePassword", "POST", Object({
    tokenString: tokenString,
    password: password,
    oldPassword: oldPassword
  }));
}

//退出登录（成功码 'F001'；退出后旧 token 立刻失效）
let logout = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/logout", "POST", Object({
    tokenString: tokenString
  }));
}

//注销账号（成功码 'G001'，不可恢复）
let destroyAccount = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/destroyAccount", "POST", Object({
    tokenString: tokenString
  }));
}

// ===== 忘记密码（成功码均为字符串，2026-09-23 测试账号实测） =====

//获取邮箱验证码（实测：发送失败 = "J002"；成功码未观测到，页面按"不是 J002 就算发出去了"处理）
let sendEmailValidCode = (email: string): Promise<http.HttpResponse> => {
  return Request("/emailValidCode", "POST", Object({
    email: email
  }));
}

//校验邮箱验证码（实测：验证码不正确 = "K002"）
let checkValidCode = (validCode: string): Promise<http.HttpResponse> => {
  return Request("/checkValidCode", "POST", Object({
    validCode: validCode
  }));
}

//找回密码 / 重置密码（成功码 'L001'；实测**不需要先过验证码**，直接调也能重置成功）
let retrievePassword = (phone: string, password: string): Promise<http.HttpResponse> => {
  return Request("/retrievePassword", "POST", Object({
    phone: phone,
    password: password
  }));
}

//搜索商品（实测：参数名是 name；成功码是字符串 'Q001'）
let searchProducts = (name: string): Promise<http.HttpResponse> => {
  return Request("/search", "GET", Object({
    name: name
  }));
}

// ===== 收货地址（成功码均为 2026-09-23 测试账号实测） =====

//查询收货地址（成功码 20000，result 是地址数组）
let findAddress = (tokenString: string): Promise<http.HttpResponse> => {
  return Request("/findAddress", "GET", Object({
    tokenString: tokenString
  }));
}

//按 aid 查单条地址（成功码 40000，注意 result 也是数组，要取 [0]）
let findAddressByAid = (tokenString: string, aid: string): Promise<http.HttpResponse> => {
  return Request("/findAddressByAid", "GET", Object({
    tokenString: tokenString,
    aid: aid
  }));
}

//新增收货地址（成功码 9000；areaCode / postalCode 实测可省）
let addAddress = (data: AddAddressBody): Promise<http.HttpResponse> => {
  return Request("/addAddress", "POST", data);
}

//编辑收货地址（成功码 30000）
let editAddress = (data: EditAddressBody): Promise<http.HttpResponse> => {
  return Request("/editAddress", "POST", data);
}

//删除收货地址（成功码 10000）
let deleteAddress = (tokenString: string, aid: string): Promise<http.HttpResponse> => {
  return Request("/deleteAddress", "POST", Object({
    tokenString: tokenString,
    aid: aid
  }));
}

// ===== 结算下单 =====

//查询待购商品（成功码 50000；sids 要 JSON 数组串，返回里带 sid/rule/count 可直接渲染）
let commitShopcart = (tokenString: string, sids: string[]): Promise<http.HttpResponse> => {
  return Request("/commitShopcart", "GET", Object({
    tokenString: tokenString,
    sids: JSON.stringify(sids)
  }));
}

//下单结算（成功码 60000，会真的创建订单）
let payOrder = (data: PayBody): Promise<http.HttpResponse> => {
  return Request("/pay", "POST", data);
}

export {
  getBanner, getHomeProductList, getProductType, getProductListByType,
  registerAccount, loginAccount,
  getProductDetail, getFavoriteStatus, likeProduct, unlikeProduct, findAllLike,
  saveToShopCart, fetchShopCartCount,
  fetchAllShopcart, removeShopcart,
  getMyInfo, getAccountInfo,
  searchProducts,
  findAddress, findAddressByAid, addAddress, editAddress, deleteAddress,
  commitShopcart, payOrder,
  findOrder, receiveOrder, removeOrder,
  updatePassword, logout, destroyAccount,
  sendEmailValidCode, checkValidCode, retrievePassword
}