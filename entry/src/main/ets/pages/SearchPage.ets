// 搜索页
// 数据来源：/search（实测：参数名是 name；成功码是**字符串** 'Q001'；返回字段与首页商品一致）
// 版式参考课程验收图「2.搜索页」：顶栏（返回 + 搜索框 + 取消）+ 搜索历史标签 + 结果两列网格
import { common } from '@kit.AbilityKit';
import { searchProducts } from '../api/Api';
import { HomeGoodsItem, SearchResponseBody } from '../models/request';
import {
  loadSearchHistory, addSearchHistory, removeSearchHistory, clearSearchHistory
} from '../utils/SearchHistory';
import Goods from '../components/CommodityCard';

// 搜索成功的码是字符串，别写成数字
const CODE_SEARCH_OK: string = 'Q001';
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct SearchPage {
  // 输入框里的关键字
  @State keyword: string = '';
  // 搜索历史
  @State history: string[] = [];
  // 搜索结果
  @State results: HomeGoodsItem[] = [];
  // 是否正在搜索
  @State isSearching: boolean = false;
  // 是否搜过（搜过才显示"结果区/没找到"）
  @State hasSearched: boolean = false;

  // 获取宿主 UIAbility 的上下文（Preferences 读写需要）
  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  // 弹出轻提示
  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`showToast failed, err=${JSON.stringify(err)}`);
    }
  }

  // 返回（"返回"和"取消"都走这里）
  private back(): void {
    this.getUIContext().getRouter().back();
  }

  aboutToAppear(): void {
    loadSearchHistory(this.hostContext()).then((list: string[]) => {
      this.history = list;
    });
  }

  // 执行搜索
  private doSearch(keyword: string): void {
    const kw: string = keyword.trim();
    if (kw.length === 0) {
      this.toast('请输入搜索关键字');
      return;
    }
    this.keyword = kw;
    this.isSearching = true;
    this.hasSearched = true;
    searchProducts(kw)
      .then((res) => {
        const body: SearchResponseBody = res.result as SearchResponseBody;
        // 注意：这个接口的成功码是字符串 'Q001'
        if (body.code === CODE_SEARCH_OK) {
          this.results = body.result ?? [];
          // 搜过就记进历史（没结果也记，方便下次重搜）
          addSearchHistory(this.hostContext(), kw).then((list: string[]) => {
            this.history = list;
          });
        } else {
          this.toast('搜索失败，请稍后重试');
        }
      })
      .catch((err: Error) => {
        console.error(`searchProducts failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isSearching = false;
      });
  }

  // 删掉一条历史
  private removeHistory(keyword: string): void {
    removeSearchHistory(this.hostContext(), keyword).then((list: string[]) => {
      this.history = list;
    });
  }

  // 清空历史
  private clearHistory(): void {
    clearSearchHistory(this.hostContext()).then(() => {
      this.history = [];
    });
  }

  build() {
    Column() {
      // 顶栏：返回 + 搜索框 + 取消
      this.TopBar();

      // 搜索历史（有历史才显示，和验收图一致：历史在上面、结果在下面）
      if (this.history.length > 0) {
        this.HistoryArea();
      }

      // 结果区
      if (this.isSearching) {
        Column() {
          Text('搜索中…')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.results.length > 0) {
        this.ResultGrid();
      } else if (this.hasSearched) {
        Column() {
          Text('没有找到相关商品')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        // 还没搜过：留白（历史已经在上面了）
        Column()
          .width('100%')
          .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
  }

  // 顶栏：< 返回 + 搜索输入框 + 取消
  @Builder
  TopBar() {
    Row() {
      Text('< 返回')
        .width(56)
        .fontSize(16)
        .fontColor($r('app.color.theme_blue'))
        .onClick(() => {
          this.back();
        });

      Search({ value: this.keyword, placeholder: '请输入搜索关键字' })
        .layoutWeight(1)
        .height(38)
        .textFont({ size: 15 })
        .placeholderFont({ size: 15 })
        .backgroundColor($r('app.color.detail_chip_bg'))
        .onChange((value: string) => {
          this.keyword = value;
        })
        .onSubmit((value: string) => {
          this.doSearch(value);
        });

      Text('取消')
        .width(56)
        .textAlign(TextAlign.End)
        .fontSize(16)
        .fontColor($r('app.color.theme_blue'))
        .onClick(() => {
          this.back();
        });
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 搜索历史：标签可点可删，下面一个"清除所有搜索历史"
  @Builder
  HistoryArea() {
    Column() {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.history, (item: string) => {
          Row() {
            Text(item)
              .fontSize(13)
              .fontColor($r('app.color.detail_text_dark'))
              .onClick(() => {
                this.doSearch(item);
              });

            // 单个删除
            Text('✕')
              .fontSize(12)
              .fontColor($r('app.color.grey_color'))
              .margin({ left: 8 })
              .onClick(() => {
                this.removeHistory(item);
              });
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.detail_chip_bg'))
          .borderRadius(4)
          .margin({ right: 10, bottom: 10 });
        }, (item: string) => item)
      }
      .width('100%');

      Button('清除所有搜索历史')
        .height(32)
        .fontSize(13)
        .fontColor($r('app.color.detail_text_grey'))
        .backgroundColor($r('app.color.detail_chip_bg'))
        .borderRadius(16)
        .margin({ top: 4, bottom: 12 })
        .onClick(() => {
          this.clearHistory();
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
    .backgroundColor(Color.White)
  }

  // 搜索结果：两列网格（卡片复用首页的 CommodityCard）
  @Builder
  ResultGrid() {
    Grid() {
      ForEach(this.results, (item: HomeGoodsItem) => {
        GridItem() {
          Goods({ GoodsData: item })
            .onClick(() => {
              // 点结果进商品详情，和首页/分类页行为一致
              const params: Record<string, string> = { 'pid': item.pid };
              this.getUIContext().getRouter()
                .pushUrl({ url: 'pages/ShopDetail', params: params })
                .catch((err: Error) => {
                  console.error(`pushUrl to ShopDetail failed, err=${JSON.stringify(err)}`);
                });
            })
        }
      }, (item: HomeGoodsItem) => item.pid)
    }
    .width('100%')
    .layoutWeight(1)
    .columnsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .padding({ left: 12, right: 12, top: 12 })
  }
}
