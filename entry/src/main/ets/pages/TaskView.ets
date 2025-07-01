import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct TaskView {
  @State message: string = '任务列表页面';

  aboutToAppear() {
    console.info('TaskView页面加载');
  }

  build() {
    Column() {
      // 页面标题
      Row() {
        Button('返回')
          .fontSize(14)
          .onClick(() => {
            router.back();
          })
        
        Text('任务管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('设置')
          .fontSize(14)
          .onClick(() => {
            promptAction.showToast({
              message: '设置功能开发中',
              duration: 2000
            });
          })
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: '#eeeeee' })

      // 主要内容区域
      Column() {
        Text(this.message)
          .fontSize(18)
          .fontColor('#333333')
          .margin({ top: 100 })
        
        Text('此页面正在开发中...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}