// 我的订单页
// 入口：我的 → 我的订单
// 数据来源：/findOrder（成功码 70000）、/receive（确认收货，成功码 80000）、/removeOrder（删除，成功码 90000）
//          —— 成功码与状态流转均为 2026-09-23 测试账号实测
// 版式参考课程验收图「8.我的订单1~5」
//
// ⚠️ 关键事实：/findOrder 返回的是**每件商品一条记录**（同一个订单的多件商品 oid 相同），
//    所以必须先按 oid 分组，才能画出验收图那种"一个订单一张卡片、里面多件商品"。
//    status 过滤语义（实测）：0 全部、1 进行中、2 已完成；确认收货后记录的 status 从 1 变 2。
import { common } from '@kit.AbilityKit';
import { findOrder, receiveOrder, removeOrder } from '../api/Api';
import { OrderRecord, OrderListResponseBody, OrderOpResponseBody } from '../models/request';
import { loadSavedToken } from '../utils/Session';

const CODE_ORDER_LIST: number = 70000;
const CODE_RECEIVE_OK: number = 80000;
const CODE_REMOVE_OK: number = 90000;
const NET_ERR_MSG: string = '网络异常，请稍后重试';
// 页签 -> 传给接口的 status 值
const TAB_LABELS: string[] = ['全部', '进行中', '已完成'];

// 一个订单（把同 oid 的多条商品记录合成一张卡片）
interface OrderGroup {
  oid: string;
  status: number; // 1 进行中 / 2 已完成
  records: OrderRecord[];
  time: string; // 格式化后的下单时间
  totalCount: number;
  totalAmount: string;
}

@Entry
@Component
struct OrderList {
  @State tokenString: string = '';
  // 当前页签：0 全部、1 进行中、2 已完成（同时也是接口的 status 参数）
  @State currentTab: number = 0;
  @State orders: OrderGroup[] = [];
  @State isLoading: boolean = false;
  // 加载是否失败（和"真的没有订单"区分开：早先两者都显示空态，排查时会被带偏）
  @State loadFailed: boolean = false;
  // 收货/删除请求中（防连点）
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

