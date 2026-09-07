import Request from "./Request"
import { http } from "@kit.NetworkKit";

interface BannerItem{
  bannerImg: string;
  name: string;
  pid: string;
}

interface BannerResponseBody{
  result: BannerItem[]
}

interface GoodsItem{
  pid: string;
  name: string;
  enname: string;
  price: string;
  smallImg: string;
  largeImg: string;
  isHot: number;
  type: string;
  desc: string;
}

interface GoodsResponseBody{
  result: GoodsItem[]
}


//发起网络请求
let getBanner = ():Promise<http.HttpResponse> => {
  return Request("/banner")
}

let getHotGoods = (): Promise<http.HttpResponse> => {
  const params: Record<string, string> = {
    "key": "isHot",
    "value": "1"
  }
  return Request("/typeProducts","GET",params);
}

export {
  getBanner,
  getHotGoods
}
export type {BannerItem, BannerResponseBody,GoodsItem,GoodsResponseBody}