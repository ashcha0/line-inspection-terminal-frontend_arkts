import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { AppConstants } from '../constants/AppConstants';

// 任务详情接口
interface TaskDetail {
  id: number;
  taskCode: string;
  taskName: string;
  startPos: string;
  taskTrip: string;
  creator: string;
  executor: string;
  execTime: string;
  endTime: string;
  createTime: string;
  taskStatus: string;
  round: number;
  uploaded: boolean;
  remark: string;
  cloudTaskId: number;
}

// 故障信息接口
interface FlawInfo {
  id: number;
  taskId: number;
  round: number;
  flawType: string;
  flawName: string;
  flawDesc: string;
  flawDistance: number;
  flawImage: string;
  flawImageUrl: string;
  flawRtsp: string;
  shown: boolean;
  confirmed: boolean;
  uploaded: boolean;
  createTime: string;
  remark: string;
  flawLength: number;
  flawArea: number;
  level: string;
  countNum: number;
}

// 上传信息接口
interface UploadInfo {
  info: string;
  type: string;
  status: string;
}

// 上传进度接口
interface UploadProgress {
  percentage: number;
  completed: number;
  total: number;
  current: string;
}

@Entry
@Component
struct TaskReviewView {
  @State taskId: number = 0;
  @State taskDetail: TaskDetail | null = null;
  @State flaws: FlawInfo[] = [];
  @State loading: boolean = true;
  @State uploading: boolean = false;
  @State uploadProgress: UploadProgress = {
    percentage: 0,
    completed: 0,
    total: 0,
    current: ''
  };
  @State showFlawDetail: boolean = false;
  @State selectedFlaw: FlawInfo | null = null;
  @State showRemarkDialog: boolean = false;
  @State editingRemark: string = '';
  @State uploadInfoList: UploadInfo[] = [];

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['taskId']) {
      this.taskId = params['taskId'] as number;
      this.loadData();
    }
  }

  // 加载数据
  async loadData() {
    try {
      this.loading = true;
      console.log('[TaskReviewView] 开始加载数据，任务ID:', this.taskId);
      
      await Promise.all([
        this.loadTaskDetail(),
        this.loadFlaws()
      ]);
    } catch (error) {
      console.error('[TaskReviewView] 加载数据失败:', error);
      promptAction.showToast({
        message: '加载数据失败，请重试',
        duration: 3000
      });
    } finally {
      this.loading = false;
    }
  }

  // 加载任务详情
  async loadTaskDetail() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${AppConstants.API_BASE_URL}/agv/task/${this.taskId}`);
      
      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          this.taskDetail = data.data as TaskDetail;
          console.log('[TaskReviewView] 任务详情加载成功:', this.taskDetail);
        } else {
          throw new Error((data.msg as string) || '获取任务详情失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 加载任务详情失败:', error);
      throw new Error('加载任务详情失败');
    }
  }

  // 加载故障列表
  async loadFlaws() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${AppConstants.API_BASE_URL}/agv/flaw/list?taskId=${this.taskId}`);
      
      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          this.flaws = (data.rows as FlawInfo[]) || [];
          console.log('[TaskReviewView] 故障列表加载成功，数量:', this.flaws.length);
        } else {
          throw new Error((data.msg as string) || '获取故障列表失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 加载故障列表失败:', error);
      throw new Error('加载故障列表失败');
    }
  }

  // 打开故障详情
  openFlawDetail(flaw: FlawInfo) {
    this.selectedFlaw = flaw;
    this.showFlawDetail = true;
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
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${AppConstants.API_BASE_URL}/agv/flaw`,
        {
          method: http.RequestMethod.PUT,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            id: this.selectedFlaw!.id,
            flawName: this.selectedFlaw!.flawName,
            flawType: this.selectedFlaw!.flawType,
            level: this.selectedFlaw!.level,
            flawDesc: this.selectedFlaw!.flawDesc,
            flawImageUrl: this.selectedFlaw!.flawImageUrl,
            confirmed: this.selectedFlaw!.confirmed,
            remark: this.editingRemark
          })
        }
      );

      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          // 更新本地数据
          const index = this.flaws.findIndex(f => f.id === this.selectedFlaw!.id);
          if (index !== -1) {
            this.flaws[index].remark = this.editingRemark;
          }
          this.closeRemarkDialog();
          promptAction.showToast({
            message: '备注保存成功',
            duration: 2000
          });
          console.log('[TaskReviewView] 备注保存成功');
        } else {
          throw new Error((data.msg as string) || '保存备注失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 保存备注失败:', error);
      promptAction.showToast({
        message: '保存备注失败，请重试',
        duration: 3000
      });
    }
  }

  // 确认故障
  async confirmFlaw(flaw: FlawInfo) {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${AppConstants.API_BASE_URL}/agv/flaw`,
        {
          method: http.RequestMethod.PUT,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            id: flaw.id,
            flawName: flaw.flawName,
            flawType: flaw.flawType,
            level: flaw.level,
            flawDesc: flaw.flawDesc,
            flawImageUrl: flaw.flawImageUrl,
            remark: flaw.remark,
            confirmed: true
          })
        }
      );

      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          // 更新本地数据
          const index = this.flaws.findIndex(f => f.id === flaw.id);
          if (index !== -1) {
            this.flaws[index].confirmed = true;
          }
          promptAction.showToast({
            message: '故障确认成功',
            duration: 2000
          });
          console.log('[TaskReviewView] 故障确认成功，ID:', flaw.id);
        } else {
          throw new Error((data.msg as string) || '确认故障失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 确认故障失败:', error);
      promptAction.showToast({
        message: '确认故障失败，请重试',
        duration: 3000
      });
    }
  }

  // 获取上传数据信息
  async getUploadInfo() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${AppConstants.API_BASE_URL}/agv/task/preupload/${this.taskId}`);
      
      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          this.uploadInfoList = (data.data as UploadInfo[]) || [];
          console.log('[TaskReviewView] 获取上传信息成功，数量:', this.uploadInfoList.length);
          return this.uploadInfoList;
        } else {
          throw new Error((data.msg as string) || '获取上传信息失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 获取上传信息失败:', error);
      throw new Error('获取上传信息失败');
    }
  }

  // 上传巡检记录
  async uploadInspectionRecord() {
    try {
      this.uploading = true;
      this.uploadProgress = {
        percentage: 0,
        completed: 0,
        total: 100,
        current: '准备上传...'
      };

      // 获取上传信息
      const uploadList = await this.getUploadInfo();
      if (uploadList.length === 0) {
        promptAction.showToast({
          message: '没有需要上传的数据',
          duration: 2000
        });
        this.uploading = false;
        return;
      }

      this.uploadProgress.total = uploadList.length;
      console.log('[TaskReviewView] 开始上传，总数:', uploadList.length);

      // 执行上传
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${AppConstants.API_BASE_URL}/agv/task/upload/${this.taskId}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          // 模拟上传进度
          for (let i = 0; i < uploadList.length; i++) {
            this.uploadProgress.completed = i + 1;
            this.uploadProgress.percentage = Math.round((i + 1) / uploadList.length * 100);
            this.uploadProgress.current = `正在上传: ${uploadList[i].info}`;
            
            // 模拟上传延迟
            await new Promise<void>(resolve => setTimeout(resolve, 500));
          }

          // 更新任务状态
          if (this.taskDetail) {
            this.taskDetail.uploaded = true;
            this.taskDetail.taskStatus = '已完成';
          }

          promptAction.showToast({
            message: '上传完成',
            duration: 2000
          });
          console.log('[TaskReviewView] 上传完成');
        } else {
          throw new Error((data.msg as string) || '上传失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] 上传失败:', error);
      promptAction.showToast({
        message: '上传失败，请重试',
        duration: 3000
      });
    } finally {
      this.uploading = false;
    }
  }

  // 获取故障状态颜色
  getFlawStatusColor(confirmed: boolean): string {
    return confirmed ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.WARNING;
  }

  // 获取故障状态文本
  getFlawStatusText(confirmed: boolean): string {
    return confirmed ? '已确认' : '待确认';
  }

  // 获取故障等级颜色
  getFlawLevelColor(level: string): string {
    switch (level) {
      case '严重':
        return AppConstants.COLORS.DANGER;
      case '一般':
        return AppConstants.COLORS.WARNING;
      case '轻微':
        return AppConstants.COLORS.INFO;
      default:
        return AppConstants.COLORS.TEXT_REGULAR;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor('#ffffff')
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back();
        })
        
        Text('任务复盘')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button() {
          Text('设置')
            .fontSize(14)
            .fontColor('#ffffff')
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsView' });
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppConstants.COLORS.PRIMARY)
      
      if (this.loading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(AppConstants.COLORS.PRIMARY)
            .margin({ bottom: 16 })
          
          Text('加载中...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
        
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
                  
                  Blank()
                  
                  Text(this.taskDetail.taskStatus)
                    .fontSize(12)
                    .fontColor('#ffffff')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor(this.taskDetail.uploaded ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.WARNING)
                    .borderRadius(4)
                }
                .width('100%')
                .margin({ bottom: 16 })
                
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
                    Text('任务编号:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.taskCode)
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 8 })
                  
                  Row() {
                    Text('执行人:')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .width(80)
                    
                    Text(this.taskDetail.executor)
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
                    
                    Text(this.taskDetail.endTime)
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
                          
                          Text(flaw.level)
                            .fontSize(12)
                            .fontColor(this.getFlawLevelColor(flaw.level))
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      
                      Column() {
                        Text(this.getFlawStatusText(flaw.confirmed))
                          .fontSize(12)
                          .fontColor(this.getFlawStatusColor(flaw.confirmed))
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .backgroundColor(this.getFlawStatusColor(flaw.confirmed) + '20')
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
                        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        .onClick(() => {
                          this.openFlawDetail(flaw);
                        })
                      
                      Button('添加备注')
                        .fontSize(12)
                        .fontColor(AppConstants.COLORS.WARNING)
                        .backgroundColor('transparent')
                        .border({ width: 1, color: AppConstants.COLORS.WARNING })
                        .borderRadius(4)
                        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        .margin({ left: 8 })
                        .onClick(() => {
                          this.openRemarkDialog(flaw);
                        })
                      
                      if (!flaw.confirmed) {
                        Button('确认故障')
                          .fontSize(12)
                          .fontColor('#ffffff')
                          .backgroundColor(AppConstants.COLORS.SUCCESS)
                          .borderRadius(4)
                          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
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
                }, (flaw: FlawInfo) => flaw.id.toString())
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
        .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showFlawDetail, this.buildFlawDetailSheet(), {
      height: '80%',
      showClose: true,
      onDisappear: () => {
        this.closeFlawDetail();
      }
    })
    .bindSheet(this.showRemarkDialog, this.buildRemarkDialog(), {
      height: '60%',
      showClose: true,
      onDisappear: () => {
        this.closeRemarkDialog();
      }
    })
  }

  // 故障详情弹窗
  @Builder
  buildFlawDetailSheet() {
    Column() {
      Text('故障详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
        .margin({ bottom: 20 })
      
      if (this.selectedFlaw) {
        Scroll() {
          Column() {
            // 故障基本信息
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
                
                Text(this.selectedFlaw.level)
                  .fontSize(14)
                  .fontColor(this.getFlawLevelColor(this.selectedFlaw.level))
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                Text('故障描述:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .width(80)
                
                Text(this.selectedFlaw.flawDesc)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })
              
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
                .margin({ bottom: 16 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 16 })
            
            // 故障图片
            if (this.selectedFlaw.flawImageUrl) {
              Column() {
                Text('故障图片')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .margin({ bottom: 12 })
                
                Image(this.selectedFlaw.flawImageUrl)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(8)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(8)
            }
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }

  // 备注编辑对话框
  @Builder
  buildRemarkDialog() {
    Column() {
      Text('添加备注')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
        .margin({ bottom: 20 })
      
      TextArea({ placeholder: '请输入备注信息...', text: this.editingRemark })
        .width('100%')
        .height(120)
        .fontSize(14)
        .borderRadius(8)
        .backgroundColor('#ffffff')
        .onChange((value: string) => {
          this.editingRemark = value;
        })
        .margin({ bottom: 20 })
      
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor(AppConstants.COLORS.TEXT_REGULAR)
          .backgroundColor('transparent')
          .border({ width: 1, color: AppConstants.COLORS.BORDER_BASE })
          .borderRadius(8)
          .width('48%')
          .height(44)
          .onClick(() => {
            this.closeRemarkDialog();
          })
        
        Button('保存')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(AppConstants.COLORS.PRIMARY)
          .borderRadius(8)
          .width('48%')
          .height(44)
          .onClick(() => {
            this.saveRemark();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }
}