// 购物车页（Index 的第 3 个页签）
// 数据来源：/findAllShopcart（成功码 5000）、/removeShopcart（逻辑删除，成功码 7000）
// 顶部横幅图来自 /banner（成功码 300），版式对齐课程验收图「1.购物车空状态」
// 两点和老师这一版保持一致、但要写清楚：
//   1) 数量加减只改本地 —— /modifyShopcartCount 的成功码文档没写，暂不调用，
//      所以刷新或重进后数量会回到服务器上的值
//   2) 切回这个页签会重新读 token + 拉最新列表：由父组件传入的 activeIndex 变化触发
//      （不用 onVisibleAreaChange —— 它在一次滑动中会跨多个阈值重复触发，
//        列表被异步响应反复整体替换，这是老师那版踩过的坑）
import { common } from '@kit.AbilityKit';
import { getBanner, fetchAllShopcart, removeShopcart } from '../api/Api';
import {
  BannerItem, BannerResponseBody,
  CartItem, CartListResponseBody, CartOpResponseBody
} from '../models/request';
import { loadSavedToken } from '../utils/Session';

// 成功码
const CODE_CART_LIST: number = 5000;
const CODE_CART_REMOVE: number = 7000;
// 购物车页签在 Index 里的下标（父组件用它判断有没有真的切到本页）
const TAB_INDEX_SHOPBAG: number = 2;

// 购物车里的一行：把后端字段拍平 + 两个本地可变状态
// V1 的 @State 只观测第一层，改 count/selected 必须"整行替换"（见 copyRow / 各操作方法）
interface CartRow {
  sid: string; // 购物车条目 id（删除/勾选都靠它，不是商品 pid）
  pid: string;
  img: string;
  name: string;
  enname: string;
  rule: string; // 加购时拼的规格，如 "冷/全糖/默认奶油"
  price: string; // 后端是字符串
  count: number; // 本地可变（不同步后端）
  selected: boolean; // 本地可变
}

@Component
export default struct ShopBag {
  // 购物车列表
  @State cartRows: CartRow[] = [];
  // 是否处于编辑模式（右上角"编辑/完成"，底部变"删除选择"）
  @State isEditMode: boolean = false;
  // 删除请求中（防连点）
  @State isRemoving: boolean = false;
  // 是否正在加载（只在首次进页面显示，切页签的静默刷新不闪）
  @State isLoading: boolean = false;
  // 是否已登录（未登录显示"去登录"空态）
  @State hasToken: boolean = false;
  // 本地 token
  @State tokenString: string = '';
  // 父组件（Index）传进来的当前页签下标：只有它变成 2 才说明真的切到了购物车页签
  @Prop @Watch('onActiveIndexChange') activeIndex: number = -1;
  // 父组件每次从别的页面回到 Index 就 +1：下完单回来靠它刷新购物车
  @Prop @Watch('onCartTickChange') cartTick: number = 0;
  // 点顶栏"< 返回"时回首页页签：由父组件实现（页签下标在它手里）
  onGoHome: () => void = () => {
  };
  // 顶部横幅图（/banner 拿不到时用项目自带蓝底兜底）
  @State bannerImg: string = '';

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

  // 未登录时跳登录页
  private gotoLogin(): void {
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/LoginPage' })
      .catch((err: Error) => {
        console.error(`pushUrl to LoginPage failed, err=${JSON.stringify(err)}`);
      });
  }

  aboutToAppear(): void {
    // 横幅是页面装饰，和登录状态无关，进页面就拉
    this.fetchBanner();
    // 首次进来：只有父组件已经停在本页签（或没传下标）才拉一次
    // 之后靠 activeIndex 变化触发（见下面的 onActiveIndexChange）
    if (this.activeIndex === TAB_INDEX_SHOPBAG || this.activeIndex === -1) {
      this.refreshCart(true);
    }
  }

  // 监听父组件传来的页签下标：只有真的切到购物车页签时才刷新一次
  // （不用 onVisibleAreaChange —— 一次滑动会跨多个阈值重复触发，导致列表被反复替换）
  onActiveIndexChange(): void {
    if (this.activeIndex === TAB_INDEX_SHOPBAG) {
      this.refreshCart(false);
    }
  }

