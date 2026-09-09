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