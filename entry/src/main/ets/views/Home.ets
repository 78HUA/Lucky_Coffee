import { getBanner, BannerItem, BannerResponseBody, getHotGoods,GoodsItem,GoodsResponseBody } from "../api/Api";

//自定义组件
// interface GoodsItem {
//   name: string;
//   engName: string;
//   price: number;
//   image: Resource;
//   isHot: boolean;
// }

@Component
export default struct  Home {
  //初始化数据
  aboutToAppear(): void {
  //调用数据接口
    this.getBannerList();
    this.getGoodsList();
  }
  //定义商品数组
  @State goodsList: GoodsItem[] = [];
  // @State goodsList: GoodsItem[] = [
  //   {name:"焦糖拿铁", engName:"Caramel Latte", price: 28, image:$r("app.media.coffee1"), isHot:true},
  //   {name:"榛果拿铁", engName:"Hazelnut Latte", price: 30, image:$r("app.media.coffee2"), isHot:true},
  //   {name:"冰美式", engName:"IceAmerica", price: 6.6, image:$r("app.media.coffee3"), isHot:false},
  //   {name:"卡布奇诺", engName:"Kabuchino", price: 10, image:$r("app.media.coffee4"), isHot:true},
  // ]

  @State bannerList: BannerItem[] = [];

  private getBannerList(){
    console.log("请求轮播图")
    getBanner()
      .then(res => {
        console.log("轮播图数据", JSON.stringify(res.result));
        const data = res.result as BannerResponseBody;
        this.bannerList = data.result;
      })
  }

  private getGoodsList(){
    console.log("请求商品数据")
    getHotGoods()
      .then(res => {
        console.log("商品数据", JSON.stringify(res.result));
        const data = res.result as GoodsResponseBody;
        this.goodsList = data.result;
      })
      .catch((err:Error) => {
        console.error("商品请求失败",err.message);
      })
  }
  // //定义轮播图数组
  // private bannerList: Resource[] = [
  //   $r("app.media.coffee1"),
  //   $r("app.media.coffee2"),
  //   $r("app.media.coffee3"),
  //   $r("app.media.coffee4")
  // ]

  build() {
    //最外层容器结构，纵向排列
    Column(){
      //顶部导航，横向结构
      Row(){
        //左侧文本
        Row({space: 10}){
          Text("你好")

          Text("登录")
            .fontWeight(FontWeight.Bold)
        }
        .layoutWeight(1)
        //右侧导航栏
        Search({
          placeholder:"请输入搜索关键词"
        })
          .layoutWeight(2)
      }
      .width("100%")
      .backgroundColor(Color.White)
      .padding({left: 16, right: 16, top: 12, bottom:12})

      //第二层 轮播图
      Swiper(){
        ForEach(this.bannerList, (item: BannerItem) => {
          Image(item.bannerImg)
            .width("100%")
            .height(250)
            .objectFit(ImageFit.Cover)
        })
        // Image($r("app.media.home"))
        //   .width("100%")
        //   .height(250)
        // Image($r("app.media.home_active"))
        //   .width("100%")
        //   .height(250)
      }
      .width("100%")
      .autoPlay(true)
      .margin({left: 16, right: 16, bottom:12})

      //第三层 商品列表 grid结构
      Grid(){
        //商品内容
        ForEach(this.goodsList, (item: GoodsItem) => {
          GridItem(){
            //列结构
            Column({space: 6}){
              Stack({alignContent: Alignment.TopEnd}){
                Image(item.smallImg)
                  .width("100%")
                  .aspectRatio(1)
                  .objectFit(ImageFit.Cover)

                //判断是否热卖
                if (item.isHot === 1) {
                  Text("热卖")
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor(Color.Red)
                    .padding({left:5,right:5})
                    .borderRadius({topRight:8,bottomRight:8})
                }
              }
              .width("100%")

              Text(item.name)
                .fontSize(20)
                .width("100%")

              Text(item.enname)
                .width("100%")
                .fontSize(15)

              Text(`$${item.price}`)
                .width("100%")
                .fontSize(18)
                .fontColor(Color.Red)
                .fontWeight(FontWeight.Bold)
            }
            .width("100%")
            .padding(10)
            .backgroundColor(Color.White)
          }
        })

      }
      .width("100%")
      .columnsTemplate('1fr 1fr')//分两列，两列宽度相等
      .layoutWeight(1)
      .rowsGap(12)
      .columnsGap(12)
    }
    .backgroundColor("#F8F8F8")//淡灰色背景
    //宽高铺满整个屏幕
    .height("100%")
    .width("100%")
  }
}