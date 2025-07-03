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
  
  // 故障详情对话框控制器
  flawDetailDialogController: CustomDialogController = new CustomDialogController({
    builder: FlawDetailDialog({
      selectedFlaw: $selectedFlaw,
      getFlawLevelColor: (level: string) => this.getFlawLevelColor(level)
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  
  // 缺陷描述编辑对话框控制器
  remarkDialogController: CustomDialogController = new CustomDialogController({
    builder: RemarkEditDialog({
      editingRemark: $editingRemark,
      onSave: () => {
        this.saveRemark();
      },
      onCancel: () => {
        this.closeRemarkDialog();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

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
  async openFlawDetail(flaw: FlawInfo) {
    try {
      console.log('[TaskReviewView] 🔍 开始获取故障详情，ID:', flaw.id, '故障名称:', flaw.flawName);
      
      // 调用接口获取完整的故障详情
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${AppConstants.API_BASE_URL}/agv/flaw/${flaw.id}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      );

      console.log('[TaskReviewView] 📡 故障详情请求响应码:', response.responseCode);
      console.log('[TaskReviewView] 📡 故障详情请求响应内容:', response.result);

      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        console.log('[TaskReviewView] 📊 解析后的响应数据:', JSON.stringify(data));
        
        if (data.code === 200) {
          // 使用接口返回的完整故障信息
          this.selectedFlaw = data.data as FlawInfo;
          console.log('[TaskReviewView] 📋 获取到的完整故障详情:', JSON.stringify({
            id: this.selectedFlaw.id,
            flawName: this.selectedFlaw.flawName,
            flawType: this.selectedFlaw.flawType,
            level: this.selectedFlaw.level,
            flawDesc: this.selectedFlaw.flawDesc,
            remark: this.selectedFlaw.remark,
            flawImageUrl: this.selectedFlaw.flawImageUrl,
            confirmed: this.selectedFlaw.confirmed,
            createTime: this.selectedFlaw.createTime,
            flawDistance: this.selectedFlaw.flawDistance
          }));
          
          // 防止重复弹窗：检查弹窗是否已经打开
          if (!this.flawDetailDialogController) {
            console.warn('[TaskReviewView] ⚠️ 故障详情弹窗控制器未初始化');
            return;
          }
          
          this.flawDetailDialogController.open();
          console.log('[TaskReviewView] ✅ 故障详情弹窗已打开，ID:', flaw.id);
          
          // 显示成功提示
          promptAction.showToast({
            message: '故障详情加载成功',
            duration: 1500
          });
        } else {
          console.error('[TaskReviewView] ❌ 接口返回错误:', data.msg);
          throw new Error((data.msg as string) || '获取故障详情失败');
        }
      } else {
        console.error('[TaskReviewView] ❌ HTTP请求失败，响应码:', response.responseCode);
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] ❌ 获取故障详情失败:', error);
      // 降级处理：使用传入的故障信息，但不重复打开弹窗
      this.selectedFlaw = flaw;
      console.log('[TaskReviewView] 🔄 使用基本故障信息显示详情:', JSON.stringify({
        id: flaw.id,
        flawName: flaw.flawName,
        flawType: flaw.flawType,
        level: flaw.level
      }));
      
      // 只有在成功获取数据时才打开弹窗，避免重复显示
      // this.flawDetailDialogController.open();
      // console.log('[TaskReviewView] 🔄 基本故障信息弹窗已打开');
      
      promptAction.showToast({
        message: '获取详细信息失败，请重试',
        duration: 2000
      });
    }
  }

  // 关闭故障详情
  closeFlawDetail() {
    this.flawDetailDialogController.close();
    this.selectedFlaw = null;
  }

  // 打开缺陷描述编辑对话框
  openRemarkDialog(flaw: FlawInfo) {
    console.log('[TaskReviewView] 📝 打开缺陷描述编辑对话框，ID:', flaw.id);
    
    this.selectedFlaw = flaw;
    this.editingRemark = flaw.flawDesc || ''; // 回显当前的缺陷描述
    this.remarkDialogController.open();
    console.log('[TaskReviewView] 📝 缺陷描述编辑对话框已打开，当前描述:', this.editingRemark);
  }

  // 关闭备注编辑对话框
  closeRemarkDialog() {
    this.remarkDialogController.close();
    this.selectedFlaw = null;
    this.editingRemark = '';
  }

  // 保存缺陷描述
  async saveRemark() {
    if (!this.selectedFlaw) return;

    try {
      console.log('[TaskReviewView] 📝 开始保存缺陷描述，ID:', this.selectedFlaw.id);
      
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
            flawDesc: this.editingRemark, // 更新缺陷描述
            flawImageUrl: this.selectedFlaw!.flawImageUrl,
            confirmed: this.selectedFlaw!.confirmed,
            remark: this.selectedFlaw!.remark // 保持原有备注不变
          })
        }
      );

      if (response.responseCode === 200) {
        const data: Record<string, Object> = JSON.parse(response.result as string);
        if (data.code === 200) {
          // 在UI线程中更新本地数据
          setTimeout(() => {
            try {
              const index = this.flaws.findIndex(f => f.id === this.selectedFlaw!.id);
              if (index !== -1) {
                this.flaws[index].flawDesc = this.editingRemark;
              }
              this.selectedFlaw!.flawDesc = this.editingRemark;
              
              // 重新加载故障列表以确保数据同步
              this.loadFlaws();
              this.closeRemarkDialog();
              promptAction.showToast({
                message: '缺陷描述保存成功',
                duration: 2000
              });
              console.log('[TaskReviewView] ✅ 缺陷描述保存成功，ID:', this.selectedFlaw!.id);
            } catch (uiError) {
              console.error('[TaskReviewView] ❌ UI更新失败:', uiError);
            }
          }, 0);
        } else {
          throw new Error((data.msg as string) || '保存缺陷描述失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] ❌ 保存缺陷描述失败:', error);
      // 在UI线程中显示错误提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '保存缺陷描述失败，请重试',
            duration: 3000
          });
        } catch (uiError) {
          console.error('[TaskReviewView] ❌ 显示错误提示失败:', uiError);
        }
      }, 0);
    }
  }

  // 确认故障
  async confirmFlaw(flaw: FlawInfo) {
    try {
      console.log('[TaskReviewView] 🔧 开始确认故障，ID:', flaw.id);
      
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
          console.log('[TaskReviewView] ✅ 故障确认API调用成功，ID:', flaw.id);
          
          // 使用更长的延迟确保在UI线程中执行
          setTimeout(async () => {
            try {
              // 先更新本地数据
              const index = this.flaws.findIndex(f => f.id === flaw.id);
              if (index !== -1) {
                this.flaws[index].confirmed = true;
              }
              
              // 重新加载故障列表以确保数据同步
              await this.loadFlaws();
              
              // 显示成功提示
              promptAction.showToast({
                message: '故障确认成功',
                duration: 2000
              });
              
              console.log('[TaskReviewView] ✅ 故障确认完成，列表已刷新，ID:', flaw.id);
            } catch (uiError) {
              console.error('[TaskReviewView] ❌ UI更新失败:', uiError);
              // 如果UI更新失败，至少显示成功提示
              try {
                promptAction.showToast({
                  message: '故障确认成功，请手动刷新页面',
                  duration: 3000
                });
              } catch (toastError) {
                console.error('[TaskReviewView] ❌ 显示提示失败:', toastError);
              }
            }
          }, 100); // 增加延迟时间
        } else {
          throw new Error((data.msg as string) || '确认故障失败');
        }
      } else {
        throw new Error('网络请求失败');
      }
    } catch (error) {
      console.error('[TaskReviewView] ❌ 确认故障失败:', error);
      // 在UI线程中显示错误提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '确认故障失败，请重试',
            duration: 3000
          });
        } catch (uiError) {
          console.error('[TaskReviewView] ❌ 显示错误提示失败:', uiError);
        }
      }, 0);
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

          console.log('[TaskReviewView] ✅ 上传完成');
          
          // 显示成功对话框并跳转
          setTimeout(() => {
            try {
              promptAction.showDialog({
                title: '上传成功',
                message: '巡检记录已成功上传，任务已完成！',
                buttons: [
                  {
                    text: '确定',
                    color: AppConstants.COLORS.PRIMARY
                  }
                ]
              }).then(() => {
                // 跳转回任务列表页面
                router.replaceUrl({
                  url: 'pages/TaskView'
                }).catch((error: Error) => {
                  console.error('[TaskReviewView] ❌ 跳转任务列表失败:', error);
                  // 如果跳转失败，尝试返回上一页
                  router.back();
                });
              }).catch((error: Error) => {
                console.error('[TaskReviewView] ❌ 显示成功对话框失败:', error);
                // 如果对话框失败，直接跳转
                router.replaceUrl({ url: 'pages/TaskView' }).catch(() => {
                  router.back();
                });
              });
            } catch (error) {
              console.error('[TaskReviewView] ❌ 处理上传成功逻辑失败:', error);
              // 降级处理：显示Toast并跳转
              promptAction.showToast({
                message: '上传完成，正在返回任务列表...',
                duration: 2000
              });
              setTimeout(() => {
                router.replaceUrl({ url: 'pages/TaskView' }).catch(() => {
                  router.back();
                });
              }, 2000);
            }
          }, 100);
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
                      
                      Button('编辑描述')
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
  }

}