  // 从别的页面回到 Index 时触发（例如从订单结算页下完单返回）：
  // 如果正停在购物车页签，就刷新一次，让已下单的商品消失
  onCartTickChange(): void {
    if (this.activeIndex === TAB_INDEX_SHOPBAG) {
      this.refreshCart(false);
    }
  }

  build() {
    Column() {
      // 顶部栏
      this.TopBar();
      // 顶部横幅（对齐验收图）
      this.Banner();

      if (!this.hasToken) {
        // 未登录：版式对齐课程验收图「1.购物车空状态」
        // （大号浅灰叉 + "请先登录" + 蓝色"去登录"胶囊按钮）
        // 叉号用两根圆角色块各旋转 45° 拼出来：不依赖字体字形、也不需要图片资源
        Column() {
          Stack() {
            Text('')
              .width(64)
              .height(13)
              .borderRadius(7)
              .backgroundColor($r('app.color.login_border_grey'))
              .rotate({ angle: 45 });
            Text('')
              .width(64)
              .height(13)
              .borderRadius(7)
              .backgroundColor($r('app.color.login_border_grey'))
              .rotate({ angle: -45 });
          }
          .width(72)
          .height(72);

          Text('请先登录')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'))
            .margin({ top: 16 });

          Button('去登录')
            .width(100)
            .height(38)
            .backgroundColor($r('app.color.theme_blue'))
            .fontColor(Color.White)
            .fontSize(15)
            .borderRadius(19)
            .margin({ top: 24 })
            .onClick(() => {
              this.gotoLogin();
            });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.isLoading) {
        // 加载中
        Column() {
          Text('加载中…')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.cartRows.length === 0) {
        // 空购物袋
        Column() {
          Text('🛍')
            .fontSize(44);
          Text('购物袋是空的，去逛逛吧')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'))
            .margin({ top: 12 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        // 商品列表（左滑删除）
        List({ space: 12 }) {
          ForEach(this.cartRows, (row: CartRow) => {
            ListItem() {
              CartItemCard({
                img: row.img,
                name: row.name,
                enname: row.enname,
                rule: row.rule,
                price: row.price,
                count: row.count,
                selected: row.selected,
                editMode: this.isEditMode,
                onSelect: () => {
                  this.toggleSelect(row.sid);
                },
                onStep: (delta: number) => {
                  this.stepQuantity(row.sid, delta);
                }
              })
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.DeleteButton(row.sid);
                },
              },
              edgeEffect: SwipeEdgeEffect.Spring
            });
          // 键值必须包含"会变化的字段"：只写 sid 的话，数量/勾选变化不改变键值，
          // ArkUI 会复用旧的子组件节点、不重跑 itemGenerator，行内的数字和勾选圈就永远停在旧值
          // （官方规则：数据项变了但键值没变 → 对应组件不会被更新）
          }, (row: CartRow) => `${row.sid}_${row.count}_${row.selected ? 1 : 0}_${this.isEditMode ? 'E' : 'N'}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.background_grey'));

        // 底部结算栏
        this.CheckoutBar();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
  }

  // ===== 数据请求 =====

  // 拉顶部横幅图（和首页轮播是同一批数据）
  private fetchBanner(): void {
    getBanner()
      .then((res) => {
        const body: BannerResponseBody = res.result as BannerResponseBody;
        const list: BannerItem[] = body.result ?? [];
        if (list.length > 0) {
          this.bannerImg = list[0].bannerImg;
        }
      })
      .catch((err: Error) => {
        console.error(`getBanner failed, err=${JSON.stringify(err)}`);
      });
  }

  // 拉购物车（showLoading=true 显示"加载中"，切页签回来的静默刷新不显示）
  private refreshCart(showLoading: boolean): void {
    this.isLoading = showLoading;
    // 每次都重新读 token：先逛后登录时，旧的 tokenString 是空的
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (token.length === 0) {
        this.hasToken = false;
        this.cartRows = [];
        this.isEditMode = false;
        this.isLoading = false;
        return;
      }
      this.hasToken = true;
      this.fetchCart();
    });
  }

  // 查询购物车所有商品
  private fetchCart(): void {
    fetchAllShopcart(this.tokenString)
      .then((res) => {
        const body: CartListResponseBody = res.result as CartListResponseBody;
        if (body.code === CODE_CART_LIST) {
          const rows: CartRow[] = [];
          const list: CartItem[] = body.result ?? [];
          for (const g of list) {
            const row: CartRow = {
              sid: g.sid,
              pid: g.pid,
              img: g.small_img,
              name: g.name,
              enname: g.enname,
              rule: g.rule,
              price: g.price,
              count: g.count,
              selected: false
            };
            rows.push(row);
          }
          this.cartRows = rows;
        } else {
          this.toast(body.msg ?? '购物袋加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`fetchAllShopcart failed, err=${JSON.stringify(err)}`);
        this.toast('网络异常，请稍后重试');
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 删除（单个或批量）：后端删成功才移除本地，保证两边一致
  private deleteRows(sids: string[]): void {
    if (this.isRemoving) {
      return; // 防连点
    }
    if (sids.length === 0) {
      this.toast('请先选择要删除的商品');
      return;
    }
    this.isRemoving = true;
    removeShopcart(this.tokenString, sids)
      .then((res) => {
        const body: CartOpResponseBody = res.result as CartOpResponseBody;
        if (body.code === CODE_CART_REMOVE) {
          this.cartRows = this.cartRows.filter((r: CartRow) => !sids.includes(r.sid));
          if (this.cartRows.length === 0) {
            this.isEditMode = false; // 删空了就退出编辑模式
          }
          this.toast('商品已删除');
        } else {
          this.toast(body.msg ?? '删除失败，请稍后重试');
        }
      })
      .catch((err: Error) => {
        console.error(`removeShopcart failed, err=${JSON.stringify(err)}`);
        this.toast('网络异常，请稍后重试');
      })
      .finally(() => {
        this.isRemoving = false;
      });
  }

  // ===== 选中 / 数量（V1 整项替换：直接改行对象的字段界面不会刷新） =====

  // 复制一行，把 selected / count 换成新值
  private copyRow(from: CartRow, selected: boolean, count: number): CartRow {
    const row: CartRow = {
      sid: from.sid,
      pid: from.pid,
      img: from.img,
      name: from.name,
      enname: from.enname,
      rule: from.rule,
      price: from.price,
      count: count,
      selected: selected
    };
    return row;
  }

  // 切换某行的选中态
  private toggleSelect(sid: string): void {
    const i: number = this.cartRows.findIndex((r: CartRow) => r.sid === sid);
    if (i < 0) {
      return;
    }
    const next: CartRow[] = this.cartRows.slice();
    next[i] = this.copyRow(next[i], !next[i].selected, next[i].count);
    this.cartRows = next;
  }

  // 全选 / 取消全选
  private toggleSelectAll(): void {
    const target: boolean = !this.allSelected();
    const next: CartRow[] = this.cartRows.map((r: CartRow): CartRow => {
      return this.copyRow(r, target, r.count);
    });
    this.cartRows = next;
  }

  // 数量加减（只改本地，范围 1~99；刷新或重进会回到服务器上的值）
  private stepQuantity(sid: string, delta: number): void {
    const i: number = this.cartRows.findIndex((r: CartRow) => r.sid === sid);
    if (i < 0) {
      return;
    }
    const value: number = this.cartRows[i].count + delta;
    if (value < 1 || value > 99) {
      return;
    }
    const next: CartRow[] = this.cartRows.slice();
    next[i] = this.copyRow(next[i], next[i].selected, value);
    this.cartRows = next;
  }

  // 是否全选（列表非空且每行都选中）
  private allSelected(): boolean {
    return this.cartRows.length > 0 && this.cartRows.every((r: CartRow) => r.selected);
  }

  // 合计：只统计勾选的（价格是字符串，要转数字）
  private totalPriceText(): string {
    let sum: number = 0;
    this.cartRows.forEach((r: CartRow) => {
      if (r.selected) {
        sum += Number(r.price) * r.count;
      }
    });
    return sum.toFixed(2);
  }

  // 已勾选的 sid 集合（编辑模式批量删除用）
  private selectedSids(): string[] {
    return this.cartRows
      .filter((r: CartRow) => r.selected)
      .map((r: CartRow): string => r.sid);
  }

  // 编辑 <-> 完成
  // 切换时清空所有勾选：普通模式勾选是为了"结算"，如果原样带进编辑模式再点"删除选择"，
  // 就会误删本来想买的商品（老师这一版也补了同样的处理）
  private toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    const next: CartRow[] = this.cartRows.map((r: CartRow): CartRow => {
      return this.copyRow(r, false, r.count);
    });
    this.cartRows = next;
  }

  // 提交订单：跳到订单结算页，把勾选的 sid 用逗号串带过去
  private submitOrder(): void {
    const sids: string[] = this.selectedSids();
    if (sids.length === 0) {
      this.toast('请先勾选要结算的商品');
      return;
    }
    const params: Record<string, string> = { 'sids': sids.join(',') };
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/OrderConfirm', params: params })
      .catch((err: Error) => {
        console.error(`pushUrl to OrderConfirm failed, err=${JSON.stringify(err)}`);
      });
  }

  // ===== 界面分区 =====

  // 顶部栏：左侧"< 返回" + 标题居中 + 右侧"编辑/完成"（有商品才显示）
  @Builder
  TopBar() {
    Row() {
      // 购物车是 Index 的页签，所以"返回"= 切回首页那个页签（不是页面出栈）
      Text('< 返回')
        .width(64)
        .fontSize(16)
        .fontColor($r('app.color.theme_blue'))
        .onClick(() => {
          this.onGoHome();
        });

      Text('购物袋')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'));

      // 右侧同样占 64 宽，标题才真的居中；没商品时是空文本
      Text(this.cartRows.length > 0 ? (this.isEditMode ? '完成' : '编辑') : '')
        .width(64)
        .textAlign(TextAlign.End)
        .fontSize(15)
        .fontColor($r('app.color.theme_blue'))
        .onClick(() => {
          if (this.cartRows.length > 0) {
            this.toggleEditMode();
          }
        });
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 顶部横幅：图来自 /banner，拿不到图时用项目自带蓝底兜底
  @Builder
  Banner() {
    Stack({ alignContent: Alignment.Start }) {
      Image(this.bannerImg.length > 0 ? this.bannerImg : $r('app.media.background'))
        .width('100%')
        .height(110)
        .objectFit(ImageFit.Cover);

      // 半透明遮罩：保证白字在任何底图上都看得清
      Text('')
        .width('100%')
        .height(110)
        .backgroundColor('#33000000');

      Column() {
        Text('luckin coffee的新鲜')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White);
        Text('喝下第一口，你就会懂')
          .fontSize(16)
          .fontColor(Color.White)
          .margin({ top: 6 });
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20 });
    }
    .width('100%')
    .height(110)
  }

  // 左滑露出的删除按钮
  @Builder
  DeleteButton(sid: string) {
    Button('删除')
      .width(80)
      .height('100%')
      .backgroundColor($r('app.color.detail_price_red'))
      .fontColor(Color.White)
      .fontSize(16)
      .borderRadius({ topLeft: 0, topRight: 12, bottomLeft: 0, bottomRight: 12 })
      .onClick(() => {
        this.deleteRows([sid]);
      });
  }

  // 底部结算栏：全选 / 合计 / 提交订单（编辑模式变成"删除选择"）
  @Builder
  CheckoutBar() {
    Row() {
      // 全选圆圈（用圆角 Text 画，Circle 的 fill/stroke 要 SDK 26，项目兼容的是 API 23）
      Stack() {
        Text(this.allSelected() ? '✓' : '')
          .width(20)
          .height(20)
          .borderRadius(10)
          .textAlign(TextAlign.Center)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor(this.allSelected() ? $r('app.color.theme_blue') : Color.White)
          .border({
            width: 1.5,
            color: this.allSelected() ? $r('app.color.theme_blue') : $r('app.color.login_border_grey')
          });
      }
      .width(28)
      .height(28)
      .margin({ right: 6 })
      .onClick(() => {
        this.toggleSelectAll();
      });

      Text('全选')
        .fontSize(15)
        .fontColor($r('app.color.detail_text_dark'));

      Blank();

      if (this.isEditMode) {
        // 编辑模式：批量删除勾选的商品
        Button('删除选择')
          .width(132)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.detail_price_red'))
          .borderRadius(22)
          .opacity(this.isRemoving ? 0.6 : 1)
          .onClick(() => {
            this.deleteRows(this.selectedSids());
          });
      } else {
        // 普通模式：合计 + 提交订单
        Row() {
          Text('合计: ')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_dark'));
          Text(`¥${this.totalPriceText()}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.detail_price_red'));
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ right: 12 });

        Button('提交订单')
          .width(132)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.theme_blue'))
          .borderRadius(22)
          .onClick(() => {
            this.submitOrder();
          });
      }
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: { top: $r('app.color.detail_divider') } })
  }
}

// 购物车单个商品卡片
// 为什么是子组件而不是 @Builder：@Builder 的基础类型参数是"值快照"，
// 父组件的选中态/数量变了不会重新传进来；子组件 + @Prop 会跟着父组件刷新。
@Component
struct CartItemCard {
  @Prop img: string;
  @Prop name: string;
  @Prop enname: string;
  @Prop rule: string;
  @Prop price: string;
  @Prop count: number;
  @Prop selected: boolean;
  @Prop editMode: boolean;
  onSelect: () => void = () => {
  };
  onStep: (delta: number) => void = () => {
  };

