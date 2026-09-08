import { getBanner, getHomeProductList } from "../api/Api";
import { HomeGoodsItem, BannerItem } from "../models/request"
import Goods from "../components/CommodityCard"

@Component
export default struct Home {
  //定义商品数组
  @State goodsList: HomeGoodsItem[] = [];
  //定义轮播图数组
  @State bannerList: BannerItem[] = [];

  //初始化数据
  aboutToAppear(): void {
    //调用数据接口
    this.getBannerList();
    this.getGoodsList();
  }

  private getBannerList() {
    console.log("请求轮播图")
    getBanner()
      .then(res => {
        console.log("轮播图数据", JSON.stringify(res.result));
        this.bannerList = Object(res.result).result;
      })
  }

  private getGoodsList() {
    console.log("请求商品数据")
    getHomeProductList()
      .then(res => {
        console.log("商品数据", JSON.stringify(res.result));
        this.goodsList = Object(res.result).result;
      })
  }

  build() {
    //最外层容器结构，纵向排列
    Column() {
      //顶部导航，横向结构
      Row() {
        //左侧文本
        Row({ space: 10 }) {
          Text("你好")

          Text("登录")
            .fontWeight(FontWeight.Bold)
        }
        .layoutWeight(1)

        //右侧导航栏
        Search({
          placeholder: "请输入搜索关键词"
        })
          .layoutWeight(2)
      }
      .width("100%")
      .backgroundColor(Color.White)
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })

      //滚动视图容器(高度=父组件高度的100%,减去顶部导航不滚动部分的高度)
      Scroll() {
        //只支持单一子节点
        Column() {
          //第二层 轮播图
          Swiper() {
            ForEach(this.bannerList, (item: BannerItem) => {
              Image(item.bannerImg)
                .width("100%")
                .height(250)
                .objectFit(ImageFit.Cover)
            })
          }
          .width("100%")
          .autoPlay(true)
          .margin({ left: 16, right: 16, bottom: 12 })
          .indicator(
            Indicator.dot()
              .selectedColor($r("app.color.theme_blue"))
              .color($r("app.color.grey_color"))
              .right(20)
          )

          //第三层 商品列表 grid网格结构
          Grid() {
            //商品内容遍历
            ForEach(this.goodsList, (item: HomeGoodsItem) => {
              GridItem() {
                Goods({ GoodsData: item })
              }
            })

          }
          .width("100%")
          .columnsTemplate('1fr 1fr') //分两列，两列宽度相等
          .rowsGap(12)
          .columnsGap(12)
        }
      }
      .height("calc(100% - 80vp)")
    }
    .backgroundColor($r("app.color.background_grey")) //淡灰色背景
    //宽高铺满整个屏幕
    .height("100%")
    .width("100%")
  }
}
