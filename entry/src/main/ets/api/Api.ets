import Request from "./Request"
import { http } from "@kit.NetworkKit";
import { LoginRequestBody, RegisterRequestBody } from "../models/request";

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

export {
  getBanner, getHomeProductList, getProductType, getProductListByType,
  registerAccount, loginAccount
}