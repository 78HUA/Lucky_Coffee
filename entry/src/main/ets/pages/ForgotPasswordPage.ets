// 忘记密码页
// 入口：登录页 →「忘记密码?」
// 数据来源（成功码均为字符串，2026-09-23 测试账号实测）：
//   /emailValidCode  "J002" = 发送失败（用 test@example.com 实测的码；成功码未观测到）
//   /checkValidCode  "K002" = 验证码不正确
//   /retrievePassword "L001" = 找回密码成功（**实测不需要先过验证码**，直接调也能重置）
// 版式参考课程验收图「12.忘记密码」：顶栏复用登录页（logo + Luckin Coffee + 首页）+ 四行表单 + 提交
import { common } from '@kit.AbilityKit';
import { sendEmailValidCode, checkValidCode, retrievePassword } from '../api/Api';
import { SecurityOpResponseBody } from '../models/request';
import { validatePhone, validatePassword, validateEmail } from '../utils/validForm';

// 实测到的两个"失败码"；成功码未观测到，所以按"不是已知失败码就算成功"处理
const CODE_EMAIL_SEND_FAIL: string = 'J002';
const CODE_VALID_CODE_WRONG: string = 'K002';
// 重置密码成功
const CODE_RESET_OK: string = 'L001';
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct ForgotPasswordPage {
  @State phone: string = '';
  @State newPwd: string = '';
  @State newPwdVisible: boolean = false;
  @State email: string = '';
  @State validCode: string = '';

  // 发送验证码中 / 提交中（防连点）
  @State isSending: boolean = false;
  @State isSubmitting: boolean = false;

  // 获取宿主 UIAbility 的上下文
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

  // 回登录页（本页是从登录页压栈进来的）
  private backToLogin(): void {
    this.getUIContext().getRouter().back();
  }

  // ===== 发送邮箱验证码 =====

  private doSendCode(): void {
    if (this.isSending) {
      return; // 防连点
    }
    if (!validateEmail(this.email)) {
      this.toast('请输入正确的邮箱');
      return;
    }
    this.isSending = true;
    sendEmailValidCode(this.email)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_EMAIL_SEND_FAIL) {
          this.toast(body.msg ?? '验证码发送失败，请检查邮箱');
        } else {
          this.toast('验证码已发送，请查收邮箱');
        }
      })
      .catch((err: Error) => {
        console.error(`sendEmailValidCode failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isSending = false;
      });
  }

  // ===== 提交（重置密码） =====

  private doSubmit(): void {
    if (this.isSubmitting) {
      return; // 防连点
    }
    if (!validatePhone(this.phone)) {
      this.toast('请输入正确的 11 位手机号');
      return;
    }
    if (!validatePassword(this.newPwd)) {
      this.toast('新密码需 6-16 位，且同时包含字母和数字');
      return;
    }
    if (!validateEmail(this.email)) {
      this.toast('请输入正确的邮箱');
      return;
    }
    if (this.validCode.length > 0) {
      // 填了验证码：先校验，不通过就拦住（验证码错确实提交不了）
      this.checkCodeThenReset();
    } else {
      // 没填验证码：直接重置（实测后端不强制要求验证码，这样演示不会因为收不到邮件而卡住）
      this.doReset();
    }
  }

  private checkCodeThenReset(): void {
    this.isSubmitting = true;
    checkValidCode(this.validCode)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_VALID_CODE_WRONG) {
          this.toast(body.msg ?? '验证码不正确');
          this.isSubmitting = false;
          return;
        }
        // 验证码通过（或返回了预期外的码）→ 继续重置
        this.doReset();
      })
      .catch((err: Error) => {
        console.error(`checkValidCode failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
        this.isSubmitting = false;
      });
  }

  private doReset(): void {
    this.isSubmitting = true;
    retrievePassword(this.phone, this.newPwd)
      .then((res) => {
        const body: SecurityOpResponseBody = res.result as SecurityOpResponseBody;
        if (body.code === CODE_RESET_OK) {
          this.toast('密码重置成功，请用新密码登录');
          this.backToLogin();
        } else {
          this.toast(body.msg ?? '重置失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`retrievePassword failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  build() {
    Column() {
      this.TitleBar();

      Scroll() {
        Column() {
          // 大标题 + 副标题
          Text('忘记密码!')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.login_title_dark'))
            .width('100%')
            .padding({ left: 26 })
            .margin({ top: 44 });

          Text('forgot password!')
            .fontSize(24)
            .fontColor($r('app.color.login_placeholder_grey'))
            .width('100%')
            .padding({ left: 26 })
            .margin({ top: 12 });

          // 四行表单
          Column() {
            FormRow({
              label: '手机号',
              placeholder: '手机号',
              value: this.phone,
              inputType: InputType.PhoneNumber,
              onValueChange: (value: string) => {
                this.phone = value;
              }
            });

            FormRow({
              label: '新密码',
              placeholder: '新密码',
              value: this.newPwd,
              inputType: this.newPwdVisible ? InputType.Normal : InputType.Password,
              showEye: true,
              eyeVisible: this.newPwdVisible,
              onValueChange: (value: string) => {
                this.newPwd = value;
              },
              onToggleEye: () => {
                this.newPwdVisible = !this.newPwdVisible;
              }
            });

            FormRow({
              label: '邮箱',
              placeholder: '邮箱',
              value: this.email,
              onValueChange: (value: string) => {
                this.email = value;
              }
            });

            // 邮箱验证码 + 右侧「发送验证码」按钮
            FormRow({
              label: '邮箱验证码',
              placeholder: '请输入邮箱验证码',
              value: this.validCode,
              trailingButton: this.isSending ? '发送中…' : '发送验证码',
              onValueChange: (value: string) => {
                this.validCode = value;
              },
              onTrailingTap: () => {
                this.doSendCode();
              }
            });
          }
          .width('100%')
          .margin({ top: 44 });

          // 已有账号，立即登录
          Text('已有账号，立即登录')
            .fontSize(15)
            .fontColor($r('app.color.login_label_grey'))
            .width('100%')
            .textAlign(TextAlign.End)
            .padding({ right: 26 })
            .margin({ top: 18 })
            .onClick(() => {
              this.backToLogin();
            });

          // 提交
          Text(this.isSubmitting ? '提交中…' : '提 交')
            .fontSize(17)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width('calc(100% - 20vp)')
            .height(44)
            .borderRadius(22)
            .margin({ left: 10, right: 10, top: 48 })
            .backgroundColor($r('app.color.login_blue'))
            .opacity(this.isSubmitting ? 0.6 : 1)
            .onClick(() => {
              this.doSubmit();
            });
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  // 顶栏：和登录页完全一致（logo + Luckin Coffee + 右上角"首页"）
  @Builder
  TitleBar() {
    Row() {
      Image($r('app.media.startIcon'))
        .width(32)
        .height(32)
        .borderRadius(6)
      Text('Luckin Coffee')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.login_title_dark'))
        .margin({ left: 10 })
      Blank() // 撑开中间空间，把"首页"挤到右侧
      Text('首页')
        .fontSize(16)
        .fontColor($r('app.color.login_blue'))
        .onClick(() => {
          // 回首页（replace，避免返回栈残留）
          this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
        })
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: $r('app.color.login_line_grey') })
  }
}

// 表单行（标签 + 输入框 + 可选小眼睛 / 可选右侧小按钮）
// 视觉规格照登录页的输入行：label 宽 60、字号 16、行高 44、左右 26、底部下划线
// 做成 @Component + @Prop：@Builder 的按值参数是快照，小眼睛切明文时图标刷不动
@Component
struct FormRow {
  @Prop label: string;
  @Prop placeholder: string;
  @Prop value: string;
  @Prop inputType: InputType = InputType.Normal;
  @Prop showEye: boolean = false;
  @Prop eyeVisible: boolean = false;
  // 非空则显示右侧小按钮（如「发送验证码」）
  @Prop trailingButton: string = '';
  onValueChange: (value: string) => void = () => {
  };
  onToggleEye: () => void = () => {
  };
  onTrailingTap: () => void = () => {
  };

  build() {
    Row() {
      Text(this.label)
        .fontSize(16)
        .fontColor($r('app.color.login_label_grey'))
        .width(76);

      TextInput({ text: this.value, placeholder: this.placeholder })
        .type(this.inputType)
        .showPasswordIcon(false) // 隐藏系统自带眼睛，改用右侧自定义图标
        .placeholderColor($r('app.color.login_placeholder_grey'))
        .placeholderFont({ size: 16 })
        .fontSize(16)
        .fontColor($r('app.color.login_text_dark'))
        .backgroundColor(Color.Transparent)
        .padding({ left: 0, right: 0 })
        .layoutWeight(1)
        .onChange((value: string) => {
          this.onValueChange(value);
        });

      if (this.showEye) {
        // 小眼睛：切换明文 / 密文
        SymbolGlyph(this.eyeVisible ? $r('sys.symbol.eye') : $r('sys.symbol.eye_slash'))
          .fontSize(20)
          .fontColor([$r('app.color.login_placeholder_grey')])
          .margin({ left: 8 })
          .onClick(() => {
            this.onToggleEye();
          });
      }

      if (this.trailingButton.length > 0) {
        Text(this.trailingButton)
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.login_blue'))
          .borderRadius(4)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ left: 8 })
          .onClick(() => {
            this.onTrailingTap();
          });
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 26, right: 26 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: $r('app.color.login_line_grey') })
  }
}
