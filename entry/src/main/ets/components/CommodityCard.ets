import { HomeGoodsItem } from "../models/request"


@Component
export default struct CommodityCard {
  @Prop GoodsData: HomeGoodsItem;

  build() {
    //列结构
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(this.GoodsData.smallImg)
          .width("100%")
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)

        //判断是否热卖
        if (this.GoodsData.isHot === 1) {
          Text("热卖")
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(Color.Red)
            .padding({ left: 5, right: 5 })
            .borderRadius({ topRight: 8, bottomRight: 8 })
        }
      }
      .width("100%")

      Text(this.GoodsData.name)
        .fontSize(20)
        .width("100%")
        .maxLines(1)
        .textOverflow({overflow: TextOverflow.Ellipsis})

      Text(this.GoodsData.enname)
        .width("100%")
        .fontSize(15)
        .fontColor($r("app.color.grey_color"))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`$${this.GoodsData.price}`)
        .width("100%")
        .fontSize(18)
        .fontColor(Color.Red)
        .fontWeight(FontWeight.Bold)
    }
    .width("100%")
    .padding(10)
    .backgroundColor(Color.White)
  }
}