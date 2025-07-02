import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TaskService } from '../services/TaskService';
import { FlawService } from '../services/FlawService';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 任务详情接口
interface TaskDetail {
  id: string;
  taskName: string;
  status: string;
  createTime: string;
  updateTime: string;
  agvId: string;
  agvName: string;
  routeId: string;
  routeName: string;
  description?: string;
}

// 故障信息接口
interface FlawInfo {
  id: string;
  flawName: string;
  flawType: string;
  flawLevel: string;
  status: string;
  imageUrl?: string;
  description?: string;
  remark?: string;
  createTime: string;
  updateTime: string;
}

// 上传进度接口
interface UploadProgress {
  total: number;
  completed: number;
  current: string;
  percentage: number;
}

@Entry
@Component
struct TaskReviewView {
  @State taskId: string = '';
  @State taskDetail: TaskDetail | null = null;
  @State flaws: FlawInfo[] = [];
  @State loading: boolean = true;
  @State uploading: boolean = false;
  @State uploadProgress: UploadProgress = {
    total: 0,
    completed: 0,
    current: '',
    percentage: 0
  };
  @State selectedFlaw: FlawInfo | null = null;
  @State showFlawDetail: boolean = false;
  @State editingRemark: string = '';
  @State showRemarkDialog: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.taskId = params['taskId'] as string;
    console.info(`[TaskReviewView] 📋 初始化任务复盘页面, taskId: ${this.taskId}`);
    
