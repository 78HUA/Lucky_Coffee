// 个人中心页（Index 的第 4 个页签）
// 版式参考课程验收图「7.个人页面.png」：顶部背景图 + 半透明资料卡（头像 / 昵称 / 签名）+ 功能列表卡片
// 数据来源：/findMy（字段名接口文档没写，先按常见命名映射，并把原始返回打日志；
//          跑一次后在 hilog 里看真实字段，只需校正 models/request.ets 里的 MyInfoItem）
import { common } from '@kit.AbilityKit';
import { getMyInfo } from '../api/Api';
import { MyInfoItem, MyInfoResponseBody } from '../models/request';
import { loadSavedToken } from '../utils/Session';

// 功能列表（顺序即界面顺序；这些二级页面都还没做，点击先给提示）
const MENU_ITEMS: string[] = ['个人资料', '我的订单', '我的收藏', '地址管理', '安全中心'];
// /findMy 的成功码是字符串（实测）
const CODE_MY_INFO: string = 'A001';

@Component
export default struct My {
  // 资料（未登录 / 未拿到时显示占位文案）
  @State nickName: string = '未登录';
  @State desc: string = '登录后可同步收藏和购物袋';
  @State avatar: string = '';
  @State bg: string = '';
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

  // 顶部背景图：接口给了用户背景就用它，否则用项目自带的蓝色背景
  private bgSrc(): ResourceStr {
    return this.bg.length > 0 ? this.bg : $r('app.media.background');
  }

  // 头像还没有图时显示的字：未登录显示人像符号，已登录显示昵称首字
  private avatarText(): string {
    if (this.tokenString.length === 0 || this.nickName.length === 0) {
      return '👤';
    }
    return this.nickName.substring(0, 1);
  }

  aboutToAppear(): void {
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (token.length === 0) {
        return; // 未登录：保持占位文案
      }
      this.nickName = '加载中…';
      this.fetchMyInfo();
    });
  }

  // 拉个人资料
  private fetchMyInfo(): void {
    getMyInfo(this.tokenString)
      .then((res) => {
        const body: MyInfoResponseBody = res.result as MyInfoResponseBody;
        // 实测（2026-09-23）：成功码是**字符串** 'A001'，且 result 是**数组**（取 [0]）
        if (body.code !== CODE_MY_INFO) {
          console.error(`findMy 返回异常 code=${body.code} msg=${body.msg}`);
          return;
        }
        const list: MyInfoItem[] = body.result ?? [];
        if (list.length === 0) {
          return;
        }
        const info: MyInfoItem = list[0];
        const name: string = info.nickName ?? '';
        if (name.length > 0) {
          this.nickName = name;
        }
        const descText: string = info.desc ?? '';
        // 登录后如果用户还没写简介，显示"这个人很懒"这类兜底，
        // 而不是继续留着未登录时的提示语「登录后可同步收藏和购物袋」（那样会让人误以为没登录）
        this.desc = descText.length > 0 ? descText : '这个人很懒，什么都没写';
        // 实测字段名：头像是 userImg、背景是 userBg（不是 avatar/bg）
        this.avatar = info.userImg ?? '';
        this.bg = info.userBg ?? '';
      })
      .catch((err: Error) => {
        console.error(`getMyInfo failed, err=${JSON.stringify(err)}`);
      });
  }

  // 菜单点击：已做好的页面真跳转，其余先给提示
  private onMenuClick(item: string): void {
    if (item === '个人资料') {
      this.gotoPage('pages/ProfilePage');
      return;
    }
    if (item === '我的订单') {
      this.gotoPage('pages/OrderList');
      return;
    }
    if (item === '我的收藏') {
      this.gotoPage('pages/FavoriteList');
      return;
    }
    if (item === '地址管理') {
      this.gotoPage('pages/AddressList');
      return;
    }
    if (item === '安全中心') {
      this.gotoPage('pages/SecurityCenter');
      return;
    }
    this.toast(`「${item}」页面开发中`);
  }

  private gotoPage(url: string): void {
    this.getUIContext().getRouter()
      .pushUrl({ url: url })
      .catch((err: Error) => {
        console.error(`pushUrl to ${url} failed, err=${JSON.stringify(err)}`);
      });
  }

  build() {
    Scroll() {
      Column() {
        // 顶部：背景图 + 半透明资料卡
        this.Header()
        // 功能列表卡片
        this.MenuCard()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.background_grey'))
  }

  // 顶部背景图 + 压在下沿的半透明资料卡
  @Builder
  Header() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景图
      Image(this.bgSrc())
        .width('100%')
        .height(190)
        .objectFit(ImageFit.Cover)

      // 资料卡：半透明白，压在背景图下沿（参考图里名字是蓝色、签名是深灰）
      Row() {
        // 头像（有图用图，没图用首字圆）
        if (this.avatar.length > 0) {
          Image(this.avatar)
            .width(60)
            .height(60)
            .borderRadius(30)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: Color.White })
        } else {
          Text(this.avatarText())
            .width(60)
            .height(60)
            .borderRadius(30)
            .backgroundColor($r('app.color.theme_blue'))
            .fontColor(Color.White)
            .fontSize(24)
            .textAlign(TextAlign.Center)
            .border({ width: 2, color: Color.White })
        }

        // 昵称 + 签名
        Column() {
          Text(this.nickName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.theme_blue'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%');

          Text(this.desc)
            .fontSize(13)
            .fontColor($r('app.color.detail_text_dark'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
            .width('100%');
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('calc(100% - 32vp)')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor($r('app.color.my_card_overlay'))
      .borderRadius(12)
      .alignItems(VerticalAlign.Center)
      .margin({ left: 16, right: 16, bottom: 14 });
    }
    .width('100%')
    .height(190)
  }

  // 功能列表卡片（每行一个入口 + 右侧箭头，行间细分割线）
  @Builder
  MenuCard() {
    Column() {
      ForEach(MENU_ITEMS, (item: string, idx: number) => {
        Column() {
          Row() {
            Text(item)
              .fontSize(16)
              .fontColor($r('app.color.detail_text_dark'))
              .layoutWeight(1);

            Text('>')
              .fontSize(16)
              .fontColor($r('app.color.grey_color'));
          }
          .width('100%')
          .height(53)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onMenuClick(item);
          });

          // 最后一行不画分割线
          if (idx < MENU_ITEMS.length - 1) {
            Divider()
              .strokeWidth(1)
              .color($r('app.color.detail_divider'))
              .margin({ left: 16 });
          }
        }
        .width('100%');
      }, (item: string) => item)
    }
    .width('calc(100% - 24vp)')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }
}
