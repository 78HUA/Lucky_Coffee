//轮播图
export interface BannerItem {
  bannerImg: string;
  name: string;
  pid: string;
}

// export  interface  BannerResponseBody{
//   result: BannerItem[]
// }

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

// export  interface HomeGoodsResponseBody{
//   result: HomeGoodsItem[]
// }

//商品的分类
// export interface  {
//   code: number;
//   result: Result[];
// }

export interface SideMenu {
  createdAt: string;
  id: number;
  type: string;
  typeDesc: string;
  updatedAt: string;
}