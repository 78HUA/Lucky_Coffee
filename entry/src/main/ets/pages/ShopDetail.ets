// 商品详情页
// 数据来源：/productDetail（实测成功码 code=600，result 是数组，字段是 snake_case）
// 入口：首页 / 分类页的商品卡片点击后 pushUrl 过来，携带路由参数 pid
// 功能：商品详情 + 规格选择 + 数量 + 收藏 + 加入购物袋（含购物袋数量角标）
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import {
  getProductDetail, getFavoriteStatus, likeProduct, unlikeProduct,
  saveToShopCart, fetchShopCartCount
} from '../api/Api';
import {
  ProductDetailItem, ProductDetailResponseBody,
  FavoriteStatusResponseBody, FavoriteResponseBody,
  SaveShopCartProduct, AddShopCartResponseBody, ShopCartCountResponseBody
} from '../models/request';
import { loadSavedToken } from '../utils/Session';

// 单独打开这一页调试时用的默认商品（正常都是从列表页带 pid 过来）
const DEFAULT_PID: string = 'latte006';
const NET_ERR_MSG: string = '网络异常，请稍后重试';
// 收藏成功码：800 已收藏、900 已取消收藏
const CODE_FAVORITED: number = 800;
const CODE_UNFAVORITED: number = 900;
// 加入购物车成功码
const CODE_ADD_TO_CART: number = 3000;
// 查询购物车数量成功码
const CODE_CART_COUNT: number = 4000;
// 购物车页签在 Index 里的下标（详情页点"购物袋"要跳到它）
const TAB_INDEX_SHOPBAG: number = 2;

// 一组规格（温度 / 奶 / 糖 / 奶油），例如：温度 -> [冷, 热]
interface SpecGroup {
  key: string; // tem / milk / sugar / cream
  label: string; // 这组规格的名字，来自 xxx_desc
  options: string[]; // 选项，来自 xxx 按 "/" 拆开
  selectedIndex: number; // 当前选中第几项
}

@Entry
@Component
struct ShopDetail {
  // 商品 id（从路由参数取；取不到则用默认值，方便单独调试这一页）
  @State pid: string = DEFAULT_PID;
  // 商品详情数据
  @State product: ProductDetailItem | null = null;
  // 规格组（实测不同商品的规格组数是 2~3 组：温度/糖度/奶油常见，奶常常是空的）
  @State specGroups: SpecGroup[] = [];
  // 购买数量
  @State quantity: number = 1;
  // 是否正在加载详情
  @State isLoading: boolean = false;
  // 这个商品是否已被收藏
  @State isFavorite: boolean = false;
  // 收藏请求中（防连点）
  @State isFavOperating: boolean = false;
  // 加入购物袋请求中（防止手快连点重复提交）
  @State isSaveToShopCarting: boolean = false;
  // 购物袋里的商品总数量（底部角标显示）
  @State shopCartCount: number = 0;
  // 本地登录 token（收藏和加购都要用，未登录时是空串）
  @State tokenString: string = '';

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

  // 未登录时统一跳登录页（只弹提示用户不知道去哪登录）
  private gotoLogin(): void {
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/LoginPage' })
      .catch((err: Error) => {
        console.error(`pushUrl to LoginPage failed, err=${JSON.stringify(err)}`);
      });
  }

