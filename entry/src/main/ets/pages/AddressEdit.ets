// 新增 / 编辑收货地址页
// 入口：订单结算页 → 地址弹窗 →「新增地址」或某行的「编辑」
// 数据来源：/addAddress（成功码 9000）、/editAddress（30000）、/deleteAddress（10000）、
//          /findAddressByAid（40000）—— 成功码均为 2026-09-23 测试账号实测
// 版式参考课程验收图「5.新增地址1/2/3」
import { common } from '@kit.AbilityKit';
import { addAddress, editAddress, deleteAddress, findAddressByAid } from '../api/Api';
import {
  AddressItem, AddressListResponseBody, AddressOpResponseBody,
  AddAddressBody, EditAddressBody
} from '../models/request';
import { loadSavedToken } from '../utils/Session';
import { validatePhone } from '../utils/validForm';
import {
  provinceNames, cityNames, districtNames, areaCodeOf
} from '../utils/RegionData';
import FormField from '../components/FormField';

const CODE_ADDRESS_BY_AID: number = 40000;
const CODE_ADD_OK: number = 9000;
const CODE_EDIT_OK: number = 30000;
const CODE_DELETE_OK: number = 10000;
const NET_ERR_MSG: string = '网络异常，请稍后重试';

@Entry
@Component
struct AddressEdit {
  // 地址 id：空 = 新增，有值 = 编辑
  @State aid: string = '';
  @State tokenString: string = '';

  // ===== 表单字段 =====
  @State name: string = '';
  @State tel: string = '';
  @State province: string = '';
  @State city: string = '';
  @State county: string = '';
  @State addressDetail: string = '';
  @State postalCode: string = '';
  @State isDefault: boolean = false;

  @State isSaving: boolean = false;
  @State isLoading: boolean = false;

  // ===== 省市区选择器 =====
  @State showRegionSheet: boolean = false;
  // 第一列（省）是固定的
  @State provinceList: string[] = provinceNames();
  // 第二、三列随上面的选择变化
  @State cityList: string[] = [];
  @State countyList: string[] = [];
  // 选择器里当前高亮的三列值（点"确认"才写回表单）
  @State pickProvince: string = '';
  @State pickCity: string = '';
  @State pickCounty: string = '';

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

  // 页面标题：有 aid 是编辑，没有是新增
  private pageTitle(): string {
    return this.aid.length > 0 ? '编辑地址' : '新增地址';
  }

  // 「地区」那一行显示的内容：广东省/广州市/天河区
  private regionText(): string {
    if (this.province.length === 0 || this.city.length === 0 || this.county.length === 0) {
      return '';
    }
    return `${this.province}/${this.city}/${this.county}`;
  }

  aboutToAppear(): void {
    // 取路由参数：aid 为空 = 新增
    const params: Record<string, string> | undefined =
      this.getUIContext().getRouter().getParams() as Record<string, string> | undefined;
    const aidParam: string | undefined = params?.aid;
    if (aidParam !== undefined) {
      this.aid = aidParam;
    }
    loadSavedToken(this.hostContext()).then((token: string) => {
      this.tokenString = token;
      if (this.aid.length > 0) {
        this.fetchAddress();
      }
    });
  }

