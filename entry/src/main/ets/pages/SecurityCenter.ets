// 安全中心页
// 入口：我的 → 安全中心
// 数据来源（成功码均为字符串，2026-09-23 测试账号实测，且验证过真的生效）：
//   /updatePassword 'E001'（改完旧密码立刻失效）
//   /logout         'F001'（退出后旧 token 立刻失效）
//   /destroyAccount 'G001'（不可恢复）
// 版式参考课程验收图「13.安全中心1~4」
import { common } from '@kit.AbilityKit';
import { updatePassword, logout, destroyAccount } from '../api/Api';
import { SecurityOpResponseBody } from '../models/request';
import { loadSavedToken, clearLoginSession } from '../utils/Session';
import { validatePassword } from '../utils/validForm';

const CODE_UPDATE_PWD: string = 'E001';
const CODE_LOGOUT: string = 'F001';
const CODE_DESTROY: string = 'G001';
// 弹窗确认按钮用主题蓝，取消用灰（对齐验收图）
const COLOR_DIALOG_CANCEL: string = '#666666';
const COLOR_DIALOG_CONFIRM: string = '#1677FF';

@Entry
@Component
struct SecurityCenter {
  @State tokenString: string = '';

  // ===== 修改密码弹窗 =====
  @State showPwdSheet: boolean = false;
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State oldPwdVisible: boolean = false;
  @State newPwdVisible: boolean = false;

