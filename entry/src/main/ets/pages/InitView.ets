import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { SystemCheckService, CheckResult } from '../services/SystemCheckService';
import { AppConstants } from '../constants/AppConstants';

// 检查项状态枚举
enum CheckStatus {
  LOADING = 'loading',
  SUCCESS = 'success',
  FAILED = 'failed'
}

// 检查项接口
interface CheckItem {
  id: string;
  name: string;
  status: CheckStatus;
  errorMsg?: string;
  solution?: string;
}

// 检查结果接口
interface PerformCheckResult {
  success: boolean;
  errorMsg?: string;
}

// 路由参数接口
interface RouterOptions {
  url: string;
}

// Toast参数接口
interface ToastOptions {
  message: string;
  duration: number;
}

@Entry
@Component
struct InitView {
  @State checkItems: CheckItem[] = [
    {
      id: AppConstants.CHECK_ITEMS.FS.id,
      name: AppConstants.CHECK_ITEMS.FS.name,
      status: CheckStatus.LOADING,
      solution: AppConstants.CHECK_ITEMS.FS.solution
    },
    {
      id: AppConstants.CHECK_ITEMS.DB.id,
      name: AppConstants.CHECK_ITEMS.DB.name,
      status: CheckStatus.LOADING,
      solution: AppConstants.CHECK_ITEMS.DB.solution
    },
    {
      id: AppConstants.CHECK_ITEMS.AGV.id,
      name: AppConstants.CHECK_ITEMS.AGV.name,
      status: CheckStatus.LOADING,
      solution: AppConstants.CHECK_ITEMS.AGV.solution
    },
    {
      id: AppConstants.CHECK_ITEMS.CAM.id,
      name: AppConstants.CHECK_ITEMS.CAM.name,
      status: CheckStatus.LOADING,
      solution: AppConstants.CHECK_ITEMS.CAM.solution
    }
  ];
  
  @State allChecksPassed: boolean = false;
  @State showSettings: boolean = false;
  @State isChecking: boolean = false;
  @State expandedItems: Set<string> = new Set();

  aboutToAppear() {
    this.startSystemCheck();
  }

  // 开始系统检查
  async startSystemCheck() {
    console.info('[InitView] 开始系统自检流程');
    this.isChecking = true;
    this.allChecksPassed = false;
    
    // 重置所有检查项状态
    const newCheckItems: CheckItem[] = [];
    for (let i = 0; i < this.checkItems.length; i++) {
      const item = this.checkItems[i];
      const newItem: CheckItem = {
        id: item.id,
        name: item.name,
        status: CheckStatus.LOADING,
        errorMsg: item.errorMsg,
        solution: item.solution
      };
      newCheckItems.push(newItem);
    }
    this.checkItems = newCheckItems;

    // 依次执行检查
    for (let i = 0; i < this.checkItems.length; i++) {
      console.info(`[InitView] 开始检查项目: ${this.checkItems[i].id}`);
      await this.checkSingleItem(this.checkItems[i].id, i);
      await this.delay(500); // 模拟检查间隔
    }

    this.isChecking = false;
    this.checkAllPassed();
    console.info('[InitView] 系统自检流程完成');
  }

  // 检查单个项目
  async checkSingleItem(itemId: string, index: number) {
    try {
      const result = await this.performCheck(itemId);
      
      // 创建新的数组来触发@State更新
      const newCheckItems: CheckItem[] = [...this.checkItems];
      const currentItem = newCheckItems[index];
      const updatedItem: CheckItem = {
        id: currentItem.id,
        name: currentItem.name,
        status: result.success ? CheckStatus.SUCCESS : CheckStatus.FAILED,
        errorMsg: result.errorMsg,
        solution: currentItem.solution
      };
      newCheckItems[index] = updatedItem;
      this.checkItems = newCheckItems;
      
      // 强制触发UI更新
      setTimeout(() => {
        this.checkItems = [...this.checkItems];
      }, 10);
      
      console.info(`[InitView] 检查项目 ${itemId} 完成，状态: ${updatedItem.status}`);
      
      // 如果检查失败，自动展开该项
      if (!result.success) {
        this.expandedItems.add(itemId);
      }
    } catch (error) {
      // 创建新的数组来触发@State更新
      const newCheckItems: CheckItem[] = [...this.checkItems];
      const currentItem = newCheckItems[index];
      const updatedItem: CheckItem = {
        id: currentItem.id,
        name: currentItem.name,
        status: CheckStatus.FAILED,
        errorMsg: '检查过程中发生错误',
        solution: currentItem.solution
      };
      newCheckItems[index] = updatedItem;
      this.checkItems = newCheckItems;
      
      // 强制触发UI更新
      setTimeout(() => {
        this.checkItems = [...this.checkItems];
      }, 10);
      
      console.error(`[InitView] 检查项目 ${itemId} 异常:`, error);
      this.expandedItems.add(itemId);
    }
  }