  // 编辑模式：按 aid 拉出这条地址回填表单
  private fetchAddress(): void {
    this.isLoading = true;
    findAddressByAid(this.tokenString, this.aid)
      .then((res) => {
        const body: AddressListResponseBody = res.result as AddressListResponseBody;
        // 注意：这个接口的 result 也是数组，要取 [0]
        if (body.code === CODE_ADDRESS_BY_AID) {
          const list: AddressItem[] = body.result ?? [];
          if (list.length > 0) {
            const a: AddressItem = list[0];
            this.name = a.name;
            this.tel = a.tel;
            this.province = a.province;
            this.city = a.city;
            this.county = a.county;
            this.addressDetail = a.addressDetail;
            this.postalCode = a.postalCode;
            this.isDefault = a.isDefault === 1;
          }
        } else {
          this.toast(body.msg ?? '地址加载失败');
        }
      })
      .catch((err: Error) => {
        console.error(`findAddressByAid failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // 保存（新增 / 编辑走不同接口）
  private doSave(): void {
    if (this.isSaving) {
      return; // 防连点
    }
    if (this.name.trim().length === 0) {
      this.toast('请填写收货人姓名');
      return;
    }
    if (!validatePhone(this.tel)) {
      this.toast('请填写正确的 11 位手机号');
      return;
    }
    if (this.regionText().length === 0) {
      this.toast('请选择所在地区');
      return;
    }
    if (this.addressDetail.trim().length === 0) {
      this.toast('请填写详细地址');
      return;
    }
    // 行政区划代码：实测后端不校验，但能给就给（真实代码）
    const areaCode: string = areaCodeOf(this.province, this.city, this.county);
    const isDefaultValue: number = this.isDefault ? 1 : 0;
    this.isSaving = true;
    if (this.aid.length > 0) {
      const body: EditAddressBody = {
        tokenString: this.tokenString, aid: this.aid, name: this.name, tel: this.tel,
        province: this.province, city: this.city, county: this.county,
        addressDetail: this.addressDetail, areaCode: areaCode,
        postalCode: this.postalCode, isDefault: isDefaultValue
      };
      editAddress(body)
        .then((res) => {
          const resp: AddressOpResponseBody = res.result as AddressOpResponseBody;
          if (resp.code === CODE_EDIT_OK) {
            this.toast('保存成功');
            this.back();
          } else {
            this.toast(resp.msg ?? '保存失败，请重试');
          }
        })
        .catch((err: Error) => {
          console.error(`editAddress failed, err=${JSON.stringify(err)}`);
          this.toast(NET_ERR_MSG);
        })
        .finally(() => {
          this.isSaving = false;
        });
    } else {
      const body: AddAddressBody = {
        tokenString: this.tokenString, name: this.name, tel: this.tel,
        province: this.province, city: this.city, county: this.county,
        addressDetail: this.addressDetail, areaCode: areaCode,
        postalCode: this.postalCode, isDefault: isDefaultValue
      };
      addAddress(body)
        .then((res) => {
          const resp: AddressOpResponseBody = res.result as AddressOpResponseBody;
          if (resp.code === CODE_ADD_OK) {
            this.toast('保存成功');
            this.back();
          } else {
            this.toast(resp.msg ?? '保存失败，请重试');
          }
        })
        .catch((err: Error) => {
          console.error(`addAddress failed, err=${JSON.stringify(err)}`);
          this.toast(NET_ERR_MSG);
        })
        .finally(() => {
          this.isSaving = false;
        });
    }
  }

  // 删除前先确认（参考图没画这一步，但删数据不该一点就没）
  private confirmDelete(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '删除地址',
      message: '确定要删除这个收货地址吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#DC2626' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.doDelete();
      }
    }).catch((err: Error) => {
      console.error(`showDialog failed, err=${JSON.stringify(err)}`);
    });
  }

  private doDelete(): void {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    deleteAddress(this.tokenString, this.aid)
      .then((res) => {
        const resp: AddressOpResponseBody = res.result as AddressOpResponseBody;
        if (resp.code === CODE_DELETE_OK) {
          this.toast('已删除');
          this.back();
        } else {
          this.toast(resp.msg ?? '删除失败，请重试');
        }
      })
      .catch((err: Error) => {
        console.error(`deleteAddress failed, err=${JSON.stringify(err)}`);
        this.toast(NET_ERR_MSG);
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  // ===== 省市区选择器 =====

  // 打开选择器：用表单里已有的地区初始化，没选过就默认每个列表的第一项
  private openRegionSheet(): void {
    const p: string = this.province.length > 0 ? this.province : this.provinceList[0];
    this.pickProvince = p;
    this.cityList = cityNames(p);
    const c: string = this.city.length > 0 ? this.city : this.cityList[0];
    this.pickCity = c;
    this.countyList = districtNames(p, c);
    this.pickCounty = this.county.length > 0 ? this.county : this.countyList[0];
    this.showRegionSheet = true;
  }

  // 换省 → 市列表刷新、区列表跟着重置
  private pickProvinceChanged(value: string): void {
    this.pickProvince = value;
    this.cityList = cityNames(value);
    this.pickCity = this.cityList.length > 0 ? this.cityList[0] : '';
    this.countyList = districtNames(value, this.pickCity);
    this.pickCounty = this.countyList.length > 0 ? this.countyList[0] : '';
  }

  // 换市 → 区列表刷新
  private pickCityChanged(value: string): void {
    this.pickCity = value;
    this.countyList = districtNames(this.pickProvince, value);
    this.pickCounty = this.countyList.length > 0 ? this.countyList[0] : '';
  }

  private pickCountyChanged(value: string): void {
    this.pickCounty = value;
  }

  // 确认：把选择器里的三列写回表单
  private confirmRegion(): void {
    this.province = this.pickProvince;
    this.city = this.pickCity;
    this.county = this.pickCounty;
    this.showRegionSheet = false;
  }

  // ===== 界面 =====

  build() {
    Column() {
      this.TopBar();

      Scroll() {
        Column() {
          this.FormCard();
          this.DefaultCard();
          this.Buttons();
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_grey'))
    // 省市区选择器弹窗
    .bindSheet($$this.showRegionSheet, this.RegionSheetContent(), {
      height: '50%',
      dragBar: false,
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

      Text(this.pageTitle())
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

  // 表单卡片：姓名 / 电话 / 地区 / 详细地址 / 邮政编码
  @Builder
  FormCard() {
    Column() {
      FormField({
        label: '姓名',
        placeholder: '姓名',
        value: this.name,
        onValueChange: (value: string) => {
          this.name = value;
        }
      })

      Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

      FormField({
        label: '电话',
        placeholder: '电话',
        value: this.tel,
        inputType: InputType.PhoneNumber,
        onValueChange: (value: string) => {
          this.tel = value;
        }
      })

      Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

      // 地区：只读行，点了弹三列选择器
      FormField({
        label: '地区',
        placeholder: '地区',
        value: this.regionText(),
        readonlyRow: true,
        onRowTap: () => {
          this.openRegionSheet();
        }
      })

      Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

      FormField({
        label: '详细地址',
        placeholder: '详细地址',
        value: this.addressDetail,
        onValueChange: (value: string) => {
          this.addressDetail = value;
        }
      })

      Divider().strokeWidth(1).color($r('app.color.detail_divider')).margin({ left: 16 })

      FormField({
        label: '邮政编码',
        placeholder: '邮政编码',
        value: this.postalCode,
        inputType: InputType.Number,
        onValueChange: (value: string) => {
          this.postalCode = value;
        }
      })
    }
    .width('calc(100% - 24vp)')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  // 设为默认收货地址
  @Builder
  DefaultCard() {
    Row() {
      Text('设为默认收货地址')
        .fontSize(15)
        .fontColor($r('app.color.detail_text_dark'))
        .layoutWeight(1);

      Toggle({ type: ToggleType.Switch, isOn: this.isDefault })
        .selectedColor($r('app.color.theme_blue'))
        .onChange((isOn: boolean) => {
          this.isDefault = isOn;
        });
    }
    .width('calc(100% - 24vp)')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  // 保存 / 删除按钮
  @Builder
  Buttons() {
    Column() {
      Button(this.isSaving ? '保存中…' : '保存')
        .width('100%')
        .height(46)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.login_blue'))
        .borderRadius(23)
        .opacity(this.isSaving ? 0.6 : 1)
        .onClick(() => {
          this.doSave();
        });

      // 编辑模式才有删除
      if (this.aid.length > 0) {
        Button('删除')
          .width('100%')
          .height(46)
          .fontSize(17)
          .fontColor($r('app.color.detail_text_dark'))
          .backgroundColor(Color.White)
          .borderRadius(23)
          .border({ width: 1, color: $r('app.color.login_border_grey') })
          .margin({ top: 16 })
          .onClick(() => {
            this.confirmDelete();
          });
      }
    }
    .width('calc(100% - 24vp)')
    .margin({ left: 12, right: 12, top: 24, bottom: 24 })
  }

  // 省市区选择器弹窗：取消 / 确认 + 三列
  @Builder
  RegionSheetContent() {
    Column() {
      // 顶部：取消 + 确认（对齐验收图）
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.theme_blue'))
          .onClick(() => {
            this.showRegionSheet = false;
          });
        Blank();
        Text('确认')
          .fontSize(16)
          .fontColor($r('app.color.theme_blue'))
          .onClick(() => {
            this.confirmRegion();
          });
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center);

      // 三列：省 / 市 / 区
      Row() {
        PickerColumn({
          items: this.provinceList,
          selected: this.pickProvince,
          onPick: (value: string) => {
            this.pickProvinceChanged(value);
          }
        });

        PickerColumn({
          items: this.cityList,
          selected: this.pickCity,
          onPick: (value: string) => {
            this.pickCityChanged(value);
          }
        });

        PickerColumn({
          items: this.countyList,
          selected: this.pickCounty,
          onPick: (value: string) => {
            this.pickCountyChanged(value);
          }
        });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
  }
}

// 选择器的一列：一个可滚动的列表，点哪一项就选哪一项
// 做成 @Component + @Prop（和 SpecRow / CartItemCard 同一套路），保证高亮跟着父组件刷新
@Component
struct PickerColumn {
  @Prop items: string[];
  @Prop selected: string;
  onPick: (value: string) => void = () => {
  };

  build() {
    List() {
      ForEach(this.items, (item: string) => {
        ListItem() {
          Text(item)
            .fontSize(15)
            .fontWeight(item === this.selected ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(item === this.selected
              ? $r('app.color.theme_blue')
              : $r('app.color.detail_text_dark'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.onPick(item);
            });
        }
      }, (item: string) => item)
    }
    .layoutWeight(1)
    .height('100%')
    .scrollBar(BarState.Off)
  }
}
