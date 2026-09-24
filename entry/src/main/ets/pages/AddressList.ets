// 地址管理页
// 入口：我的 → 地址管理
// 数据来源：/findAddress（成功码 20000）—— 和订单结算页用的是同一个接口、同一份数据
// 新增 / 编辑 / 删除都跳到已有的 pages/AddressEdit：
//   aid 传空串 = 新增模式；aid 传具体值 = 编辑模式（删除按钮也在那一页里）
// 版式参考课程验收图「10.地址管理」：地址卡片 + 右侧铅笔 + 底部固定「新增地址」
import { common } from '@kit.AbilityKit';
import { findAddress } from '../api/Api';
import { AddressItem, AddressListResponseBody } from '../models/request';
import { loadSavedToken } from '../utils/Session';

const CODE_ADDRESS_LIST: number = 20000;
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct AddressList {
  @State tokenString: string = '';
  @State addresses: AddressItem[] = [];
  @State isLoading: boolean = false;

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
      this.fetchAddresses();
    });
  }

  // 从新增 / 编辑地址页返回时刷新列表（新增、改名、删除都能立刻看到）
  onPageShow(): void {
    if (this.tokenString.length > 0) {
      this.fetchAddresses();
    }
  }

  // 拉地址列表
  private fetchAddresses(): void {
    this.isLoading = true;
    findAddress(this.tokenString)
      .then((res) => {
        const body: AddressListResponseBody = res.result as AddressListResponseBody;
        if (body.code === CODE_ADDRESS_LIST) {
          this.addresses = body.result ?? [];
        } else {
          this.toast(body.msg ?? '地址加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`findAddress failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 地址整串（省市区 + 详细地址）
  private fullAddress(a: AddressItem): string {
    return a.province + a.city + a.county + a.addressDetail;
  }

  // 跳新增 / 编辑地址页（aid 空 = 新增）
  private gotoAddressEdit(aid: string): void {
    const params: Record<string, string> = { 'aid': aid };
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/AddressEdit', params: params })
      .catch((err: Error) => {
        console.error(`pushUrl to AddressEdit failed, err=${JSON.stringify(err)}`);
      });
  }

  build() {
    Column() {
      this.TopBar();

      if (this.isLoading) {
        Column() {
          Text('加载中…')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.addresses.length === 0) {
        Column() {
          Text('还没有收货地址，点下面的按钮新增一个')
            .fontSize(15)
            .fontColor($r('app.color.detail_text_grey'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List({ space: 12 }) {
          ForEach(this.addresses, (addr: AddressItem) => {
            ListItem() {
              // 地址卡片：姓名 + 电话 + 默认标签 + 右侧铅笔；下面一行地址整串
              Column() {
                Row() {
                  Text(addr.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.detail_text_dark'));

                  Text(addr.tel)
                    .fontSize(15)
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

                  Blank();

                  // 铅笔：进编辑页（改资料、删除都在那一页）
                  Text('✏️')
                    .fontSize(16)
                    .padding({ left: 8, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.gotoAddressEdit(addr.aid);
                    });
                }
                .width('100%')
                .alignItems(VerticalAlign.Center);

                Text(this.fullAddress(addr))
                  .fontSize(13)
                  .fontColor($r('app.color.detail_text_grey'))
                  .margin({ top: 8 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%');
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12);
            }
          // 键值用整条地址的序列化：只写 aid 的话，编辑地址后 aid 没变、键值没变，
          // 列表这一行会一直显示旧内容
          }, (addr: AddressItem) => JSON.stringify(addr))
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .scrollBar(BarState.Off);
      }

      // 底部固定：新增地址
      Row() {
        Button('新增地址')
          .width('100%')
          .height(46)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.login_blue'))
          .borderRadius(23)
          .onClick(() => {
            this.gotoAddressEdit('');
          });
      }
      .width('100%')
      .height(70)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: { top: $r('app.color.detail_divider') } })
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

      Text('地址管理')
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
}