  // 执行具体检查逻辑
  async performCheck(itemId: string): Promise<PerformCheckResult> {
    try {
      let result: CheckResult;
      
      switch (itemId) {
        case 'fs':
          result = await SystemCheckService.checkFileSystem();
          break;
        case 'db':
          result = await SystemCheckService.checkDatabase();
          break;
        case 'agv':
          result = await SystemCheckService.checkAgv();
          break;
        case 'cam':
          result = await SystemCheckService.checkCamera();
          break;
        default:
          const defaultResult: PerformCheckResult = { success: false, errorMsg: '未知检查项' };
          return defaultResult;
      }

      const checkResult: PerformCheckResult = {
        success: result.success,
        errorMsg: result.message
      };
      return checkResult;
    } catch (error) {
      console.error(`检查${itemId}失败:`, error);
      const errorResult: PerformCheckResult = { success: false, errorMsg: '网络连接失败' };
      return errorResult;
    }
  }

  // 检查是否全部通过
  checkAllPassed() {
    this.allChecksPassed = this.checkItems.every(item => item.status === CheckStatus.SUCCESS);
  }

  // 延时函数
  delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  // 切换检查项展开状态
  toggleExpanded(itemId: string) {
    if (this.expandedItems.has(itemId)) {
      this.expandedItems.delete(itemId);
    } else {
      this.expandedItems.add(itemId);
    }
  }

  // 进入系统
  enterSystem() {
    if (this.allChecksPassed) {
      const routerOptions: RouterOptions = {
        url: AppConstants.ROUTES.TASK_LIST
      };
      router.pushUrl(routerOptions).catch((err: Error) => {
        const toastOptions: ToastOptions = {
          message: '页面跳转失败',
          duration: 2000
        };
        promptAction.showToast(toastOptions);
      });
    }
  }

  // 打开设置
  openSettings() {
    this.showSettings = true;
  }

  // 关闭设置
  closeSettings() {
    this.showSettings = false;
  }

  // 重新检测
  recheck() {
    this.expandedItems.clear();
    this.startSystemCheck();
  }

