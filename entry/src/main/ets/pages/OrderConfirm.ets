// 订单结算页
// 入口：购物车勾选商品 → 点「提交订单」→ pushUrl 过来，参数 sids（逗号串）
// 数据来源：/commitShopcart（待购商品，成功码 50000）、/findAddress（地址列表，成功码 20000）、
//          /pay（下单，成功码 60000）—— 成功码均为 2026-09-23 测试账号实测
// 版式参考课程验收图「3.订单结算」「4.结算地址1」
import { common } from '@kit.AbilityKit';
import { commitShopcart, findAddress, payOrder } from '../api/Api';
import {
  AddressItem, AddressListResponseBody,
  OrderItem, OrderItemsResponseBody,
  PayBody, PayResponseBody
} from '../models/request';
import { loadSavedToken } from '../utils/Session';

const CODE_ADDRESS_LIST: number = 20000;
const CODE_ORDER_ITEMS: number = 50000;
const CODE_PAY_OK: number = 60000;
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct OrderConfirm {
  // 结算的购物车条目 id（从购物车页传过来）
  @State sids: string[] = [];
  // 本地 token
  @State tokenString: string = '';
  // 待购商品
  @State items: OrderItem[] = [];
  // 收货地址列表
  @State addresses: AddressItem[] = [];
  // 用户手动选中的地址（空 = 用默认地址）
  @State selectedAid: string = '';
  // 是否正在加载商品
  @State isLoading: boolean = false;
  // 是否正在下单（防连点）
  @State isPaying: boolean = false;
  // 地址选择弹窗开关
  @State showAddressSheet: boolean = false;

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

  // 返回上一级
  private back(): void {
    this.getUIContext().getRouter().back();
  }

  aboutToAppear(): void {
    // 1) 取路由参数：sids 用逗号串传（项目里没有传数组的先例，数组不可靠）
    const params: Record<string, string> | undefined =
      this.getUIContext().getRouter().getParams() as Record<string, string> | undefined;
    const sidsParam: string | undefined = params?.sids;
    if (sidsParam !== undefined && sidsParam.length > 0) {
      this.sids = sidsParam.split(',');
    }
    // 2) 读 token 后拉数据
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (token.length === 0) {
        this.toast('请先登录');
        return;
      }
      this.fetchItems();
      this.fetchAddresses();
    });
  }

  // 从「新增/编辑地址」页返回时刷新地址列表
  // （首次进入时 token 还没读出来，这里会自然跳过，不会重复请求）
  onPageShow(): void {
    if (this.tokenString.length > 0) {
      this.fetchAddresses();
    }
  }

  // ===== 数据请求 =====

  // 拉待购商品
  private fetchItems(): void {
    if (this.sids.length === 0) {
      this.toast('没有要结算的商品');
      return;
    }
    this.isLoading = true;
    commitShopcart(this.tokenString, this.sids)
      .then((res) => {
        const body: OrderItemsResponseBody = res.result as OrderItemsResponseBody;
        if (body.code === CODE_ORDER_ITEMS) {
          this.items = body.result ?? [];
        } else {
          this.toast(body.msg ?? '商品加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`commitShopcart failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 拉地址列表
  private fetchAddresses(): void {
    findAddress(this.tokenString)
      .then((res) => {
        const body: AddressListResponseBody = res.result as AddressListResponseBody;
        if (body.code === CODE_ADDRESS_LIST) {
          this.addresses = body.result ?? [];
        } else {
          console.error(`findAddress 返回异常 code=${body.code} msg=${body.msg}`);
        }
      })
      .catch((err: Error) => {
        console.error(`findAddress failed, err=${JSON.stringify(err)}`);
      });
  }

  // 下单
  private doPay(): void {
    const addr: AddressItem | undefined = this.currentAddress();
    if (addr === undefined) {
      this.toast('请先选择收货地址');
      this.showAddressSheet = true;
      return;
    }
    if (this.items.length === 0) {
      this.toast('没有可结算的商品');
      return;
    }
    if (this.isPaying) {
      return; // 防连点：下单不能重复提交
    }
    this.isPaying = true;
    const body: PayBody = {
      tokenString: this.tokenString,
      sids: JSON.stringify(this.sids),
      phone: addr.tel,
      address: addr.province + addr.city + addr.county + addr.addressDetail,
      receiver: addr.name
    };
    payOrder(body)
      .then((res) => {
        const resp: PayResponseBody = res.result as PayResponseBody;
        if (resp.code === CODE_PAY_OK) {
          this.toast('下单成功');
          // 回购物车（Index 的 onPageShow 会触发购物车刷新，已下单的商品会消失）
          this.back();
        } else {
          this.toast(resp.msg ?? '下单失败，请稍后重试');
        }
      })
      .catch((err: Error) => {
        console.error(`payOrder failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isPaying = false;
      });
  }

  // ===== 计算 =====

  // 当前要用的地址：优先用户选的，其次默认地址，再次第一条
  private currentAddress(): AddressItem | undefined {
    if (this.addresses.length === 0) {
      return undefined;
    }
    const picked: AddressItem | undefined =
      this.addresses.find((a: AddressItem) => a.aid === this.selectedAid);
    if (picked !== undefined) {
      return picked;
    }
    const def: AddressItem | undefined =
      this.addresses.find((a: AddressItem) => a.isDefault === 1);
    return def !== undefined ? def : this.addresses[0];
  }

  // 地址整串（省市区 + 详细地址）
  private fullAddress(a: AddressItem): string {
    return a.province + a.city + a.county + a.addressDetail;
  }

  // ===== 当前地址的安全取值（@Builder 里不能写局部变量，也不能用 ! 断言） =====

  private hasAddress(): boolean {
    return this.currentAddress() !== undefined;
  }

  private curName(): string {
    const a: AddressItem | undefined = this.currentAddress();
    return a === undefined ? '' : a.name;
  }

  private curTel(): string {
    const a: AddressItem | undefined = this.currentAddress();
    return a === undefined ? '' : a.tel;
  }

  private curIsDefault(): boolean {
    const a: AddressItem | undefined = this.currentAddress();
    return a !== undefined && a.isDefault === 1;
  }

  private curFullAddress(): string {
    const a: AddressItem | undefined = this.currentAddress();
    return a === undefined ? '' : this.fullAddress(a);
  }

  // 这一条是不是当前选中的（弹窗里画勾用它）
  private isCurrent(addr: AddressItem): boolean {
    const a: AddressItem | undefined = this.currentAddress();
    return a !== undefined && a.aid === addr.aid;
  }

  // 商品总件数
  private totalCount(): number {
    let sum: number = 0;
    this.items.forEach((it: OrderItem) => {
      sum += it.count;
    });
    return sum;
  }

  // 订单金额（price 是字符串要转数字）
  private totalAmountText(): string {
    let sum: number = 0;
    this.items.forEach((it: OrderItem) => {
      sum += Number(it.price) * it.count;
    });
    return sum.toFixed(2);
  }

  // ===== 界面 =====

  build() {
    Column() {
      // 顶栏
      this.TopBar();

      if (this.items.length === 0 && !this.isLoading) {
        Column() {
          Text('没有可结算的商品')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column() {
            // 收货地址卡片
            this.AddressCard();
            // 订单信息卡片
            this.OrderCard();
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        // 底部：立即结算
        this.PayBar();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
    // 地址选择弹窗（和登录页注册弹窗同一套写法）
    .bindSheet($$this.showAddressSheet, this.AddressSheetContent(), {
      height: '60%',
      dragBar: true,
      showClose: false,
      backgroundColor: Color.White
    })
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

      Text('订单结算')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'));

      // 右侧占位保持标题居中
      Text('')
        .width(64);
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // 收货地址卡片
  @Builder
  AddressCard() {
    Column() {
      // 「选择地址 ›」：点它滑出地址弹窗
      Row() {
        Text('选择地址')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.detail_text_dark'));
        Text('>')
          .fontSize(15)
          .fontColor($r('app.color.grey_color'))
          .margin({ left: 4 });
      }
      .width('100%')
      .padding({ bottom: 12 })
      .onClick(() => {
        this.showAddressSheet = true;
      });

      if (this.hasAddress()) {
        // 收货人 + 电话 + 默认标签
        Row() {
          Text(this.curName())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.detail_text_dark'));

          Text(this.curTel())
            .fontSize(15)
            .fontColor($r('app.color.detail_text_dark'))
            .margin({ left: 8 });

          if (this.curIsDefault()) {
            Text('默认')
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.theme_blue'))
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 });
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        // 地址整串
        Text(this.curFullAddress())
          .fontSize(13)
          .fontColor($r('app.color.detail_text_grey'))
          .margin({ top: 8 })
          .width('100%');
      } else {
        Text('还没有收货地址，点上面「选择地址」新增一个')
          .fontSize(14)
          .fontColor($r('app.color.detail_text_grey'));
      }
    }
    .width('calc(100% - 24vp)')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  // 订单信息卡片
  @Builder
  OrderCard() {
    Column() {
      Text('订单信息')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.detail_text_dark'))
        .width('100%')
        .margin({ bottom: 12 });

      // 商品行
      ForEach(this.items, (item: OrderItem) => {
        Row() {
          Image(item.small_img)
            .width(64)
            .height(64)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.detail_hero_bg'));

          Column() {
            // 名称 + 规格
            Row() {
              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.detail_text_dark'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
              Text(item.rule)
                .fontSize(12)
                .fontColor($r('app.color.detail_text_grey'))
                .margin({ left: 8 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1);
            }
            .width('100%');

            Text(item.enname)
              .fontSize(11)
              .fontColor($r('app.color.grey_color'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
              .width('100%');

            // 价格 + 数量
            Row() {
              Text(`¥${item.price}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.detail_price_red'))
                .layoutWeight(1);
              Text(`x${item.count}`)
                .fontSize(13)
                .fontColor($r('app.color.detail_text_dark'));
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 6 });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 });
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 16 });
      }, (item: OrderItem) => item.sid)

      // 虚线分割：用上边框的 dashed 样式（比手画虚线省事）
      Column() {
        Row() {
          Text(`共计 ${this.totalCount()} 件商品`)
            .fontSize(13)
            .fontColor($r('app.color.detail_text_grey'))
            .layoutWeight(1);
          Text('订单金额：')
            .fontSize(14)
            .fontColor($r('app.color.detail_text_dark'));
          Text(`¥${this.totalAmountText()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.detail_price_red'));
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom);
      }
      .width('100%')
      .padding({ top: 14 })
      .border({
        width: { top: 1 },
        color: { top: $r('app.color.login_border_grey') },
        style: { top: BorderStyle.Dashed }
      });
    }
    .width('calc(100% - 24vp)')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12, bottom: 12 });
  }

  // 底部：立即结算
  @Builder
  PayBar() {
    Row() {
      Button(this.isPaying ? '结算中…' : '立即结算')
        .width('100%')
        .height(46)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.theme_blue'))
        .borderRadius(23)
        .opacity(this.isPaying ? 0.6 : 1)
        .onClick(() => {
          this.doPay();
        });
    }
    .width('100%')
    .height(70)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: { top: $r('app.color.detail_divider') } })
  }

  // 地址选择弹窗内容：标题 + 地址列表 + 新增地址
  @Builder
  AddressSheetContent() {
    Column() {
      // 标题行：选择地址 + 右上角关闭
      Row() {
        Text('选择地址')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.detail_text_dark'));
        Blank();
        Text('✕')
          .fontSize(18)
          .fontColor($r('app.color.grey_color'))
          .onClick(() => {
            this.showAddressSheet = false;
          });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      .alignItems(VerticalAlign.Center);

      // 地址列表
      List() {
        ForEach(this.addresses, (addr: AddressItem) => {
          ListItem() {
            Row() {
              // 选中圆圈（沿用购物车的圆角 Text 画法，Circle.fill 要 SDK 26）
              Text(this.isCurrent(addr) ? '✓' : '')
                .width(20)
                .height(20)
                .borderRadius(10)
                .textAlign(TextAlign.Center)
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(this.isCurrent(addr)
                  ? $r('app.color.theme_blue')
                  : Color.White)
                .border({
                  width: 1.5,
                  color: this.isCurrent(addr)
                    ? $r('app.color.theme_blue')
                    : $r('app.color.login_border_grey')
                });

              Column() {
                Row() {
                  Text(addr.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.detail_text_dark'));
                  Text(addr.tel)
                    .fontSize(14)
                    .fontColor($r('app.color.detail_text_dark'))
                    .margin({ left: 8 });
                  if (addr.isDefault === 1) {
                    Text('默认')
                      .fontSize(11)
                      .fontColor(Color.White)
                      .backgroundColor($r('app.color.theme_blue'))
                      .borderRadius(4)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .margin({ left: 8 });
                  }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center);

                Text(this.fullAddress(addr))
                  .fontSize(13)
                  .fontColor($r('app.color.detail_text_grey'))
                  .margin({ top: 6 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%');
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 });

              // 编辑入口（验收图里的"编辑地址"页从这里进）
              Text('编辑')
                .fontSize(14)
                .fontColor($r('app.color.theme_blue'))
                .padding({ left: 8, right: 2, top: 6, bottom: 6 })
                .onClick(() => {
                  this.gotoAddressEdit(addr.aid);
                });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              // 点这一行 = 选中它并关掉弹窗
              this.selectedAid = addr.aid;
              this.showAddressSheet = false;
            });
          }
          // 同上：地址内容变化要能刷新靠的是键值跟着变，不能只用 aid
        }, (addr: AddressItem) => JSON.stringify(addr))
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off);

      // 底部：新增地址
      Button('新增地址')
        .width('calc(100% - 32vp)')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.theme_blue'))
        .borderRadius(22)
        .margin({ top: 8, bottom: 20 })
        .onClick(() => {
          this.gotoAddressEdit('');
        });
    }
    .width('100%')
    .height('100%');
  }

  // 跳「新增/编辑地址」页；aid 为空 = 新增
  private gotoAddressEdit(aid: string): void {
    // 关掉弹窗；返回时 onPageShow 会重新拉地址列表
    this.showAddressSheet = false;
    // 让返回后自动用默认（新加的）地址
    this.selectedAid = '';
    const params: Record<string, string> = { 'aid': aid };
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/AddressEdit', params: params })
      .catch((err: Error) => {
        console.error(`pushUrl to AddressEdit failed, err=${JSON.stringify(err)}`);
      });
  }
}