// 故障详情对话框组件
@CustomDialog
struct FlawDetailDialog {
  @Link selectedFlaw: FlawInfo | null;
  getFlawLevelColor: (level: string) => string = () => AppConstants.COLORS.TEXT_PRIMARY;
  controller: CustomDialogController = new CustomDialogController({builder: FlawDetailDialog()});

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('故障详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Button('×')
          .fontSize(20)
          .fontColor(AppConstants.COLORS.TEXT_REGULAR)
          .backgroundColor('transparent')
          .width(32)
          .height(32)
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')
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
                
                Text(this.selectedFlaw.flawDesc || '暂无描述')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              if (this.selectedFlaw.flawDistance !== undefined) {
                Row() {
                  Text('故障距离:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  
                  Text(`${this.selectedFlaw.flawDistance}m`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              
              if (this.selectedFlaw.flawLength !== undefined) {
                Row() {
                  Text('故障长度:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  
                  Text(`${this.selectedFlaw.flawLength}m`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              
              if (this.selectedFlaw.flawArea !== undefined) {
                Row() {
                  Text('故障面积:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  
                  Text(`${this.selectedFlaw.flawArea}㎡`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              
              if (this.selectedFlaw.countNum !== undefined) {
                Row() {
                  Text('故障数量:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  
                  Text(`${this.selectedFlaw.countNum}个`)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              
              if (this.selectedFlaw.createTime) {
                Row() {
                  Text('发现时间:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  
                  Text(this.selectedFlaw.createTime)
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              
              Row() {
                Text('确认状态:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  .width(80)
                
                Text(this.selectedFlaw.confirmed ? '已确认' : '待确认')
                  .fontSize(14)
                  .fontColor(this.selectedFlaw.confirmed ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.WARNING)
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
    .width('90%')
    .height('80%')
    .padding(20)
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
    .borderRadius(12)
  }
}

// 缺陷描述编辑对话框组件
@CustomDialog
struct RemarkEditDialog {
  @Link editingRemark: string;
  onSave: () => void = () => {};
  onCancel: () => void = () => {};
  controller: CustomDialogController = new CustomDialogController({builder: RemarkEditDialog()});

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('编辑缺陷描述')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Button('×')
          .fontSize(20)
          .fontColor(AppConstants.COLORS.TEXT_REGULAR)
          .backgroundColor('transparent')
          .width(32)
          .height(32)
          .onClick(() => {
            this.onCancel();
          })
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      TextArea({ placeholder: '请输入缺陷描述...', text: this.editingRemark })
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
            this.onCancel();
          })
        
        Button('保存')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(AppConstants.COLORS.PRIMARY)
          .borderRadius(8)
          .width('48%')
          .height(44)
          .onClick(() => {
            this.onSave();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('90%')
    .padding(20)
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
    .borderRadius(12)
  }
}