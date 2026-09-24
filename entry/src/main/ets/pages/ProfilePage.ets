// 个人资料页（只读展示）
// 入口：我的 → 个人资料
// 数据来源：/findAccountInfo（成功码是字符串 'B001'，result 是数组）——用它是因为它比 /findMy 多了 userId 和 phone
// 版式参考课程验收图「11.个人资料」：顶栏 + 蓝色色块 + 压在下沿的白色卡片
import { common } from '@kit.AbilityKit';
import { getAccountInfo } from '../api/Api';
import { AccountInfoItem, AccountInfoResponseBody } from '../models/request';
import { loadSavedToken } from '../utils/Session';

const CODE_ACCOUNT_INFO: string = 'B001'; // 注意是字符串
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct ProfilePage {
  @State tokenString: string = '';
  @State userImg: string = '';
  @State userId: string = '';
  @State phone: string = '';
  @State nickName: string = '';
  @State desc: string = '';

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
      this.fetchAccountInfo();
    });
  }

  // 拉账号信息
  private fetchAccountInfo(): void {
    getAccountInfo(this.tokenString)
      .then((res) => {
        const body: AccountInfoResponseBody = res.result as AccountInfoResponseBody;
        if (body.code === CODE_ACCOUNT_INFO) {
          // 实测：这个接口的 result 是**数组**，取 [0]
          const list: AccountInfoItem[] = body.result ?? [];
          if (list.length > 0) {
            const info: AccountInfoItem = list[0];
            this.userImg = info.userImg ?? '';
            this.userId = info.userId ?? '';
            this.phone = info.phone ?? '';
            this.nickName = info.nickName ?? '';
            this.desc = info.desc ?? '';
          }
        } else {
          this.toast(body.msg ?? '资料加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`getAccountInfo failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      });
  }

  build() {
    Column() {
      this.TopBar();

      // 蓝色色块 + 压住下沿的白色卡片（用 Stack 实现，不用负 margin）
      Stack({ alignContent: Alignment.TopStart }) {
        // 蓝色背景块
        Text('')
          .width('100%')
          .height(70)
          .backgroundColor($r('app.color.login_blue'));

        // 资料卡片
        Column() {
          // 头像：标签在左、圆形头像靠右
          Row() {
            Text('头像')
              .fontSize(15)
              .fontColor($r('app.color.detail_text_dark'))
              .layoutWeight(1);

            if (this.userImg.length > 0) {
              Image(this.userImg)
                .width(44)
                .height(44)
                .borderRadius(22)
                .objectFit(ImageFit.Cover)
                .backgroundColor($r('app.color.detail_hero_bg'));
            } else {
              Text('👤')
                .width(44)
                .height(44)
                .borderRadius(22)
                .textAlign(TextAlign.Center)
                .fontSize(22)
                .backgroundColor($r('app.color.detail_chip_bg'));
            }
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center);

          Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

          InfoRow({ label: '用户id', value: this.userId })

          Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

          InfoRow({ label: '手机号', value: this.phone })

          Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

          InfoRow({ label: '昵称', value: this.nickName })

          Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

          // 简介：标签一行、内容换行显示在下面
          Column() {
            Text('简介')
              .fontSize(15)
              .fontColor($r('app.color.detail_text_dark'))
              .width('100%');

            Text(this.desc.length > 0 ? this.desc : '这个人很懒，什么都没写')
              .fontSize(14)
              .fontColor($r('app.color.detail_text_grey'))
              .margin({ top: 8 })
              .width('100%');
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 14, bottom: 16 });
        }
        .width('calc(100% - 24vp)')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 12, right: 12, top: 45 });
      }
      .width('100%')
      .layoutWeight(1)
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

      Text('个人资料')
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

// 一行"标签 + 右侧灰值"
// 做成 @Component + @Prop 而不是 @Builder：@Builder 的按值参数是快照，
// 资料是异步加载回来的，用 @Builder 会出现"数据回来了但界面不刷新"
@Component
struct InfoRow {
  @Prop label: string;
  @Prop value: string;

  build() {
    Row() {
      Text(this.label)
        .fontSize(15)
        .fontColor($r('app.color.detail_text_dark'));

      Blank();

      Text(this.value.length > 0 ? this.value : '未设置')
        .fontSize(15)
        .fontColor($r('app.color.grey_color'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }
}
