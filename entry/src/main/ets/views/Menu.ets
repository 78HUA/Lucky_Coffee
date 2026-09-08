import { getProductType, getProductListByType } from "../api/Api"
import { SideMenu, SideMenuResponseBody, HomeGoodsItem, HomeGoodsResponseBody } from "../models/request"
import CommodityCard from "../components/CommodityCard";

@Entry
  //自定义组件
@Component
export default struct MenuPage {
  @State sideMenuList: SideMenu[] = [];
  @State select_side: number = 0;
  @State productList: HomeGoodsItem[] = [];

  async aboutToAppear() {
    let type: string = await this.getType();
    this.getListByType(type);
  }

  private async getType() {
    let type: string = "";

    await getProductType()
      .then(res => {
        console.log("类型数据", JSON.stringify(res.result));
        let temp: SideMenuResponseBody = res.result as SideMenuResponseBody;

        this.sideMenuList = temp.result;

        type = temp.result[0].type;
      })

    return type;
  }

  private getListByType(_type: string) {
    getProductListByType(_type)
      .then(res => {
        console.log("分类" + _type + "的商品有=>", JSON.stringify(res.result));
      })
  }

  build() {
    Column() {
      //1.顶部搜索栏
      Search({ placeholder: "请输入搜索关键字" })
        .margin({ left: 20, right: 20 })

      //2.页面内容
      Row() {
        //侧边栏
        Column() {
          ForEach(this.sideMenuList, (item: SideMenu, index: number) => {
            Row() {
              Text(item.typeDesc)
                .padding({ left: 20, top: 16, bottom: 16 })
                .border({
                  width: { left: 2 },
                  style: BorderStyle.Solid,
                  color: this.select_side === index ? $r("app.color.theme_blue") : Color.Transparent
                })
            }
            .width("100%")
            .padding({ top: 10, bottom: 10 })
            .background(this.select_side === index ? Color.White : Color.Transparent)
            .onClick(() => {
              if (index === this.select_side) {
                return;
              }
              this.select_side = index;
              this.getListByType(item.type)
            })
          })

        }
        .width("35%")
        .height("calc(100% - 50vp)")
        .backgroundColor($r("app.color.background_grey"))
        .alignItems(HorizontalAlign.Start)

        Scroll(){
          Column(){
            Grid() {
              ForEach(this.productList, (item: HomeGoodsItem) => {
                GridItem() {
                  CommodityCard({ GoodsData: item })
                }
              })
            }
            .width("100%")
            .columnsTemplate('1fr 1fr') //分两列，两列宽度相等
            // .rowsGap(12)
            // .columnsGap(12)
          }
          .width("65%")
          .height("100%")
          .backgroundColor(Color.White)

        }

      }


    }
    .height("100%")

  }
}