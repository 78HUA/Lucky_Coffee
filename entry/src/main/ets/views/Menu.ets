import { getProductType,getProductListByType } from "../api/Api"
import { SideMenu } from "../models/request"


//自定义组件
@Entry
@Component
export default struct MenuPage {
  @State sideMenuList: SideMenu[] = [];
  @State select_side: number = 0;

  private getType() {
    getProductType()
      .then(res => {
        console.log("类型数据", JSON.stringify(res.result));

      })
  }

  private  getListByType(_type:string){
    getProductListByType(_type)
      .then(res => {
        console.log("分类"+_type+"的商品有=>",JSON.stringify(res.result));
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
          Row() {
            Text("热卖推荐").padding({ left: 20, top: 20, bottom: 20 })
              .border({ width: { left: 2 }, style: BorderStyle.Solid, color: $r("app.color.theme_blue") })
            Text("热卖推荐").padding({ left: 20, top: 20, bottom: 20 })
            Text("热卖推荐").padding({ left: 20, top: 20, bottom: 20 })
          }
          .width("100%")
          .padding({ top: 10, bottom: 10 })
          .background(Color.White)
        }
        .width("35%")
        .height("100%")
        .background($r("app.color.grey_color"))
        .alignItems(HorizontalAlign.Start)

        Grid() {
          GridItem() {

          }
        }
        .width("65%")
        .height("100%")
        .backgroundColor(Color.Red)
      }
    }
    .height("100%")

  }
}