  // 跳过系统自检（测试用）
  skipSystemCheck() {
    this.isChecking = false;
    // 将所有检查项设置为成功状态
    const newCheckItems: CheckItem[] = [];
    for (let i = 0; i < this.checkItems.length; i++) {
      const item = this.checkItems[i];
      const newItem: CheckItem = {
        id: item.id,
        name: item.name,
        status: CheckStatus.SUCCESS,
        solution: item.solution
      };
      newCheckItems.push(newItem);
    }
    this.checkItems = newCheckItems;
    this.allChecksPassed = true;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 主内容
      Column() {
        // 标题
        Text('AGV智能巡检系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .margin({ bottom: 40 })

        // 检查项列表
        Column({ space: 10 }) {
          ForEach(this.checkItems, (item: CheckItem) => {
            Column() {
              // 检查项头部
              Row() {
                // 状态图标
                Row() {
                  if (item.status === CheckStatus.LOADING) {
                    LoadingProgress()
                      .width(16)
                      .height(16)
                      .color('#409eff')
                  } else if (item.status === CheckStatus.SUCCESS) {
                    Text('✓')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .textAlign(TextAlign.Center)
                      .width(20)
                      .height(20)
                      .borderRadius(10)
                      .backgroundColor(AppConstants.COLORS.SUCCESS)
                  } else {
                    Text('✕')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .textAlign(TextAlign.Center)
                      .width(20)
                      .height(20)
                      .borderRadius(10)
                      .backgroundColor(AppConstants.COLORS.DANGER)
                  }
                }
                .width(20)
                .height(20)
                .margin({ right: 10 })

                // 检查项名称
                Text(item.name)
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)

                Blank()
              }
              .width('100%')
              .height(44)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#fafafa')
              .border({ width: { bottom: 1 }, color: '#eeeeee' })
              .onClick(() => {
                if (item.status === CheckStatus.FAILED) {
                  this.toggleExpanded(item.id);
                }
              })

              // 解决方案内容（失败时显示）
              if (item.status === CheckStatus.FAILED && this.expandedItems.has(item.id)) {
                Column() {
                  Text(item.solution || '请联系技术支持')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width('100%')
                    .padding(16)
                }
                .width('100%')
                .backgroundColor(Color.White)
              }
            }
            .width('100%')
            .border({ width: 1, color: '#dddddd', radius: 4 })
            .margin({ bottom: 10 })
          }, (item: CheckItem) => `${item.id}_${item.status}`)
        }
        .width('100%')
        .margin({ bottom: 40 })

        // 操作按钮组
        Row({ space: 10 }) {
          // 设置按钮
          Button() {
            Text('⚙')
              .fontSize(16)
              .fontColor('#666666')
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#ffffff')
          .border({ width: 1, color: '#dddddd' })
          .onClick(() => this.openSettings())

          // 跳过自检按钮（测试用）
          Button('跳过自检')
            .fontSize(12)
            .fontColor('#ffffff')
            .backgroundColor('#ff6b6b')
            .border({ width: 1, color: '#ff6b6b' })
            .enabled(!this.allChecksPassed)
            .onClick(() => this.skipSystemCheck())



          // 进入系统按钮
          Button('进入系统')
            .fontSize(14)
            .fontColor(this.allChecksPassed ? '#ffffff' : '#999999')
            .backgroundColor(this.allChecksPassed ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.BACKGROUND_BASE)
            .border({ width: 1, color: this.allChecksPassed ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.BORDER_BASE })
            .enabled(this.allChecksPassed)
            .onClick(() => this.enterSystem())

          // 重新检测按钮
          Button('重新检测')
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor(AppConstants.COLORS.PRIMARY)
            .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
            .enabled(!this.isChecking)
            .onClick(() => this.recheck())
        }
        .justifyContent(FlexAlign.Center)
      }
      .width(400)
      .padding(30)
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 2 })

      // 设置模态框
      if (this.showSettings) {
        Column() {
          Column() {
            // 模态框头部
            Row() {
              Text('设置')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)

              Button('✕')
                .fontSize(16)
                .fontColor('#999999')
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .onClick(() => this.closeSettings())
            }
            .width('100%')
            .height(50)
            .padding({ left: 20, right: 20 })
            .border({ width: { bottom: 1 }, color: '#eeeeee' })

            // 设置内容区域
            Column() {
              Text('[SettingsView 组件内容]')
                .fontSize(14)
                .fontColor('#666666')
                .textAlign(TextAlign.Center)
                .margin({ top: 40, bottom: 40 })
            }
            .width('100%')
            .layoutWeight(1)

            // 模态框底部按钮
            Row({ space: 10 }) {
              Button('取消')
                .fontSize(14)
                .fontColor('#666666')
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#dddddd' })
                .onClick(() => this.closeSettings())

              Button('保存')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.PRIMARY)
                .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                .onClick(() => {
                  // TODO: 保存设置逻辑
                  this.closeSettings();
                  promptAction.showToast({
                    message: '设置已保存',
                    duration: 2000
                  });
                })
            }
            .justifyContent(FlexAlign.End)
            .width('100%')
            .padding(20)
          }
          .width(600)
          .height(400)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.closeSettings())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }
}