    this.loadData();
  }

  async loadData() {
    try {
      this.loading = true;
      console.info('[TaskReviewView] 🔄 加载任务复盘数据...');
      
      // 并行加载任务详情和故障列表
      const [taskDetail, flaws] = await Promise.all([
        this.loadTaskDetail(),
        this.loadFlaws()
      ]);
      
      console.info('[TaskReviewView] ✅ 任务复盘数据加载完成');
    } catch (error) {
      console.error('[TaskReviewView] ❌ 加载数据失败:', error);
      promptAction.showToast({
        message: '加载数据失败，请重试',
        duration: 2000
      });
    } finally {
      this.loading = false;
    }
  }

  async loadTaskDetail(): Promise<TaskDetail> {
    try {
      console.info(`[TaskReviewView] 📋 加载任务详情: ${this.taskId}`);
      const taskDetail = await TaskService.getTaskDetail(this.taskId);
      this.taskDetail = taskDetail;
      console.info('[TaskReviewView] ✅ 任务详情加载成功:', JSON.stringify(taskDetail));
      return taskDetail;
    } catch (error) {
      console.error('[TaskReviewView] ❌ 加载任务详情失败:', error);
      throw error;
    }
  }

  async loadFlaws(): Promise<FlawInfo[]> {
    try {
      console.info(`[TaskReviewView] 🔍 加载故障列表: ${this.taskId}`);
      const flaws = await FlawService.liveInfo(this.taskId);
      this.flaws = flaws;
      console.info(`[TaskReviewView] ✅ 故障列表加载成功，共${flaws.length}个故障`);
      return flaws;
    } catch (error) {
      console.error('[TaskReviewView] ❌ 加载故障列表失败:', error);
      throw error;
    }
  }

  // 打开故障详情
  openFlawDetail(flaw: FlawInfo) {
    this.selectedFlaw = flaw;
    this.showFlawDetail = true;
    console.info(`[TaskReviewView] 👁️ 查看故障详情: ${flaw.flawName}`);
  }

  // 关闭故障详情
  closeFlawDetail() {
    this.showFlawDetail = false;
    this.selectedFlaw = null;
  }

  // 打开备注编辑对话框
  openRemarkDialog(flaw: FlawInfo) {
    this.selectedFlaw = flaw;
    this.editingRemark = flaw.remark || '';
    this.showRemarkDialog = true;
    console.info(`[TaskReviewView] ✏️ 编辑故障备注: ${flaw.flawName}`);
  }

  // 关闭备注编辑对话框
  closeRemarkDialog() {
    this.showRemarkDialog = false;
    this.selectedFlaw = null;
    this.editingRemark = '';
  }

  // 保存备注
  async saveRemark() {
    if (!this.selectedFlaw) return;
    
    try {
      console.info(`[TaskReviewView] 💾 保存故障备注: ${this.selectedFlaw.flawName}`);
      
      const updateData = {
        id: this.selectedFlaw.id,
        flawName: this.selectedFlaw.flawName,
        flawType: this.selectedFlaw.flawType,
        flawLevel: this.selectedFlaw.flawLevel,
        status: this.selectedFlaw.status,
        imageUrl: this.selectedFlaw.imageUrl,
        description: this.selectedFlaw.description,
        remark: this.editingRemark,
        createTime: this.selectedFlaw.createTime,
        updateTime: this.selectedFlaw.updateTime
      };
      
      await FlawService.updateFlaw(updateData);
      
      // 更新本地数据
      const index = this.flaws.findIndex(f => f.id === this.selectedFlaw!.id);
      if (index >= 0) {
        this.flaws[index].remark = this.editingRemark;
      }
      
      promptAction.showToast({
        message: '备注保存成功',
        duration: 2000
      });
      
      this.closeRemarkDialog();
      console.info('[TaskReviewView] ✅ 故障备注保存成功');
    } catch (error) {
      console.error('[TaskReviewView] ❌ 保存故障备注失败:', error);
      promptAction.showToast({
        message: '保存备注失败，请重试',
        duration: 2000
      });
    }
  }

  // 确认故障
  async confirmFlaw(flaw: FlawInfo) {
    try {
      console.info(`[TaskReviewView] ✅ 确认故障: ${flaw.flawName}`);
      
      // 将字符串ID转换为数字
      const flawId = typeof flaw.id === 'string' ? parseInt(flaw.id) : flaw.id;
      await FlawService.confirmFlaw(flawId, true);
      
      // 更新本地数据
      const index = this.flaws.findIndex(f => f.id === flaw.id);
      if (index >= 0) {
        this.flaws[index].status = 'confirmed';
      }
      
      promptAction.showToast({
        message: '故障确认成功',
        duration: 2000
      });
      
      console.info('[TaskReviewView] ✅ 故障确认成功');
    } catch (error) {
      console.error('[TaskReviewView] ❌ 确认故障失败:', error);
      promptAction.showToast({
        message: '确认故障失败，请重试',
        duration: 2000
      });
    }
  }

  // 上传巡检记录
  async uploadInspectionRecord() {
    try {
      this.uploading = true;
      console.info('[TaskReviewView] 📤 开始上传巡检记录...');
      
      // 模拟上传进度
      const files = [
        '任务报告.pdf',
        '故障图片1.jpg',
        '故障图片2.jpg',
        '巡检日志.txt'
      ];
      
      this.uploadProgress = {
        total: files.length,
        completed: 0,
        current: '',
        percentage: 0
      };
      
      for (let i = 0; i < files.length; i++) {
        this.uploadProgress.current = files[i];
        console.info(`[TaskReviewView] 📤 正在上传: ${files[i]}`);
        
        // 模拟上传时间
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        this.uploadProgress.completed = i + 1;
        this.uploadProgress.percentage = Math.round((i + 1) / files.length * 100);
      }
      
      // 调用实际的上传API
      const response = await HttpUtil.post(`/agv/task/upload/${this.taskId}`, {
        files: files,
        flaws: this.flaws
      });
      
      if (response.code === 200) {
        promptAction.showToast({
          message: '巡检记录上传成功',
          duration: 2000
        });
        
        console.info('[TaskReviewView] ✅ 巡检记录上传成功');
        
        // 延迟跳转到任务列表
        setTimeout(() => {
          router.replaceUrl({
            url: 'pages/TaskListView'
          });
        }, 2000);
      }
    } catch (error) {
      console.error('[TaskReviewView] ❌ 上传巡检记录失败:', error);
      promptAction.showToast({
        message: '上传失败，请重试',
        duration: 2000
      });
    } finally {
      this.uploading = false;
    }
  }

  // 获取故障状态颜色
  getFlawStatusColor(status: string): string {
    switch (status) {
      case 'confirmed':
        return AppConstants.COLORS.SUCCESS;
      case 'pending':
        return AppConstants.COLORS.WARNING;
      default:
        return AppConstants.COLORS.TEXT_REGULAR;
    }
  }

  // 获取故障状态文本
  getFlawStatusText(status: string): string {
    switch (status) {
      case 'confirmed':
        return '已确认';
      case 'pending':
        return '待确认';
      default:
        return '未知';
    }
  }

  // 获取故障等级颜色
  getFlawLevelColor(level: string): string {
    switch (level) {
      case 'high':
        return AppConstants.COLORS.DANGER;
      case 'medium':
        return AppConstants.COLORS.WARNING;
      case 'low':
        return AppConstants.COLORS.SUCCESS;
      default:
        return AppConstants.COLORS.TEXT_REGULAR;
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
        
        Text('任务复盘')
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
          
          Text('正在加载任务数据...')
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
        Scroll() {
          Column() {
            // 任务信息卡片
            if (this.taskDetail) {
              Column() {
                Row() {
                  Text('任务信息')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                }
                .width('100%')
                .margin({ bottom: 12 })
                
                Column() {
                  Row() {
                    Text('任务名称:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.taskName)
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 8 })
                  
                  Row() {
                    Text('AGV车辆:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.agvName)
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 8 })
                  
                  Row() {
                    Text('巡检路线:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.routeName)
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 8 })
                  
                  Row() {
                    Text('完成时间:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.updateTime)
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .margin({ bottom: 16 })
            }
            
            // 故障列表
            Column() {
              Row() {
                Text(`发现故障 (${this.flaws.length})`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                
                Blank()
                
                Text('请确认故障信息')
                  .fontSize(12)
                  .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
              }
              .width('100%')
              .margin({ bottom: 12 })
              
              if (this.flaws.length === 0) {
                Column() {
                  Text('🎉')
                    .fontSize(32)
                    .margin({ bottom: 8 })
                  
                  Text('本次巡检未发现故障')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .width('100%')
                .height(120)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor('#f8f9fa')
                .borderRadius(8)
              } else {
                ForEach(this.flaws, (flaw: FlawInfo) => {
                  Column() {
                    Row() {
                      Column() {
                        Text(flaw.flawName)
                          .fontSize(14)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                          .margin({ bottom: 4 })
                        
                        Row() {
                          Text(flaw.flawType)
                            .fontSize(12)
                            .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                          
                          Text('|')
                            .fontSize(12)
                            .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                            .margin({ left: 8, right: 8 })
                          
                          Text(flaw.flawLevel)
                            .fontSize(12)
                            .fontColor(this.getFlawLevelColor(flaw.flawLevel))
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      
                      Column() {
                        Text(this.getFlawStatusText(flaw.status))
                          .fontSize(12)
                          .fontColor(this.getFlawStatusColor(flaw.status))
                          .padding({ horizontal: 8, vertical: 4 })
                          .backgroundColor(this.getFlawStatusColor(flaw.status) + '20')
                          .borderRadius(4)
                      }
                    }
                    .width('100%')
                    .margin({ bottom: 12 })
                    
                    // 操作按钮
                    Row() {
                      Button('查看详情')
                        .fontSize(12)
                        .fontColor(AppConstants.COLORS.PRIMARY)
                        .backgroundColor('transparent')
                        .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                        .borderRadius(4)
                        .padding({ horizontal: 12, vertical: 6 })
                        .onClick(() => {
                          this.openFlawDetail(flaw);
                        })
                      
                      Button('添加备注')
                        .fontSize(12)
                        .fontColor(AppConstants.COLORS.WARNING)
                        .backgroundColor('transparent')
                        .border({ width: 1, color: AppConstants.COLORS.WARNING })
                        .borderRadius(4)
                        .padding({ horizontal: 12, vertical: 6 })
                        .margin({ left: 8 })
                        .onClick(() => {
                          this.openRemarkDialog(flaw);
                        })
                      
                      if (flaw.status !== 'confirmed') {
                        Button('确认故障')
                          .fontSize(12)
                          .fontColor('#ffffff')
                          .backgroundColor(AppConstants.COLORS.SUCCESS)
                          .borderRadius(4)
                          .padding({ horizontal: 12, vertical: 6 })
                          .margin({ left: 8 })
                          .onClick(() => {
                            this.confirmFlaw(flaw);
                          })
                      }
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Start)
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor('#ffffff')
                  .borderRadius(8)
                  .margin({ bottom: 12 })
                }, (flaw: FlawInfo) => flaw.id)
              }
            }
            .width('100%')
            .margin({ bottom: 24 })
            
            // 上传按钮
            if (!this.uploading) {
              Button('上传巡检记录')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.PRIMARY)
                .width('100%')
                .height(48)
                .borderRadius(8)
                .onClick(() => {
                  this.uploadInspectionRecord();
                })
            } else {
              // 上传进度
              Column() {
                Row() {
                  Text('上传进度')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  
                  Blank()
                  
                  Text(`${this.uploadProgress.percentage}%`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.PRIMARY)
                }
                .width('100%')
                .margin({ bottom: 8 })
                
                Progress({
                  value: this.uploadProgress.completed,
                  total: this.uploadProgress.total,
                  type: ProgressType.Linear
                })
                .width('100%')
                .height(6)
                .color(AppConstants.COLORS.PRIMARY)
                .margin({ bottom: 8 })
                
                Text(`正在上传: ${this.uploadProgress.current}`)
                  .fontSize(12)
                  .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(8)
            }
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
    
    // 故障详情弹窗
    if (this.showFlawDetail && this.selectedFlaw) {
      Column() {
        Column() {
          // 弹窗标题
          Row() {
            Text('故障详情')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            
            Button('✕')
              .fontSize(16)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .backgroundColor('transparent')
              .onClick(() => {
                this.closeFlawDetail();
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          
          // 故障信息
          Column() {
            Row() {
              Text('故障名称:')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .width(80)
              
              Text(this.selectedFlaw.flawName)
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Row() {
              Text('故障类型:')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .width(80)
              
              Text(this.selectedFlaw.flawType)
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Row() {
              Text('故障等级:')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .width(80)
              
              Text(this.selectedFlaw.flawLevel)
                .fontSize(14)
                .fontColor(this.getFlawLevelColor(this.selectedFlaw.flawLevel))
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            if (this.selectedFlaw.description) {
              Row() {
                Text('故障描述:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .width(80)
                
                Text(this.selectedFlaw.description)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })
            }
            
            if (this.selectedFlaw.remark) {
              Row() {
                Text('备注信息:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .width(80)
                
                Text(this.selectedFlaw.remark)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })
            }
            
            // 故障图片
            if (this.selectedFlaw.imageUrl) {
              Column() {
                Text('故障图片:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .width('100%')
                  .margin({ bottom: 8 })
                
                Image(this.selectedFlaw.imageUrl)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(8)
                  .backgroundColor('#f8f9fa')
              }
              .width('100%')
              .margin({ bottom: 16 })
            }
          }
        }
        .width('90%')
        .maxWidth(400)
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(12)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.closeFlawDetail();
      })
    }
    
    // 备注编辑弹窗
    if (this.showRemarkDialog && this.selectedFlaw) {
      Column() {
        Column() {
          // 弹窗标题
          Row() {
            Text('编辑备注')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            
            Button('✕')
              .fontSize(16)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .backgroundColor('transparent')
              .onClick(() => {
                this.closeRemarkDialog();
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          
          // 故障名称
          Text(`故障: ${this.selectedFlaw.flawName}`)
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            .width('100%')
            .margin({ bottom: 12 })
          
          // 备注输入框
          TextArea({
            placeholder: '请输入备注信息...',
            text: this.editingRemark
          })
            .width('100%')
            .height(100)
            .fontSize(14)
            .borderRadius(8)
            .backgroundColor('#f8f9fa')
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.editingRemark = value;
            })
          
          // 操作按钮
          Row() {
            Button('取消')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .backgroundColor('transparent')
              .border({ width: 1, color: '#dddddd' })
              .borderRadius(6)
              .layoutWeight(1)
              .onClick(() => {
                this.closeRemarkDialog();
              })
            
            Button('保存')
              .fontSize(14)
              .fontColor('#ffffff')
              .backgroundColor(AppConstants.COLORS.PRIMARY)
              .borderRadius(6)
              .layoutWeight(1)
              .margin({ left: 12 })
              .onClick(() => {
                this.saveRemark();
              })
          }
          .width('100%')
        }
        .width('90%')
        .maxWidth(400)
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(12)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}