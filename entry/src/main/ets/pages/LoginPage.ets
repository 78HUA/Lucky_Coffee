// 登录/注册页（启动页）
// 结构：顶栏 + 欢迎语 + 登录表单 + 登录/注册按钮 + 底部上滑注册弹窗（bindSheet）
// 优化点：
//  1) 校验规则抽到 utils/validForm.ets（登录/注册/未来个人资料页共用）
//  2) 字段级红字报错 + hasValidated 开关：点过提交后才"边输入边实时校验"
//  3) 登录/注册接真实后端 /login /register（POST 参数由 Request 统一序列化）
//  4) 登录成功：token+手机号写入 Preferences（utils/Session.ets），replace 跳首页；
//     再次启动时若已有 token 直接进首页，否则回填上次登录手机号
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { loginAccount, registerAccount } from '../api/Api';
import { validatePhone, validatePassword, validateNickName } from '../utils/validForm';
import { saveLoginSession, loadSavedToken, loadSavedPhone } from '../utils/Session';
import { LoginResponseBody, AccountResponseBody } from '../models/request';

// 校验错误提示文案（集中在顶部，改文案不用翻代码）
const PHONE_ERR_MSG: string = '请输入正确的 11 位手机号';
const PWD_ERR_MSG: string = '密码需 6-16 位，且同时包含字母和数字';
const NICK_ERR_MSG: string = '昵称至少 2 个字符，且不能包含空格';
const NET_ERR_MSG: string = '网络异常，请稍后重试';

// 输入行参数：登录表单与注册弹窗复用同一个 @Builder FieldInput
interface FieldParams {
  label: string;
  placeholder: string;
  type: InputType;
  text: string;
  showEye: boolean; // 是否显示明文切换小眼睛（密码框才显示）
  eyeVisible: boolean; // 当前是否明文显示
  error: string; // 错误提示，非空时显示红字并把下划线变红
  onChange: (value: string) => void;
  onToggleEye: () => void;
}

@Entry
@Component
struct LoginPage {
  // ===== 登录表单 =====
  // 手机号
  @State phone: string = '';
  // 密码
  @State password: string = '';
  // 密码是否明文显示
  @State isPwdVisible: boolean = false;
  // 字段级错误提示（非空 = 不通过）
  @State phoneError: string = '';
  @State passwordError: string = '';
  // 是否点过"登录"（true 之后输入时才实时校验，避免一进页面就报红）
  @State hasValidated: boolean = false;
  // 登录请求中（防重复点击）
  @State isLoggingIn: boolean = false;

  // ===== 注册表单（字段与登录框隔离，注册成功后清空） =====
  // 注册弹窗是否显示（bindSheet 开关）
  @State showRegisterSheet: boolean = false;
  @State regNickname: string = '';
  @State regPhone: string = '';
  @State regPassword: string = '';
  @State regPwdVisible: boolean = false;
  @State regNicknameError: string = '';
  @State regPhoneError: string = '';
  @State regPasswordError: string = '';
  @State regHasValidated: boolean = false;
  // 注册请求中
  @State isRegistering: boolean = false;

