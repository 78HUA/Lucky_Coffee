import Home from "../views/Home"
import MenuPage from "../views/Menu"
import ShopBag from "../views/ShopBag"
import My from "../views/My"


@Entry
@Component
struct Index {
  // 当前选中页签索引，驱动图片和文字同时刷新
  //@state定义状态变量：数据变化的同时，视图也会更新
  //currentIndx: number = 0; 数据变化，视图不会更新
  @State currentIndex: number = 0;
  // 每次从别的页面回到本页就 +1，传给购物车页触发刷新（下完单回来能立刻看到变化）
  @State cartTick: number = 0;

  // 从别的页面（详情/搜索/订单结算…）返回时触发
  onPageShow(): void {
    this.cartTick++;
  }

  // 别的页面跳过来时可以指定要显示哪个页签
  // （详情页点"购物袋"会带着 selectedIndex = 2 跳过来，直接停在购物车页签）
  aboutToAppear(): void {
    const params: Record<string, number> | undefined =
      this.getUIContext().getRouter().getParams() as Record<string, number> | undefined;
    const target: number | undefined = params?.selectedIndex;
    if (target !== undefined) {
      this.currentIndex = target;
    }
  }

  //Builder装饰器
  @Builder
  TabItem(index: number, normalRes: Resource, activeRes: Resource, label: string) {
    Column({ space: 4 }) { // space: 图片和文字的间距
      // 图片：选中/未选中切换
      Image(this.currentIndex === index ? activeRes : normalRes)
        .width(24)
        .height(24)

      // 文字：选中/未选中切换颜色
      Text(label)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? $r("app.color.theme_blue") : $r("app.color.grey_color"))
    }
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.currentIndex
    }) {
      // 1. 首页
      TabContent() {
        Home()
      }
      .tabBar(this.TabItem(0, $r('app.media.home'), $r('app.media.home_active'), '首页'))

      // 2. 分类
      TabContent() {
        MenuPage()
      }
      .tabBar(this.TabItem(1, $r('app.media.menu'), $r('app.media.menu_active'), '分类'))

      // 3. 购物车
      TabContent() {
        ShopBag({ activeIndex: this.currentIndex, cartTick: this.cartTick, onGoHome: () => {
          // 购物车页顶栏点"< 返回"：切回首页页签
          this.currentIndex = 0;
        } })
      }
      .tabBar(this.TabItem(2, $r('app.media.shopbag'), $r('app.media.shopbag_active'), '购物车'))

      // 4. 我的
      TabContent() {
        My()
      }
      .tabBar(this.TabItem(3, $r('app.media.my'), $r('app.media.my_active'), '我的'))
    }
    // 切换页签时更新状态，触发图片+文字同时刷新
    .onChange((index: number) => {
      console.log(String(index))
      this.currentIndex = index;
    })
  }
}
