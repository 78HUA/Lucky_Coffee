// 我的收藏页
// 入口：我的 → 我的收藏
// 数据来源：/findAllLike（成功码 2000，result 是商品数组，字段与首页商品一致 → 可直接用 CommodityCard）
//          /notlike（取消收藏，成功码 900）—— 成功码均为 2026-09-23 测试账号实测
// 版式参考课程验收图「9.我的收藏1/2」：顶栏 + 蓝色色块 + 两列网格；卡片右下角垃圾桶可直接取消收藏
import { common } from '@kit.AbilityKit';
import { findAllLike, unlikeProduct } from '../api/Api';
import { HomeGoodsItem, FavoriteListResponseBody, FavoriteResponseBody } from '../models/request';
import { loadSavedToken } from '../utils/Session';
import Goods from '../components/CommodityCard';

const CODE_FAV_LIST: number = 2000;
const CODE_UNFAVORITED: number = 900;
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct FavoriteList {
  @State tokenString: string = '';
  @State items: HomeGoodsItem[] = [];
  @State isLoading: boolean = false;
  // 取消收藏请求中（防连点）
  @State isOperating: boolean = false;

  // 获取宿主 UIAbility 的上下文（Preferences 读写需要）
  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`showToast failed, err=${JSON.stringify(err)}`);
    }
  }

  private back(): void {
    this.getUIContext().getRouter().back();
  }

  aboutToAppear(): void {
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (token.length === 0) {
        this.toast('请先登录');
        return;
      }
      this.fetchFavorites();
    });
  }

  // 从商品详情页收藏 / 取消收藏后返回，列表要跟着变
  // （首次进入时 token 还没读出来，这里会自然跳过，不会重复请求）
  onPageShow(): void {
    if (this.tokenString.length > 0) {
      this.fetchFavorites();
    }
  }

  // 拉收藏列表
  private fetchFavorites(): void {
    this.isLoading = true;
    findAllLike(this.tokenString)
      .then((res) => {
        const body: FavoriteListResponseBody = res.result as FavoriteListResponseBody;
        if (body.code === CODE_FAV_LIST) {
          this.items = body.result ?? [];
        } else {
          this.toast(body.msg ?? '收藏加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`findAllLike failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 取消收藏：成功后直接把这张卡片从列表里去掉（不弹确认框，收藏随时能加回来）
  private cancelFavorite(item: HomeGoodsItem): void {
    if (this.isOperating) {
      return; // 防连点
    }
    this.isOperating = true;
    unlikeProduct(item.pid, this.tokenString)
      .then((res) => {
        const body: FavoriteResponseBody = res.result as FavoriteResponseBody;
        // 900 = 已取消收藏（800 也一并放行，避免后端返回已收藏状态时误报失败）
        if (body.code === CODE_UNFAVORITED || body.code === 800) {
          this.toast('已取消收藏');
          this.items = this.items.filter((x: HomeGoodsItem) => x.pid !== item.pid);
        } else {
          this.toast(body.msg ?? '取消失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`unlikeProduct failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isOperating = false;
      });
  }

  // 点卡片进商品详情（和首页 / 搜索结果的行为一致）
  private gotoDetail(pid: string): void {
    const params: Record<string, string> = { 'pid': pid };
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/ShopDetail', params: params })
      .catch((err: Error) => {
        console.error(`pushUrl to ShopDetail failed, err=${JSON.stringify(err)}`);
      });
  }

  build() {
    Column() {
      this.TopBar();

      // 蓝色色块 + 一张白色卡片的上沿（对齐验收图）
      Stack({ alignContent: Alignment.TopStart }) {
        Text('')
          .width('100%')
          .height(70)
          .backgroundColor($r('app.color.login_blue'));

        Text('')
          .width('calc(100% - 24vp)')
          .height(56)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 24 });
      }
      .width('100%')
      .height(80);

      if (this.isLoading) {
        Column() {
          Text('加载中…')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.items.length === 0) {
        this.EmptyState();
      } else {
        // 两列网格（和首页 / 搜索结果同一套写法）
        Grid() {
          ForEach(this.items, (item: HomeGoodsItem) => {
            GridItem() {
              // 垃圾桶和卡片是 Stack 里的"兄弟节点"：点卡片进详情、点垃圾桶取消收藏，互不干扰
              Stack({ alignContent: Alignment.BottomEnd }) {
                Goods({ GoodsData: item })
                  .onClick(() => {
                    this.gotoDetail(item.pid);
                  });

                Text('🗑')
                  .fontSize(16)
                  .fontColor($r('app.color.detail_text_grey'))
                  .padding(6)
                  .margin({ right: 4, bottom: 4 })
                  .onClick(() => {
                    this.cancelFavorite(item);
                  });
              }
            }
          }, (item: HomeGoodsItem) => item.pid)
        }
        .width('100%')
        .layoutWeight(1)
        .columnsTemplate('1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .scrollBar(BarState.Off);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
  }

  // 顶栏：< 返回 + 居中标题
  @Builder
  TopBar() {
    Row() {
      Text('< 返回')
        .width(64)
        .fontSize(16)
        .fontColor($r('app.color.theme_blue'))
        .onClick(() => {
          this.back();
        });

      Text('我的收藏')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'));

      Text('')
        .width(64);
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 空态：一叠"纸"的图形 + 没有收藏数据！（和订单页同一套画法）
  @Builder
  EmptyState() {
    Column() {
      Column() {
        Text('').width(56).height(7).borderRadius(4).backgroundColor('#E3E3E3');
        Text('').width(56).height(7).borderRadius(4).backgroundColor('#E3E3E3').margin({ top: 9 });
        Text('').width(34).height(7).borderRadius(4).backgroundColor('#E3E3E3').margin({ top: 9 });
      }
      .width(96)
      .height(116)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F7F7F7')
      .borderRadius(8)
      .border({ width: 1, color: '#EFEFEF' });

      Text('没有收藏数据！')
        .fontSize(15)
        .fontColor($r('app.color.detail_text_grey'))
        .margin({ top: 20 });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }
}
