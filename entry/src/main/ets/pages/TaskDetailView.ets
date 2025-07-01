import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 故障状态枚举
enum FlawStatus {
  CONFIRMED = 'confirmed',
  SUSPECTED = 'suspected', 
  FALSE_POSITIVE = 'false_positive'
}

// 故障接口
interface Flaw {
  id: number;
  taskId: number;
  round: number;
  flawType: string;
  flawName: string;
  flawDesc: string;
  flawImage: string;
  position: number;
  status: FlawStatus;
  remark?: string;
  createTime: string;
}

// 任务接口
interface Task {
  id: number;
  taskNo: string;
  taskName: string;
  startLocation: string;
  endLocation: string;
  distance: number;
  creator: string;
  executor: string;
  status: string;
  createTime: string;
  startTime?: string;
  endTime?: string;
}

@Entry
@Component
struct TaskDetailView {
  @State task: Task | null = null;
  @State flaws: Flaw[] = [];
  @State currentFlawIndex: number = 0;
  @State showFlawDetail: boolean = false;
  @State selectedFlaw: Flaw | null = null;
  @State loading: boolean = true;
  @State confirmedCount: number = 0;
  @State suspectedCount: number = 0;
  @State falsePositiveCount: number = 0;
  
  private taskId: number = 0;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['taskId']) {
      this.taskId = params['taskId'] as number;
      this.loadTaskDetail();
      this.loadFlaws();
    }
  }

  async loadTaskDetail() {
    try {
      const response = await HttpUtil.get(`/agv/task/${this.taskId}`);
      if (response.code === 200) {
        this.task = response.data as Task;
      }
    } catch (error) {
      console.error('加载任务详情失败:', error);
    }
  }

  async loadFlaws() {
    try {
      const response = await HttpUtil.get(`/agv/flaw/list?taskId=${this.taskId}`);
      if (response.code === 200) {
        this.flaws = response.data?.rows || [];
        this.updateFlawCounts();
      }
    } catch (error) {
      console.error('加载故障列表失败:', error);
    } finally {
      this.loading = false;
    }
  }

  updateFlawCounts() {
    this.confirmedCount = this.flaws.filter(f => f.status === FlawStatus.CONFIRMED).length;
    this.suspectedCount = this.flaws.filter(f => f.status === FlawStatus.SUSPECTED).length;
    this.falsePositiveCount = this.flaws.filter(f => f.status === FlawStatus.FALSE_POSITIVE).length;
  }

  selectFlaw(index: number) {
    this.currentFlawIndex = index;
  }

  openFlawDetail(flaw: Flaw) {
    this.selectedFlaw = flaw;
    this.showFlawDetail = true;
  }

  closeFlawDetail() {
    this.showFlawDetail = false;
    this.selectedFlaw = null;
  }

  async updateFlawStatus(flawId: number, status: FlawStatus, remark?: string) {
    try {
      const updateData = {
        id: flawId,
        status: status,
        remark: remark
      };
      
      const response = await HttpUtil.put('/agv/flaw', updateData);
      if (response.code === 200) {
        // 更新本地数据
        const flawIndex = this.flaws.findIndex(f => f.id === flawId);
        if (flawIndex >= 0) {
          this.flaws[flawIndex].status = status;
          if (remark) {
            this.flaws[flawIndex].remark = remark;
          }
          this.updateFlawCounts();
        }
        
        promptAction.showToast({
          message: '故障状态更新成功',
          duration: 2000
        });
        
        this.closeFlawDetail();
      }
    } catch (error) {
      console.error('更新故障状态失败:', error);
      promptAction.showToast({
        message: '更新失败，请重试',
        duration: 2000
      });
    }
  }

  getFlawStatusColor(status: FlawStatus): string {
    switch (status) {
      case FlawStatus.CONFIRMED:
        return '#f56c6c';
      case FlawStatus.SUSPECTED:
        return '#e6a23c';
      case FlawStatus.FALSE_POSITIVE:
        return '#909399';
      default:
        return '#909399';
    }
  }

  getFlawStatusText(status: FlawStatus): string {
    switch (status) {
      case FlawStatus.CONFIRMED:
        return '已确认';
      case FlawStatus.SUSPECTED:
        return '疑似故障';
      case FlawStatus.FALSE_POSITIVE:
        return '误报';
      default:
        return '未知';
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .backgroundColor('transparent')
          .onClick(() => {
            router.back();
          })
        
        Text('任务详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: '#eeeeee' })

      if (this.loading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color(AppConstants.COLORS.PRIMARY)
          
          Text('加载中...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 主要内容
        Row() {
          // 左侧图片区域
          Column() {
            if (this.flaws.length > 0 && this.currentFlawIndex < this.flaws.length) {
              Image(this.flaws[this.currentFlawIndex].flawImage || $r('app.media.placeholder'))
                .width('100%')
                .height(400)
                .objectFit(ImageFit.Contain)
                .backgroundColor('#f5f5f5')
                .border({ width: 1, color: '#dddddd' })
                .borderRadius(8)
            } else {
              Column() {
                Text('暂无故障图片')
                  .fontSize(16)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              }
              .width('100%')
              .height(400)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('#f5f5f5')
              .border({ width: 1, color: '#dddddd' })
              .borderRadius(8)
            }

            // 进度条
            if (this.flaws.length > 0) {
              Row() {
                ForEach(this.flaws, (flaw: Flaw, index: number) => {
                  Button()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(this.getFlawStatusColor(flaw.status))
                    .border({ 
                      width: index === this.currentFlawIndex ? 2 : 1, 
                      color: index === this.currentFlawIndex ? AppConstants.COLORS.PRIMARY : '#dddddd' 
                    })
                    .margin({ right: 8 })
                    .onClick(() => this.selectFlaw(index))
                }, (flaw: Flaw) => flaw.id.toString())
              }
              .width('100%')
              .padding(20)
              .justifyContent(FlexAlign.Center)
            }
          }
          .layoutWeight(1)
          .padding(20)

          // 右侧信息区域
          Column() {
            // 任务信息卡片
            if (this.task) {
              Column() {
                Text('任务信息')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })

                Row() {
                  Text('任务编号:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  Text(this.task.taskNo)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row() {
                  Text('任务名称:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  Text(this.task.taskName)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row() {
                  Text('巡检距离:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  Text(`${this.task.distance}米`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row() {
                  Text('执行人:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  Text(this.task.executor)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .width('100%')
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .border({ width: 1, color: '#eeeeee' })
              .margin({ bottom: 20 })
            }

            // 故障统计
            Column() {
              Text('故障统计')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 15 })

              Row() {
                Column() {
                  Text(this.flaws.length.toString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  Text('总数')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)

                Column() {
                  Text(this.confirmedCount.toString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#f56c6c')
                  Text('已确认')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)

                Column() {
                  Text(this.suspectedCount.toString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#e6a23c')
                  Text('疑似')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)

                Column() {
                  Text(this.falsePositiveCount.toString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#909399')
                  Text('误报')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .border({ width: 1, color: '#eeeeee' })
            .margin({ bottom: 20 })

            // 故障列表
            Column() {
              Text('故障列表')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 15 })

              List() {
                ForEach(this.flaws, (flaw: Flaw, index: number) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(flaw.flawName)
                          .fontSize(14)
                          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                          .fontWeight(FontWeight.Medium)
                        Text(flaw.flawType)
                          .fontSize(12)
                          .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                          .margin({ top: 4 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text(this.getFlawStatusText(flaw.status))
                        .fontSize(12)
                        .fontColor('#ffffff')
                        .backgroundColor(this.getFlawStatusColor(flaw.status))
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .borderRadius(12)
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(index === this.currentFlawIndex ? '#f0f9ff' : '#ffffff')
                    .border({ width: 1, color: index === this.currentFlawIndex ? AppConstants.COLORS.PRIMARY : '#eeeeee' })
                    .borderRadius(6)
                    .onClick(() => {
                      this.selectFlaw(index);
                      this.openFlawDetail(flaw);
                    })
                  }
                  .margin({ bottom: 8 })
                }, (flaw: Flaw) => flaw.id.toString())
              }
              .width('100%')
              .height(300)
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .border({ width: 1, color: '#eeeeee' })
          }
          .width(400)
          .padding(20)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(VerticalAlign.Top)
      }

      // 故障详情模态框
      if (this.showFlawDetail && this.selectedFlaw) {
        Stack() {
          Column() {
            // 模态框标题
            Row() {
              Text('故障详情')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
              
              Button('✕')
                .fontSize(16)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .backgroundColor('transparent')
                .onClick(() => this.closeFlawDetail())
            }
            .width('100%')
            .padding(20)
            .border({ width: { bottom: 1 }, color: '#eeeeee' })

            // 模态框内容
            Column() {
              // 故障图片
              Image(this.selectedFlaw.flawImage || $r('app.media.placeholder'))
                .width('100%')
                .height(300)
                .objectFit(ImageFit.Contain)
                .backgroundColor('#f5f5f5')
                .border({ width: 1, color: '#dddddd' })
                .borderRadius(8)
                .margin({ bottom: 20 })

              // 故障信息
              Row() {
                Column() {
                  Text('故障名称')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ bottom: 5 })
                  Text(this.selectedFlaw.flawName)
                    .fontSize(16)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column() {
                  Text('故障类型')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ bottom: 5 })
                  Text(this.selectedFlaw.flawType)
                    .fontSize(16)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 故障描述
              Column() {
                Text('故障描述')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .margin({ bottom: 5 })
                Text(this.selectedFlaw.flawDesc || '暂无描述')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 20 })

              // 状态确认
              Column() {
                Text('故障确认')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .margin({ bottom: 10 })

                Row() {
                  Button('确认故障')
                    .fontSize(14)
                    .fontColor('#ffffff')
                    .backgroundColor('#f56c6c')
                    .border({ width: 1, color: '#f56c6c' })
                    .onClick(() => this.updateFlawStatus(this.selectedFlaw!.id, FlawStatus.CONFIRMED))

                  Button('疑似故障')
                    .fontSize(14)
                    .fontColor('#ffffff')
                    .backgroundColor('#e6a23c')
                    .border({ width: 1, color: '#e6a23c' })
                    .margin({ left: 10 })
                    .onClick(() => this.updateFlawStatus(this.selectedFlaw!.id, FlawStatus.SUSPECTED))

                  Button('误报')
                    .fontSize(14)
                    .fontColor('#ffffff')
                    .backgroundColor('#909399')
                    .border({ width: 1, color: '#909399' })
                    .margin({ left: 10 })
                    .onClick(() => this.updateFlawStatus(this.selectedFlaw!.id, FlawStatus.FALSE_POSITIVE))
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(20)
            .layoutWeight(1)
          }
          .width(800)
          .height(600)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.closeFlawDetail())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }
}