  // 数字补零（时间格式化用）
  private pad2(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  // 后端给的是 UTC 时间（...Z），格式化成设备本地时区的 YYYY-MM-DD HH:mm:ss
  private formatTime(iso: string): string {
    if (iso.length === 0) {
      return '';
    }
    const d: Date = new Date(iso);
    return `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())} `
      + `${this.pad2(d.getHours())}:${this.pad2(d.getMinutes())}:${this.pad2(d.getSeconds())}`;
  }

  aboutToAppear(): void {
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (token.length === 0) {
        this.toast('请先登录');
        return;
      }
      this.fetchOrders();
    });
  }

  // ===== 数据 =====

  // 按当前页签拉订单
  private fetchOrders(): void {
    if (this.tokenString.length === 0) {
      return;
    }
    this.isLoading = true;
    findOrder(this.tokenString, this.currentTab)
      .then((res) => {
        const body: OrderListResponseBody = res.result as OrderListResponseBody;
        // 把原始返回打出来：以后这个接口出问题，hilog 里能直接看到真相
        const rawCount: number = (body.result ?? []).length;
        console.log(`findOrder 返回 => status=${this.currentTab} code=${body.code} 记录数=${rawCount}`);
        if (body.code === CODE_ORDER_LIST) {
          this.orders = this.groupOrders(body.result ?? []);
          this.loadFailed = false;
        } else {
          this.loadFailed = true;
          console.error(`findOrder 返回异常 code=${body.code} msg=${body.msg}`);
        }
      })
      .catch((err: Error) => {
        console.error(`findOrder failed, err=${JSON.stringify(err)}`);
        this.loadFailed = true;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 把"每件商品一条记录"按 oid 合成订单卡片
  private groupOrders(records: OrderRecord[]): OrderGroup[] {
    const groups: OrderGroup[] = [];
    records.forEach((r: OrderRecord) => {
      const found: OrderGroup | undefined =
        groups.find((g: OrderGroup) => g.oid === r.oid);
      if (found === undefined) {
        const created: OrderGroup = {
          oid: r.oid,
          status: r.status,
          records: [],
          time: this.formatTime(r.createdAt),
          totalCount: 0,
          totalAmount: '0.00'
        };
        groups.push(created);
        created.records.push(r);
      } else {
        found.records.push(r);
      }
    });
    // 算每单的件数 / 金额（price 是字符串要转数字）
    groups.forEach((g: OrderGroup) => {
      let count: number = 0;
      let amount: number = 0;
      g.records.forEach((r: OrderRecord) => {
        count += r.count;
        amount += Number(r.price) * r.count;
      });
      g.totalCount = count;
      g.totalAmount = amount.toFixed(2);
    });
    return groups;
  }

  // 确认收货：订单会从"进行中"变成"已完成"
  private doReceive(oid: string): void {
    if (this.isOperating) {
      return; // 防连点
    }
    this.isOperating = true;
    receiveOrder(this.tokenString, oid)
      .then((res) => {
        const body: OrderOpResponseBody = res.result as OrderOpResponseBody;
        if (body.code === CODE_RECEIVE_OK) {
          this.toast('已确认收货');
          this.fetchOrders();
        } else {
          this.toast(body.msg ?? '操作失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`receiveOrder failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isOperating = false;
      });
  }

  // 删除订单前先确认（验收图里就是这个弹窗）
  private confirmDelete(oid: string): void {
    this.getUIContext().getPromptAction().showDialog({
      message: '是否确定删除该订单？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认', color: '#DC2626' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.doDelete(oid);
      }
    }).catch((err: Error) => {
      console.error(`showDialog failed, err=${JSON.stringify(err)}`);
    });
  }

  private doDelete(oid: string): void {
    if (this.isOperating) {
      return;
    }
    this.isOperating = true;
    removeOrder(this.tokenString, oid)
      .then((res) => {
        const body: OrderOpResponseBody = res.result as OrderOpResponseBody;
        if (body.code === CODE_REMOVE_OK) {
          this.toast('订单已删除');
          this.fetchOrders();
        } else {
          this.toast(body.msg ?? '删除失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`removeOrder failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isOperating = false;
      });
  }

  // 切页签：重新按 status 拉一次
  private switchTab(index: number): void {
    if (this.currentTab === index) {
      return;
    }
    this.currentTab = index;
    this.fetchOrders();
  }

  // ===== 界面 =====

  build() {
    Column() {
      this.TopBar();

      // 蓝色色块 + 页签卡片（卡片压住色块下沿）
      Stack({ alignContent: Alignment.TopStart }) {
        Text('')
          .width('100%')
          .height(70)
          .backgroundColor($r('app.color.login_blue'));

        // 页签
        Row() {
          ForEach(TAB_LABELS, (label: string, idx: number) => {
            Column() {
              Text(label)
                .fontSize(15)
                .fontWeight(this.currentTab === idx ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTab === idx
                  ? $r('app.color.detail_text_dark')
                  : $r('app.color.detail_text_grey'));

              // 选中项下面的蓝色下划线
              Text('')
                .width(28)
                .height(3)
                .borderRadius(2)
                .margin({ top: 6 })
                .backgroundColor(this.currentTab === idx
                  ? $r('app.color.theme_blue')
                  : Color.Transparent);
            }
            .layoutWeight(1)
            .onClick(() => {
              this.switchTab(idx);
            });
          }, (label: string) => label)
        }
        .width('calc(100% - 24vp)')
        .height(52)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 12, right: 12, top: 20 })
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .height(72);

      // 订单列表
      if (this.isLoading) {
        Column() {
          Text('加载中…')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.loadFailed) {
        this.ErrorState();
      } else if (this.orders.length === 0) {
        this.EmptyState();
      } else {
        List({ space: 12 }) {
          ForEach(this.orders, (g: OrderGroup) => {
            ListItem() {
              // key 里带上 status：收货后 status 变化会让这一项重建，避免界面不刷新
              OrderCard({
                group: g,
                onReceive: (oid: string) => {
                  this.doReceive(oid);
                },
                onDelete: (oid: string) => {
                  this.confirmDelete(oid);
                }
              })
            }
          }, (g: OrderGroup) => `${g.oid}_${g.status}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .scrollBar(BarState.Off)
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

      Text('我的订单')
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

  // 加载失败态：和"真的没有订单"分开显示，避免把排查方向带偏
  @Builder
  ErrorState() {
    Column() {
      Text('订单加载失败')
        .fontSize(15)
        .fontColor($r('app.color.detail_text_grey'));

      Button('重试')
        .width(120)
        .height(38)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.theme_blue'))
        .borderRadius(19)
        .margin({ top: 16 })
        .onClick(() => {
          this.fetchOrders();
        });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }

  // 空态：一叠"纸"的图形 + 没有订单数据！
  @Builder
  EmptyState() {    Column() {
      // 用手画的"文档"图标，避免依赖图片资源
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

      Text('没有订单数据！')
        .fontSize(15)
        .fontColor($r('app.color.detail_text_grey'))
        .margin({ top: 20 });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }
}

// 一张订单卡片
// 做成 @Component + @Prop：订单数据是异步刷新 + 收货/删除后会整表重建，@Builder 的按值参数是快照，会刷不动
@Component
struct OrderCard {
  @Prop group: OrderGroup;
  onReceive: (oid: string) => void = () => {
  };
  onDelete: (oid: string) => void = () => {
  };

  build() {
    Column() {
      // 头部：订单信息 + 编号 + 右侧操作
      Row() {
        Column() {
          Text('订单信息')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.detail_text_dark'));

          Text(`订单编号：${this.group.oid}`)
            .fontSize(13)
            .fontColor($r('app.color.detail_text_grey'))
            .margin({ top: 6 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        if (this.group.status === 2) {
          // 已完成：显示状态 + 删除按钮
          Row() {
            Text('已完成')
              .fontSize(14)
              .fontColor($r('app.color.detail_text_grey'));

            Text('🗑')
              .fontSize(16)
              .margin({ left: 8 })
              .onClick(() => {
                this.onDelete(this.group.oid);
              });
          }
          .alignItems(VerticalAlign.Center);
        } else {
          // 进行中：确认收货
          Text('确认收货')
            .fontSize(14)
            .fontColor($r('app.color.theme_blue'))
            .onClick(() => {
              this.onReceive(this.group.oid);
            });
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 });

      // 商品行
      ForEach(this.group.records, (r: OrderRecord) => {
        Row() {
          Image(r.smallImg)
            .width(64)
            .height(64)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.detail_hero_bg'));

          Column() {
            Row() {
              Text(r.name)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.detail_text_dark'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });

              Text(r.rule)
                .fontSize(12)
                .fontColor($r('app.color.detail_text_grey'))
                .margin({ left: 8 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1);
            }
            .width('100%');

            Text(r.enname)
              .fontSize(11)
              .fontColor($r('app.color.grey_color'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
              .width('100%');

            Row() {
              Text(`¥${r.price}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.detail_price_red'))
                .layoutWeight(1);
              Text(`x${r.count}`)
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
      }, (r: OrderRecord) => r.id.toString())

      // 底部：虚线 + 下单时间 + 件数 + 金额
      Column() {
        Text(this.group.time)
          .fontSize(13)
          .fontColor($r('app.color.detail_text_grey'))
          .margin({ bottom: 8 })
          .width('100%');

        Row() {
          Text(`共计 ${this.group.totalCount} 件商品`)
            .fontSize(13)
            .fontColor($r('app.color.detail_text_grey'))
            .layoutWeight(1);
          Text('订单金额：')
            .fontSize(14)
            .fontColor($r('app.color.detail_text_dark'));
          Text(`¥${this.group.totalAmount}`)
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
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12);
  }
}