  // 请求中（防连点）
  @State isSubmitting: boolean = false;

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
      }
    });
  }

  // 回登录页：先清本地登录态，再把登录页换成当前页，最后清栈
  // （顺序很重要：Router.clear() 是"只保留当前栈顶页"，先 clear 会把登录页也清掉）
  private backToLogin(): void {
    clearLoginSession(this.hostContext()).then(() => {
      this.getUIContext().getRouter()
        .replaceUrl({ url: 'pages/LoginPage' })
        .then(() => {
          this.getUIContext().getRouter().clear();
        })
        .catch((err: Error) => {
          console.error(`replaceUrl to LoginPage failed, err=${JSON.stringify(err)}`);
        });
    });
  }

  // ===== 修改密码 =====

  private resetPwdForm(): void {
    this.oldPwd = '';
    this.newPwd = '';
    this.oldPwdVisible = false;
    this.newPwdVisible = false;
  }

  private doUpdatePassword(): void {
    if (this.isSubmitting) {
      return; // 防连点
    }
    if (this.oldPwd.length === 0) {
      this.toast('请输入旧密码');
      return;
    }
    if (!validatePassword(this.newPwd)) {
      this.toast('新密码需 6-16 位，且同时包含字母和数字');
      return;
    }
    if (this.newPwd === this.oldPwd) {
      this.toast('新密码不能与旧密码相同');
      return;
    }
    this.isSubmitting = true;
    updatePassword(this.tokenString, this.newPwd, this.oldPwd)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_UPDATE_PWD) {
          this.showPwdSheet = false;
          this.toast('密码修改成功，请重新登录');
          this.backToLogin();
        } else {
          this.toast(body.msg ?? '修改失败，请检查旧密码');
        }
      })
      .catch((err: Error) => {
        console.error(`updatePassword failed, err=${JSON.stringify(err)}`);
        this.toast('网络异常，请稍后重试');
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  // ===== 注销账号 =====

  private confirmDestroy(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '注销账号',
      message: '是否确认注销账号，一旦确认无法恢复！',
      buttons: [
        { text: '取消', color: COLOR_DIALOG_CANCEL },
        { text: '确认', color: COLOR_DIALOG_CONFIRM }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.doDestroy();
      }
    }).catch((err: Error) => {
      console.error(`showDialog failed, err=${JSON.stringify(err)}`);
    });
  }

  private doDestroy(): void {
    if (this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    destroyAccount(this.tokenString)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_DESTROY) {
          this.toast('账号已注销');
          this.backToLogin();
        } else {
          this.toast(body.msg ?? '注销失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`destroyAccount failed, err=${JSON.stringify(err)}`);
        this.toast('网络异常，请稍后重试');
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  // ===== 退出登录 =====

  private confirmLogout(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '是否确认退出登录！',
      buttons: [
        { text: '取消', color: COLOR_DIALOG_CANCEL },
        { text: '确认', color: COLOR_DIALOG_CONFIRM }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.doLogout();
      }
    }).catch((err: Error) => {
      console.error(`showDialog failed, err=${JSON.stringify(err)}`);
    });
  }

  private doLogout(): void {
    if (this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    logout(this.tokenString)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_LOGOUT) {
          this.toast('已退出登录');
          this.backToLogin();
        } else {
          this.toast(body.msg ?? '退出失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`logout failed, err=${JSON.stringify(err)}`);
        this.toast('网络异常，请稍后重试');
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  // ===== 界面 =====

  build() {
    Column() {
      this.TopBar();

      // 蓝色色块 + 两行菜单卡片（卡片压住色块下沿）
      Stack({ alignContent: Alignment.TopStart }) {
        Text('')
          .width('100%')
          .height(70)
          .backgroundColor($r('app.color.login_blue'));

        Column() {
          MenuRow('修改密码', () => {
            this.resetPwdForm();
            this.showPwdSheet = true;
          });

          Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

          MenuRow('注销账号', () => {
            this.confirmDestroy();
          });
        }
        .width('calc(100% - 24vp)')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 12, right: 12, top: 60 });
      }
      .width('100%')
      .height(175);

      // 退出登录（验收图里它紧跟卡片下方，不贴底）
      Button('退出登录')
        .width('calc(100% - 24vp)')
        .height(46)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.login_blue'))
        .borderRadius(23)
        .margin({ left: 12, right: 12, top: 40 })
        .opacity(this.isSubmitting ? 0.6 : 1)
        .onClick(() => {
          this.confirmLogout();
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
    // 修改密码弹窗（和登录页注册弹窗同一套写法）
    .bindSheet($$this.showPwdSheet, this.PwdSheetContent(), {
      height: '45%',
      dragBar: true,
      showClose: false,
      backgroundColor: Color.White,
      onWillDismiss: (dismiss) => {
        this.resetPwdForm();
        dismiss.dismiss();
      }
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

      Text('安全中心')
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

  // 修改密码弹窗内容
  @Builder
  PwdSheetContent() {
    Column() {
      // 标题 + 关闭
      Row() {
        Text('修改密码')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.detail_text_dark'));

        Blank();

        Text('✕')
          .fontSize(18)
          .fontColor($r('app.color.grey_color'))
          .onClick(() => {
            this.showPwdSheet = false;
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 6 })
      .alignItems(VerticalAlign.Center);

      // 旧密码
      PwdField({
        label: '旧密码',
        value: this.oldPwd,
        visible: this.oldPwdVisible,
        onValueChange: (value: string) => {
          this.oldPwd = value;
        },
        onToggleEye: () => {
          this.oldPwdVisible = !this.oldPwdVisible;
        }
      });

      Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 20, right: 20 })

      // 新密码
      PwdField({
        label: '新密码',
        value: this.newPwd,
        visible: this.newPwdVisible,
        onValueChange: (value: string) => {
          this.newPwd = value;
        },
        onToggleEye: () => {
          this.newPwdVisible = !this.newPwdVisible;
        }
      });

      // 确认修改
      Button(this.isSubmitting ? '提交中…' : '确认修改')
        .width('calc(100% - 40vp)')
        .height(46)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.login_blue'))
        .borderRadius(23)
        .margin({ top: 28 })
        .opacity(this.isSubmitting ? 0.6 : 1)
        .onClick(() => {
          this.doUpdatePassword();
        });
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 24 });
  }
}

// 菜单行：左标题 + 右箭头（修改密码 / 注销账号）
@Builder
function MenuRow(label: string, action: () => void) {
  Row() {
    Text(label)
      .fontSize(15)
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
    action();
  })
}

// 密码输入行（标签 + 密码框 + 小眼睛）
// 做成 @Component + @Prop：@Builder 的按值参数是快照，小眼睛切换明文时图标刷不动
@Component
struct PwdField {
  @Prop label: string;
  @Prop value: string;
  @Prop visible: boolean;
  onValueChange: (value: string) => void = () => {
  };
  onToggleEye: () => void = () => {
  };

  build() {
    Row() {
      Text(this.label)
        .fontSize(15)
        .fontColor($r('app.color.detail_text_grey'))
        .width(64);

      TextInput({ text: this.value, placeholder: '输入密码' })
        .type(this.visible ? InputType.Normal : InputType.Password)
        .showPasswordIcon(false) // 隐藏系统自带眼睛，用右侧自定义图标
        .placeholderColor($r('app.color.login_placeholder_grey'))
        .placeholderFont({ size: 15 })
        .fontSize(15)
        .fontColor($r('app.color.detail_text_dark'))
        .backgroundColor(Color.Transparent)
        .padding({ left: 0, right: 0 })
        .layoutWeight(1)
        .onChange((value: string) => {
          this.onValueChange(value);
        });

      // 小眼睛：切换明文 / 密文
      SymbolGlyph(this.visible ? $r('sys.symbol.eye') : $r('sys.symbol.eye_slash'))
        .fontSize(20)
        .fontColor([$r('app.color.login_placeholder_grey')])
        .margin({ left: 8 })
        .onClick(() => {
          this.onToggleEye();
        });
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center);
  }
}