  aboutToAppear(): void {
    // 1) 从路由参数取 pid
    const params: Record<string, string> | undefined =
      this.getUIContext().getRouter().getParams() as Record<string, string> | undefined;
    const pidParam: string | undefined = params?.pid;
    if (pidParam !== undefined && pidParam.length > 0) {
      this.pid = pidParam;
    }
    // 2) 读本地 token（未登录时是空串），拿到后再查收藏状态和购物袋数量
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      this.fetchFavoriteStatus();
      this.fetchShopCartCount();
    });
    // 3) 拉商品详情
    this.fetchProductDetail();
  }

  // ===== 数据请求 =====

  // 查询商品详情
  private fetchProductDetail(): void {
    if (this.pid.length === 0) {
      return;
    }
    this.isLoading = true;
    getProductDetail(this.pid)
      .then((res) => {
        const body: ProductDetailResponseBody = res.result as ProductDetailResponseBody;
        // 实测：同一个后端多套成功码 —— 注册 100、登录 200、详情 600、收藏 800/900、加购 3000、购物车数量 4000
        if (body.code === 600 && body.result.length > 0) {
          const item: ProductDetailItem = body.result[0];
          this.product = item;
          this.specGroups = this.buildSpecGroups(item);
        } else {
          this.toast('商品详情加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`getProductDetail failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 查询这个商品有没有被收藏
  private fetchFavoriteStatus(): void {
    if (this.pid.length === 0 || this.tokenString.length === 0) {
      return; // 未登录就没有收藏状态可查
    }
    getFavoriteStatus(this.pid, this.tokenString)
      .then((res) => {
        const body: FavoriteStatusResponseBody = res.result as FavoriteStatusResponseBody;
        // result 是"已收藏的商品"数组：长度 > 0 就是已收藏
        // （未收藏时后端可能返回空数组、也可能返回 null，所以用 ?? [] 兜底）
        const liked: Object[] = body.result ?? [];
        this.isFavorite = liked.length > 0;
      })
      .catch((err: Error) => {
        console.error(`getFavoriteStatus failed, err=${JSON.stringify(err)}`);
      });
  }

  // 切换收藏状态
  private toggleFavorite(): void {
    if (this.isFavOperating) {
      return; // 防连点
    }
    if (this.tokenString.length === 0) {
      this.toast('请先登录');
      this.gotoLogin();
      return;
    }
    this.isFavOperating = true;
    // 已收藏 -> 取消收藏；未收藏 -> 收藏
    const task: Promise<http.HttpResponse> = this.isFavorite
      ? unlikeProduct(this.pid, this.tokenString)
      : likeProduct(this.pid, this.tokenString);
    task
      .then((res) => {
        const body: FavoriteResponseBody = res.result as FavoriteResponseBody;
        // 800 = 已收藏、900 = 已取消收藏，两个都算成功，成功后把界面状态翻过来
        if (body.code === CODE_FAVORITED || body.code === CODE_UNFAVORITED) {
          this.isFavorite = !this.isFavorite;
        } else {
          this.toast(body.msg ?? '操作失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`toggleFavorite failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isFavOperating = false;
      });
  }

  // 加入购物袋
  private onAddToBag(): void {
    if (this.tokenString.length === 0) {
      this.toast('请先登录');
      this.gotoLogin();
      return;
    }
    if (this.isSaveToShopCarting) {
      return; // 防重复提交
    }
    if (this.specGroups.length === 0) {
      // 规格还没拉回来（或这件商品真的没有规格），此时拼不出 rule，直接拦掉
      this.toast('商品规格还没加载好，请稍后再试');
      return;
    }
    this.isSaveToShopCarting = true;
    const data: SaveShopCartProduct = {
      pid: this.pid,
      count: this.quantity,
      rule: this.buildRuleString(),
      tokenString: this.tokenString
    };
    saveToShopCart(data)
      .then((res) => {
        const body: AddShopCartResponseBody = res.result as AddShopCartResponseBody;
        if (body.code === CODE_ADD_TO_CART) {
          this.toast('加入购物车成功');
          // 后台数量不会立刻回来，先把角标按本次数量加上去
          this.shopCartCount += this.quantity;
        } else {
          this.toast(body.msg ?? '加入购物车失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`saveToShopCart failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isSaveToShopCarting = false;
      });
  }

  // 查询购物袋里的商品总数量（底部角标用）
  private fetchShopCartCount(): void {
    if (this.tokenString.length === 0) {
      return; // 未登录看不到购物袋
    }
    fetchShopCartCount(this.tokenString)
      .then((res) => {
        const body: ShopCartCountResponseBody = res.result as ShopCartCountResponseBody;
        if (body.code === CODE_CART_COUNT) {
          // result 是数量，空购物袋时可能是 null
          this.shopCartCount = body.result ?? 0;
        }
      })
      .catch((err: Error) => {
        console.error(`fetchShopCartCount failed, err=${JSON.stringify(err)}`);
      });
  }

  // 把当前选中的规格拼成后端要的格式，如 "冷/全糖/默认奶油"
  // 顺序就是 specGroups 的顺序（温度 → 奶 → 糖 → 奶油），空组在构建规格时已经被跳过
  private buildRuleString(): string {
    return this.specGroups
      .map((g: SpecGroup) => g.options[g.selectedIndex])
      .join('/');
  }

  // ===== 规格数据处理 =====

  // 把商品上的四个规格字段整理成界面要用的规格组
  private buildSpecGroups(item: ProductDetailItem): SpecGroup[] {
    const groups: SpecGroup[] = [];
    this.pushSpecGroup(groups, 'tem', item.tem_desc, item.tem);
    this.pushSpecGroup(groups, 'milk', item.milk_desc, item.milk);
    this.pushSpecGroup(groups, 'sugar', item.sugar_desc, item.sugar);
    this.pushSpecGroup(groups, 'cream', item.cream_desc, item.cream);
    return groups;
  }

  // 追加一组规格；值为空就不追加（实测很多商品的 milk 是空串，但 milk_desc 有值）
  private pushSpecGroup(groups: SpecGroup[], key: string, label: string | undefined,
    raw: string | undefined): void {
    const options: string[] = (raw ?? '')
      .split('/')
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0);
    if (options.length === 0) {
      return;
    }
    const name: string = (label ?? '').trim();
    const group: SpecGroup = {
      key: key,
      label: name.length > 0 ? name : key,
      options: options,
      selectedIndex: 0
    };
    groups.push(group);
  }

  // 选中某组规格的第 index 项
  // 关键点：V1 的 @State 只观测"第一层"——直接改 specGroups[i].selectedIndex 界面不会刷新，
  //        所以这里把这一项换成新对象、再给数组整体重新赋值。
  private selectSpec(key: string, index: number): void {
    const next: SpecGroup[] = this.specGroups.slice();
    const i: number = next.findIndex((g: SpecGroup) => g.key === key);
    if (i < 0) {
      return;
    }
    const updated: SpecGroup = {
      key: next[i].key,
      label: next[i].label,
      options: next[i].options,
      selectedIndex: index
    };
    next[i] = updated;
    this.specGroups = next;
  }

  // 商品描述（后端没给描述时用兜底文案，不硬编别的内容）
  private descText(): string {
    const desc: string = this.product?.desc ?? '';
    return desc.trim().length > 0 ? desc : '暂无商品描述';
  }

  // ===== 界面 =====

  build() {
    Column() {
      // 顶部导航栏
      this.TopBar();

      if (this.product !== null) {
        // 可滚动内容区
        Scroll() {
          Column() {
            // 商品主图
            this.HeroImage();
            // 名称 / 英文名 / 价格
            this.ProductInfo();
            // 规格（温度 / 奶 / 糖 / 奶油，空的不显示）
            ForEach(this.specGroups, (group: SpecGroup) => {
              SpecRow({
                label: group.label,
                options: group.options,
                selectedIndex: group.selectedIndex,
                onSelect: (index: number) => {
                  this.selectSpec(group.key, index);
                }
              })
            // 键值带上 selectedIndex：只写 group.key 的话，选中项变化不改变键值，
            // 子组件 SpecRow 的 @Prop 不会更新，高亮就不会移动
            }, (group: SpecGroup) => `${group.key}_${group.selectedIndex}`)
            // 数量选择
            this.QuantitySelector();
            // 商品描述
            this.ProductDesc();
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        // 底部操作栏
        this.BottomBar();
      } else {
        // 加载中 / 加载失败占位
        Column() {
          Text(this.isLoading ? '加载中…' : '商品加载失败')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
  }

  // 顶部导航栏
  @Builder
  TopBar() {
    Row() {
      Text('< 返回')
        .fontSize(16)
        .fontColor($r('app.color.detail_text_dark'))
        .onClick(() => {
          this.getUIContext().getRouter().back();
        });

      Blank();

      Text('商品详情')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'));

      Blank();

      // 右侧透明占位，让标题保持居中
      Text('< 返回')
        .fontSize(16)
        .fontColor(Color.Transparent);
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 商品主图
  @Builder
  HeroImage() {
    Image(this.product?.large_img ?? '')
      .width('100%')
      .height(320)
      .objectFit(ImageFit.Cover)
      .backgroundColor($r('app.color.detail_hero_bg'))
  }

  // 商品信息：名称 + 英文名 + 价格
  @Builder
  ProductInfo() {
    Row() {
      Column() {
        Text(this.product?.name ?? '')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.detail_text_dark'));

        Text(this.product?.enname ?? '')
          .fontSize(12)
          .fontColor($r('app.color.grey_color'))
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);

      Text(`¥${this.product?.price ?? ''}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.detail_price_red'));
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 数量选择器
  @Builder
  QuantitySelector() {
    Row() {
      Text('选择数量')
        .fontSize(14)
        .fontColor($r('app.color.detail_text_dark'))
        .layoutWeight(1);

      // 减号
      Text('-')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor($r('app.color.detail_chip_bg'))
        .fontColor($r('app.color.detail_text_dark'))
        .fontSize(18)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.quantity > 1) {
            this.quantity--;
          }
        });

      Text(this.quantity.toString())
        .width(48)
        .fontSize(16)
        .fontColor($r('app.color.detail_text_dark'))
        .textAlign(TextAlign.Center);

      // 加号
      Text('+')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor($r('app.color.detail_chip_bg'))
        .fontColor($r('app.color.detail_text_dark'))
        .fontSize(18)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.quantity < 99) {
            this.quantity++;
          }
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 商品描述
  @Builder
  ProductDesc() {
    Column() {
      Text('商品描述')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'))
        .margin({ bottom: 8 });

      Text(this.descText())
        .fontSize(13)
        .fontColor($r('app.color.detail_text_grey'))
        .lineHeight(22);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    .backgroundColor(Color.White)
  }

  // 底部操作栏
  @Builder
  BottomBar() {
    Row() {
      // 购物袋入口（带数量角标）
      Badge({
        count: this.shopCartCount,
        style: {},
        position: BadgePosition.RightTop
      }) {
        Column() {
          Text('🛍')
            .fontSize(22);
          Text('购物袋')
            .fontSize(11)
            .fontColor($r('app.color.detail_text_grey'))
            .margin({ top: 2 });
        }
        .width(56)
        .alignItems(HorizontalAlign.Center)
      }
      .width(56)
      .onClick(() => {
        // 跳回首页并指定显示"购物车"那个页签（Index 会读这个下标）
        const params: Record<string, number> = { 'selectedIndex': TAB_INDEX_SHOPBAG };
        this.getUIContext().getRouter()
          .pushUrl({ url: 'pages/Index', params: params })
          .catch((err: Error) => {
            console.error(`pushUrl to Index failed, err=${JSON.stringify(err)}`);
          });
      });

      // 收藏入口
      Column() {
        Text(this.isFavorite ? '♥' : '♡')
          .fontSize(22)
          .fontColor(this.isFavorite ? $r('app.color.detail_price_red') : $r('app.color.detail_text_grey'));
        Text(this.isFavorite ? '已收藏' : '收藏')
          .fontSize(11)
          .fontColor(this.isFavorite ? $r('app.color.detail_price_red') : $r('app.color.detail_text_grey'))
          .margin({ top: 2 });
      }
      .width(56)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.toggleFavorite();
      });

      // 加入购物袋按钮
      Button(this.isSaveToShopCarting ? '加入中…' : '加入购物袋')
        .layoutWeight(1)
        .height(44)
        .backgroundColor($r('app.color.theme_blue'))
        .fontColor(Color.White)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .margin({ left: 12 })
        .opacity(this.isSaveToShopCarting ? 0.6 : 1)
        .onClick(() => {
          this.onAddToBag();
        });
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: { top: $r('app.color.detail_divider') } })
  }
}

// 一组规格（温度 / 糖度 / 奶油通用，可复用）
// 为什么做成独立子组件而不是 @Builder：
//   @Builder 的基础类型参数是"值快照"，父组件状态变了不会重新传进来，选中高亮就刷不对；
//   子组件 + @Prop 是单向绑定，父组件 specGroups 一变这里就跟着重渲染。
@Component
struct SpecRow {
  @Prop label: string;
  @Prop options: string[];
  @Prop selectedIndex: number;
  onSelect: (index: number) => void = () => {
  };

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor($r('app.color.detail_text_dark'))
        .width(56);

      Row() {
        ForEach(this.options, (opt: string, idx: number) => {
          Text(opt)
            .fontSize(13)
            .fontColor(opt === this.options[this.selectedIndex] ? Color.White : $r('app.color.detail_text_grey'))
            .backgroundColor(opt === this.options[this.selectedIndex]
              ? $r('app.color.theme_blue')
              : $r('app.color.detail_chip_bg'))
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 8 })
            .onClick(() => {
              this.onSelect(idx);
            });
        }, (opt: string) => opt)
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }
}