  build() {
    Row() {
      // 选择圆圈：编辑模式选中是蓝色，普通模式是红色（圆角 Text 画法，兼容 API 23）
      Stack() {
        Text(this.selected ? '✓' : '')
          .width(20)
          .height(20)
          .borderRadius(10)
          .textAlign(TextAlign.Center)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor(this.selected
            ? (this.editMode ? $r('app.color.theme_blue') : $r('app.color.detail_price_red'))
            : Color.White)
          .border({
            width: 1.5,
            color: this.selected
              ? (this.editMode ? $r('app.color.theme_blue') : $r('app.color.detail_price_red'))
              : $r('app.color.login_border_grey')
          });
      }
      .width(28)
      .height(28)
      .onClick(() => {
        this.onSelect();
      });

      // 商品图
      Image(this.img)
        .width(88)
        .height(88)
        .backgroundColor($r('app.color.detail_hero_bg'))
        .borderRadius(8)
        .margin({ left: 2, right: 12 })
        .objectFit(ImageFit.Cover);

      // 商品信息
      Column() {
        Row() {
          Text(this.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.detail_text_dark'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          // 规格是接口的 rule 字段（如 冷/半糖/无奶油）
          Text(this.rule)
            .fontSize(13)
            .fontColor($r('app.color.detail_text_grey'))
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
        }
        .width('100%');

        Text(this.enname)
          .fontSize(12)
          .fontColor($r('app.color.grey_color'))
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');

        Blank();

        // 价格 + 数量步进器
        Row() {
          Text(`¥${this.price}`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.detail_price_red'))
            .layoutWeight(1);

          // 减号（白底红圈，圆角 Text 画法，兼容 API 23）
          Text('−')
            .width(26)
            .height(26)
            .borderRadius(13)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor($r('app.color.detail_price_red'))
            .backgroundColor(Color.White)
            .border({ width: 1.5, color: $r('app.color.detail_price_red') })
            .onClick(() => {
              this.onStep(-1);
            });

          Text(this.count.toString())
            .fontSize(16)
            .fontColor($r('app.color.detail_text_dark'))
            .width(36)
            .textAlign(TextAlign.Center);

          // 加号（红底实心，圆角 Text 画法，兼容 API 23）
          Text('+')
            .width(26)
            .height(26)
            .borderRadius(13)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.detail_price_red'))
            .onClick(() => {
              this.onStep(1);
            });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);
      }
      .layoutWeight(1)
      .height(88)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(VerticalAlign.Center);
  }
}