  // 获取宿主 UIAbility 的上下文（Preferences 读写需要）
  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  // 启动时：本地已有 token 说明登录过 -> 直接进首页；否则回填上次登录的手机号
  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.hostContext();
    loadSavedToken(ctx).then((token: string) => {
      if (token.length > 0) {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
        return;
      }
      // 没登录过：把上次输入的手机号带回来，省得重敲
      loadSavedPhone(ctx).then((savedPhone: string) => {
        if (savedPhone.length > 0) {
          this.phone = savedPhone;
        }
      });
    });
  }

  // 弹出轻提示
  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`showToast failed, err=${JSON.stringify(err)}`);
    }
  }

  // 登录表单实时校验：有错就把红字写在对应输入框下面
  private validateLoginForm(): boolean {
    this.phoneError = validatePhone(this.phone) ? '' : PHONE_ERR_MSG;
    this.passwordError = validatePassword(this.password) ? '' : PWD_ERR_MSG;
    return this.phoneError === '' && this.passwordError === '';
  }

  // 点击登录：先本地校验，通过后请求后端 /login
  private doLogin(): void {
    // 这次点击开始"需要实时校验"
    this.hasValidated = true;
    if (this.isLoggingIn) {
      return;
    }
    if (!this.validateLoginForm()) {
      return;
    }

    this.isLoggingIn = true;
    loginAccount({ phone: this.phone, password: this.password })
      .then((res) => {
        const body: LoginResponseBody = res.result as LoginResponseBody;
        // 实测：登录成功码是 200，返回体带 token（加密字符串）
        if (body.code === 200 && body.token.length > 0) {
          const ctx: common.UIAbilityContext = this.hostContext();
          // 保存登录态 -> 弹提示 -> 进首页（replace 不留返回栈）
          saveLoginSession(ctx, body.token, this.phone).then(() => {
            this.toast('登录成功');
            this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
          });
        } else {
          // 失败时后端会返回 msg（如"手机号未注册"），直接展示给用户
          this.toast(body.msg.length > 0 ? body.msg : '登录失败，请重试');
        }
      })
      .catch(() => {
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoggingIn = false;
      });
  }

  // 清空注册表单（打开弹窗前 / 注册成功后 / 关闭弹窗时调用）
  private resetRegisterForm(): void {
    this.regNickname = '';
    this.regPhone = '';
    this.regPassword = '';
    this.regPwdVisible = false;
    this.regNicknameError = '';
    this.regPhoneError = '';
    this.regPasswordError = '';
    this.regHasValidated = false;
  }

  // 注册表单实时校验
  private validateRegisterForm(): boolean {
    this.regNicknameError = validateNickName(this.regNickname) ? '' : NICK_ERR_MSG;
    this.regPhoneError = validatePhone(this.regPhone) ? '' : PHONE_ERR_MSG;
    this.regPasswordError = validatePassword(this.regPassword) ? '' : PWD_ERR_MSG;
    return this.regNicknameError === '' && this.regPhoneError === '' && this.regPasswordError === '';
  }

  // 点击注册：先本地校验，通过后请求后端 /register
  private doRegister(): void {
    this.regHasValidated = true;
    if (this.isRegistering) {
      return;
    }
    if (!this.validateRegisterForm()) {
      return;
    }

    this.isRegistering = true;
    registerAccount({ nickName: this.regNickname, phone: this.regPhone, password: this.regPassword })
      .then((res) => {
        const body: AccountResponseBody = res.result as AccountResponseBody;
        // 实测：注册成功码是 100
        if (body.code === 100) {
          // 注册成功：手机号带到登录框（省一次输入），清空注册表单并关闭弹窗
          this.phone = this.regPhone;
          this.resetRegisterForm();
          this.showRegisterSheet = false;
          this.toast(body.msg.length > 0 ? body.msg : '注册成功，请登录');
        } else {
          this.toast(body.msg.length > 0 ? body.msg : '注册失败，请重试');
        }
      })
      .catch(() => {
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isRegistering = false;
      });
  }

  // 自定义构建函数：顶部导航栏（logo + 标题 + 右侧"首页"）
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
          // 跳转回首页（登录页是启动页，用 replace 避免返回栈残留）
          this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
        })
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: $r('app.color.login_line_grey') })
  }

  // 自定义构建函数：通用输入行（登录/注册都复用；错误时下划线变红 + 下方红字提示）
  @Builder
  FieldInput(params: FieldParams) {
    Column() {
      Row() {
        Text(params.label)
          .fontSize(16)
          .fontColor($r('app.color.login_label_grey'))
          .width(60)
        TextInput({ placeholder: params.placeholder, text: params.text })
          .type(params.type)
          .showPasswordIcon(false) // 隐藏系统自带眼睛，改用右侧自定义图标
          .placeholderColor($r('app.color.login_placeholder_grey'))
          .placeholderFont({ size: 16 })
          .fontSize(16)
          .fontColor($r('app.color.login_text_dark'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            params.onChange(value);
          })
        if (params.showEye) {
          // 小眼睛：点击切换明文/密文
          SymbolGlyph(params.eyeVisible ? $r('sys.symbol.eye') : $r('sys.symbol.eye_slash'))
            .fontSize(20)
            .fontColor([$r('app.color.login_placeholder_grey')])
            .margin({ left: 8 })
            .onClick(() => {
              params.onToggleEye();
            })
        }
      }
      .width('100%')
      .height(44)
      .padding({ left: 26, right: 26 })
      // 校验不通过时下划线变红，提示更醒目
      .border({
        width: { bottom: 1 },
        color: params.error.length > 0 ? $r('app.color.login_error_red') : $r('app.color.login_line_grey')
      })

      // 字段级错误提示：校验不通过才出现，长在对应输入框正下方
      if (params.error.length > 0) {
        Text(params.error)
          .fontSize(12)
          .fontColor($r('app.color.login_error_red'))
          .width('100%')
          .padding({ left: 26, right: 26, top: 4 })
          .textAlign(TextAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 自定义构建函数：胶囊按钮（登录/注册按钮与注册弹窗内提交按钮复用，isPrimary 区分主次样式）
  // loading=true 时半透明不可点击（防止请求期间重复提交）
  @Builder
  SubmitButton(title: string, isPrimary: boolean, loading: boolean, action: () => void) {
    Text(title)
      .fontSize(17)
      .fontColor(isPrimary ? Color.White : $r('app.color.login_text_dark'))
      .textAlign(TextAlign.Center)
      .width('100%')
      .height(44)
      .borderRadius(22)
      .margin({ top: 48, left: 10, right: 10 })
      .backgroundColor(isPrimary ? $r('app.color.login_blue') : Color.White)
      .border({
        width: 1,
        color: isPrimary ? Color.Transparent : $r('app.color.login_border_grey')
      })
      .opacity(loading ? 0.6 : 1)
      .onClick(() => {
        // 请求中禁止再次点击；点击行为由调用方传入
        if (!loading) {
          action();
        }
      })
  }

  // 自定义构建函数：注册弹窗整体内容（标题 + 三个输入行 + 提交按钮），作为 bindSheet 的内容
  @Builder
  RegisterSheetContent() {
    Column() {
      // 弹窗标题
      Text('注册账号')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.login_title_dark'))
        .margin({ top: 8, bottom: 24 })

      // 昵称输入行：点过"注册"后实时校验
      this.FieldInput({
        label: '昵称',
        placeholder: '请输入昵称',
        type: InputType.Normal,
        text: this.regNickname,
        showEye: false,
        eyeVisible: false,
        error: this.regNicknameError,
        onChange: (value: string) => {
          this.regNickname = value;
          if (this.regHasValidated) {
            this.regNicknameError = validateNickName(value) ? '' : NICK_ERR_MSG;
          }
        },
        onToggleEye: () => {
        }
      })
      // 手机号输入行
      this.FieldInput({
        label: '手机号',
        placeholder: '请输入手机号',
        type: InputType.PhoneNumber,
        text: this.regPhone,
        showEye: false,
        eyeVisible: false,
        error: this.regPhoneError,
        onChange: (value: string) => {
          this.regPhone = value;
          if (this.regHasValidated) {
            this.regPhoneError = validatePhone(value) ? '' : PHONE_ERR_MSG;
          }
        },
        onToggleEye: () => {
        }
      })
      // 密码输入行（带明文切换小眼睛）
      this.FieldInput({
        label: '密码',
        placeholder: '请设置密码',
        type: this.regPwdVisible ? InputType.Normal : InputType.Password,
        text: this.regPassword,
        showEye: true,
        eyeVisible: this.regPwdVisible,
        error: this.regPasswordError,
        onChange: (value: string) => {
          this.regPassword = value;
          if (this.regHasValidated) {
            this.regPasswordError = validatePassword(value) ? '' : PWD_ERR_MSG;
          }
        },
        onToggleEye: () => {
          this.regPwdVisible = !this.regPwdVisible;
        }
      })

      // 提交按钮：请求中显示"注册中..."且不可重复点击
      this.SubmitButton(this.isRegistering ? '注册中...' : '注册', true, this.isRegistering, () => {
        this.doRegister();
      })
    }
    .width('100%')
    .padding({ bottom: 32 })
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TitleBar()

      // 欢迎语
      Text('欢迎回来!')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.login_title_dark'))
        .width('100%')
        .padding({ left: 12 })
        .margin({ top: 96 })
      Text('Please login to your accounts')
        .fontSize(17)
        .fontColor($r('app.color.grey_color'))
        .width('100%')
        .padding({ left: 12 })
        .margin({ top: 16 })

      // 手机号 / 密码 输入行（带字段级红字报错）
      Column() {
        this.FieldInput({
          label: '手机号',
          placeholder: '手机号',
          type: InputType.PhoneNumber,
          text: this.phone,
          showEye: false,
          eyeVisible: false,
          error: this.phoneError,
          onChange: (value: string) => {
            this.phone = value;
            if (this.hasValidated) {
              this.phoneError = validatePhone(value) ? '' : PHONE_ERR_MSG;
            }
          },
          onToggleEye: () => {
          }
        })
        this.FieldInput({
          label: '密码',
          placeholder: '密码',
          type: this.isPwdVisible ? InputType.Normal : InputType.Password,
          text: this.password,
          showEye: true,
          eyeVisible: this.isPwdVisible,
          error: this.passwordError,
          onChange: (value: string) => {
            this.password = value;
            if (this.hasValidated) {
              this.passwordError = validatePassword(value) ? '' : PWD_ERR_MSG;
            }
          },
          onToggleEye: () => {
            this.isPwdVisible = !this.isPwdVisible;
          }
        })
      }
      .width('100%')
      .margin({ top: 48 })

      // 忘记密码
      Text('忘记密码?')
        .fontSize(15)
        .fontColor($r('app.color.login_label_grey'))
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ right: 14 })
        .margin({ top: 20 })
        .onClick(() => {
          this.toast('请联系管理员重置密码');
        })

      // 登录按钮：请求中显示"登录中..."且不可重复点击
      this.SubmitButton(this.isLoggingIn ? '登录中...' : '登录', true, this.isLoggingIn, () => {
        this.doLogin();
      })
      // 注册按钮：打开弹窗前先清一遍表单，保证每次打开都是全新表单
      this.SubmitButton('注册', false, false, () => {
        this.resetRegisterForm();
        this.showRegisterSheet = true;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    // 底部上滑注册弹窗：注册内容由自定义构建函数 RegisterSheetContent 提供；
    // 下滑/手势关闭时把表单清干净，避免下次打开残留上次内容
    .bindSheet($$this.showRegisterSheet, this.RegisterSheetContent(), {
      height: '65%',
      dragBar: true,
      showClose: false,
      backgroundColor: Color.White,
      onWillDismiss: (dismiss) => {
        this.resetRegisterForm();
        dismiss.dismiss();
      }
    })
  }
}
