// 公共表单输入行（标签 + 输入框 / 或只读值 + 右箭头）
// 抽出来给地址表单用；后续「个人资料」「安全中心」等表单页可直接复用。
// 为什么是 @Component + @Prop 而不是 @Builder：
//   @Builder 的基础类型参数是"值快照"，父组件状态变化不会重新传进来
//   （比如选完省市区要回填"地区"那一行），子组件 + @Prop 才会跟着刷新。
@Component
export default struct FormField {
  @Prop label: string;
  @Prop placeholder: string;
  @Prop value: string;
  // 输入框类型（姓名=Normal、电话=PhoneNumber、邮编=Number 等）
  @Prop inputType: InputType = InputType.Normal;
  // 只读行（如"地区"）：不显示输入框，显示值 + 右侧箭头，点击由 onRowTap 处理
  @Prop readonlyRow: boolean = false;
  onValueChange: (value: string) => void = () => {
  };
  onRowTap: () => void = () => {
  };

  build() {
    Row() {
      Text(this.label)
        .fontSize(15)
        .fontColor($r('app.color.detail_text_grey'))
        .width(76);

      if (this.readonlyRow) {
        // 只读行：没值时显示灰色占位
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(15)
          .fontColor(this.value.length > 0
            ? $r('app.color.detail_text_dark')
            : $r('app.color.login_placeholder_grey'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Text('>')
          .fontSize(16)
          .fontColor($r('app.color.grey_color'));
      } else {
        TextInput({ text: this.value, placeholder: this.placeholder })
          .type(this.inputType)
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
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onRowTap();
    })
  }
}
