import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';
import { AgvMovementService } from '../services/AgvMovementService';
import { AgvTask } from '../services/TaskService';

// 摄像头接口
interface Camera {
  id: string;
  name: string;
  url: string;
}

// 车辆状态接口
interface VehicleStatus {
  taskId: number;
  systemTime: string;
  distance: number;
  flawCount: number;
  position: number;
  isRunning: boolean;
}

// 故障接口
interface LiveFlaw {
  id: number;
  taskId: number;
  flawName: string;
  flawType: string;
  position: number;
  status: string;
  createTime: string;
}

// 使用AgvTask接口替代本地Task接口

@Entry
@Component
struct TaskExecuteView {
  @State task: AgvTask | null = null;
  @State vehicleStatus: VehicleStatus | null = null;
  @State liveFlaws: LiveFlaw[] = [];
  @State cameras: Camera[] = [];
  @State currentCameraIndex: number = 0;
  @State videoUrl: string = '';
  @State showFlawDetail: boolean = false;
  @State selectedFlaw: LiveFlaw | null = null;
  @State isAudioEnabled: boolean = true;
  @State loading: boolean = true;
  @State isTaskRunning: boolean = false;
  
  private taskId: number = 0;
  private statusTimer: number = -1;
  private flawTimer: number = -1;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['taskId']) {
      this.taskId = params['taskId'] as number;
      this.loadTaskDetail();
      this.loadCameras();
      this.startStatusPolling();
      this.startFlawPolling();
    }
  }

  aboutToDisappear() {
    this.stopPolling();
  }

  async loadTaskDetail() {
    try {
      const response = await HttpUtil.get(`/agv/task/${this.taskId}`);
      if (response.code === 200) {
        this.task = response.data as AgvTask;
        this.isTaskRunning = this.task.taskStatus === AppConstants.TASK_STATUS.RUNNING;
        console.info('[TaskExecuteView] 📋 任务详情加载成功:', JSON.stringify({
          taskId: this.taskId,
          taskStatus: this.task.taskStatus,
          isTaskRunning: this.isTaskRunning,
          expectedRunningStatus: AppConstants.TASK_STATUS.RUNNING
        }));
      }
    } catch (error) {
      console.error('加载任务详情失败:', error);
    }
  }

  async loadCameras() {
    try {
      // 使用完整的摄像头服务URL
      const cameraUrl = `${AppConstants.CAMERA_BASE_URL}/devices?page=1&size=999`;
      console.info('[TaskExecuteView] 📹 请求摄像头设备列表:', cameraUrl);
      
      const response = await HttpUtil.request(cameraUrl, {
        method: http.RequestMethod.GET,
        headers: {
          'Authorization': 'Basic YWRtaW4xMjM6QWRtaW5AMTIz',
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });
      
      if (response.code === 200) {
        interface DeviceItem {
          id: string;
        }
        interface DeviceData {
          rows?: DeviceItem[];
        }
        const deviceData = response.data as DeviceData;
        const devices = deviceData?.rows || [];
        interface CameraInfo {
          id: string;
          name: string;
          url: string;
        }
        this.cameras = devices.map((device: DeviceItem, index: number) => {
          const camera: CameraInfo = {
            id: device.id,
            name: `摄像头${index + 1}`,
            url: `${AppConstants.WEBRTC_BASE_URL}/live/${device.id}_01.flv`
          };
          return camera;
        });
        
        if (this.cameras.length > 0) {
          this.switchCamera(0);
        }
      }
    } catch (error) {
      console.error('加载摄像头列表失败:', error);
    } finally {
      this.loading = false;
    }
  }

  switchCamera(index: number) {
    if (index >= 0 && index < this.cameras.length) {
      this.currentCameraIndex = index;
      this.videoUrl = this.cameras[index].url;
    }
  }

  startStatusPolling() {
    this.statusTimer = setInterval(() => {
      this.updateVehicleStatus();
    }, 2000); // 每2秒更新一次状态
  }

  startFlawPolling() {
    this.flawTimer = setInterval(() => {
      this.updateLiveFlaws();
    }, 3000); // 每3秒检查一次故障
  }

  stopPolling() {
    if (this.statusTimer !== -1) {
      clearInterval(this.statusTimer);
      this.statusTimer = -1;
    }
    if (this.flawTimer !== -1) {
      clearInterval(this.flawTimer);
      this.flawTimer = -1;
    }
  }

  async updateVehicleStatus() {
    try {
      console.info('[TaskExecuteView] 📊 更新车辆状态');
      
      // 获取AGV实时状态
      const agvStatusResult = await AgvMovementService.getAgvStatus();
      
      // 定义AGV状态数据接口
      interface AgvStatusData {
        sysTime?: string;
        currentPosition?: number;
        isRunning?: boolean;
      }
      
      const agvStatus = agvStatusResult as AgvStatusData;
      
      // 构建车辆状态数据
      const vehicleStatus: VehicleStatus = {
        taskId: this.taskId,
        systemTime: agvStatus.sysTime || new Date().toLocaleTimeString(),
        distance: agvStatus.currentPosition || 0,
        flawCount: this.liveFlaws.length,
        position: agvStatus.currentPosition || 0,
        isRunning: agvStatus.isRunning || false
      };
      
      this.vehicleStatus = vehicleStatus;
      // 注意：不要在这里覆盖任务运行状态，任务状态应该基于任务本身而不是AGV状态
      // this.isTaskRunning 应该只在 loadTaskDetail 中设置
      
      console.info('[TaskExecuteView] ✅ 车辆状态更新成功:', JSON.stringify({
        vehicleStatus: vehicleStatus,
        taskRunning: this.isTaskRunning,
        agvRunning: agvStatus.isRunning
      }));
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 更新车辆状态失败:', error);
      
      // 如果获取失败，使用默认状态
      const fallbackStatus: VehicleStatus = {
        taskId: this.taskId,
        systemTime: new Date().toLocaleTimeString(),
        distance: 0,
        flawCount: this.liveFlaws.length,
        position: 0,
        isRunning: false
      };
      this.vehicleStatus = fallbackStatus;
    }
  }

  async updateLiveFlaws() {
    try {
      const response = await HttpUtil.get(`/agv/flaw/live/${this.taskId}`);
      if (response.code === 200) {
        interface FlawData {
          flaws?: LiveFlaw[];
        }
        const flawData = response.data as FlawData;
        const newFlaws = flawData?.flaws || [];
        
        // 检查是否有新故障
        if (newFlaws.length > this.liveFlaws.length) {
          promptAction.showToast({
            message: '发现新故障，请及时处理',
            duration: 3000
          });
        }
        
        this.liveFlaws = newFlaws;
      }
    } catch (error) {
      console.error('更新实时故障失败:', error);
    }
  }

  async controlVehicle(action: string) {
    try {
      console.info(`[TaskExecuteView] 🚗 控制车辆: ${action}`);
      
      interface ControlResponse {
        code?: number;
        msg?: string;
      }
      
      let response: ControlResponse;
      switch (action) {
        case 'forward':
          response = await AgvMovementService.agvForward() as ControlResponse;
          break;
        case 'stop':
          response = await AgvMovementService.agvStop() as ControlResponse;
          break;
        case 'backward':
          response = await AgvMovementService.agvBackward() as ControlResponse;
          break;
        default:
          console.warn(`[TaskExecuteView] ⚠️ 未知的控制指令: ${action}`);
          return;
      }
      
      if (response.code === 200) {
        const actionText = action === 'forward' ? '前进' : action === 'stop' ? '停止' : '后退';
        console.info(`[TaskExecuteView] ✅ 车辆${actionText}指令发送成功`);
        
        // 使用setTimeout确保在UI上下文中执行Toast
        setTimeout(() => {
          try {
            promptAction.showToast({
              message: `车辆${actionText}指令已发送`,
              duration: 2000
            });
          } catch (toastError) {
            console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
          }
        }, 0);
      } else {
        throw new Error(`控制指令返回错误: ${response.msg || '未知错误'}`);
      }
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 控制车辆失败:', error);
      
      // 使用setTimeout确保在UI上下文中执行Toast
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '控制指令发送失败',
            duration: 2000
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
    }
  }

  async finishTask() {
    try {
      console.info('[TaskExecuteView] 🏁 完成任务');
      
      // 先停止AGV确保安全
      await AgvMovementService.agvStop();
      console.info('[TaskExecuteView] ✅ AGV已停止');
      
      const response = await HttpUtil.post(`/agv/task/end/${this.taskId}?isAbort=false`);
      if (response.code === 200) {
        promptAction.showToast({
          message: '任务已完成',
          duration: 2000
        });
        
        this.stopPolling();
        this.isTaskRunning = false;
        
        console.info('[TaskExecuteView] ✅ 任务完成成功');
        
        // 跳转到任务详情页面
        router.replaceUrl({
          url: 'pages/TaskDetailView',
          params: {
            taskId: this.taskId
          }
        });
      }
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 完成任务失败:', error);
      promptAction.showToast({
        message: '完成任务失败，请重试',
        duration: 2000
      });
    }
  }

  async abortTask() {
    try {
      console.info('[TaskExecuteView] 🛑 终止任务');
      
      // 紧急停止AGV
      await AgvMovementService.emergencyStop();
      console.info('[TaskExecuteView] ✅ AGV紧急停止成功');
      
      const response = await HttpUtil.post(`/agv/task/end/${this.taskId}?isAbort=true`);
      if (response.code === 200) {
        promptAction.showToast({
          message: '任务已终止',
          duration: 2000
        });
        
        this.stopPolling();
        this.isTaskRunning = false;
        
        console.info('[TaskExecuteView] ✅ 任务终止成功');
        
        router.back();
      }
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 终止任务失败:', error);
      promptAction.showToast({
        message: '终止任务失败，请重试',
        duration: 2000
      });
    }
  }

  refreshVideo() {
    if (this.cameras.length > 0) {
      this.videoUrl = this.cameras[this.currentCameraIndex].url + '?t=' + Date.now();
    }
  }

  openFlawDetail(flaw: LiveFlaw) {
    this.selectedFlaw = flaw;
    this.showFlawDetail = true;
  }

  closeFlawDetail() {
    this.showFlawDetail = false;
    this.selectedFlaw = null;
  }

  getFlawStatusColor(status: string): string {
    switch (status) {
      case 'confirmed':
        return '#f56c6c';
      case 'suspected':
        return '#e6a23c';
      default:
        return '#909399';
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
            this.stopPolling();
            router.back();
          })
        
        Text('任务执行')
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
          
          Text('正在连接设备...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')

        .alignItems(HorizontalAlign.Center)
      } else {
        // 主要内容
        Row() {
          // 左侧视频区域
          Column() {
            // 视频播放器
            Stack() {
              if (this.videoUrl) {
                Video({
                  src: this.videoUrl
                })
                  .width('100%')
                  .height(450)
                  .autoPlay(true)
                  .controls(false)
                  .objectFit(ImageFit.Contain)
                  .backgroundColor('#000000')
              } else {
                Column() {
                  Text('📹')
                    .fontSize(48)
                    .fontColor('#cccccc')
                  Text('视频加载中...')
                    .fontSize(16)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ top: 10 })
                }
                .width('100%')
                .height(450)
          
                .alignItems(HorizontalAlign.Center)
                .backgroundColor('#f5f5f5')
              }

              // 视频控制按钮
              Row() {
                Button('🔄 刷新')
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor('rgba(0,0,0,0.6)')
                  .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
                  .borderRadius(4)
                  .onClick(() => this.refreshVideo())

                Button(this.isAudioEnabled ? '🔊' : '🔇')
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor('rgba(0,0,0,0.6)')
                  .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
                  .borderRadius(4)
                  .margin({ left: 10 })
                  .onClick(() => {
                    this.isAudioEnabled = !this.isAudioEnabled;
                  })
              }
              .position({ x: 10, y: 10 })
            }
            .width('100%')
            .borderRadius(8)
            .border({ width: 1, color: '#dddddd' })

            // 摄像头切换
            Row() {
              ForEach(this.cameras, (camera: Camera, index: number) => {
                Button(camera.name)
                  .fontSize(14)
                  .fontColor(index === this.currentCameraIndex ? '#ffffff' : AppConstants.COLORS.TEXT_PRIMARY)
                  .backgroundColor(index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#ffffff')
                  .border({ width: 1, color: index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#dddddd' })
                  .borderRadius(4)
                  .margin({ right: 10 })
                  .onClick(() => this.switchCamera(index))
              }, (camera: Camera) => camera.id)
            }
            .width('100%')
            .padding(15)
      

            // 控制按钮
            Row() {
              Button('⬅️ 后退')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor('#909399')
                .border({ width: 1, color: '#909399' })
                .enabled(this.isTaskRunning)
                .onClick(() => this.controlVehicle('backward'))

              Button('⏹️ 停止')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor('#f56c6c')
                .border({ width: 1, color: '#f56c6c' })
                .margin({ left: 15, right: 15 })
                .enabled(this.isTaskRunning)
                .onClick(() => this.controlVehicle('stop'))

              Button('➡️ 前进')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.SUCCESS)
                .border({ width: 1, color: AppConstants.COLORS.SUCCESS })
                .enabled(this.isTaskRunning)
                .onClick(() => this.controlVehicle('forward'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 20 })

            // 任务控制
            Row() {
              Button('✅ 完成巡检')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.SUCCESS)
                .border({ width: 1, color: AppConstants.COLORS.SUCCESS })
                .layoutWeight(1)
                .enabled(this.isTaskRunning)
                .onClick(() => this.finishTask())

              Button('❌ 终止巡检')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor('#f56c6c')
                .border({ width: 1, color: '#f56c6c' })
                .layoutWeight(1)
                .margin({ left: 15 })
                .enabled(this.isTaskRunning)
                .onClick(() => this.abortTask())
            }
            .width('100%')
            .margin({ top: 20 })
          }
          .layoutWeight(1)
          .padding(20)

          // 右侧状态区域
          Column() {
            // 任务信息
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
                  Text(this.task.taskCode)
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
                  Text('状态:')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .width(80)
                  Text(this.isTaskRunning ? '巡视中' : '已停止')
                    .fontSize(14)
                    .fontColor(this.isTaskRunning ? AppConstants.COLORS.SUCCESS : '#f56c6c')
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

            // 车辆状态
            if (this.vehicleStatus) {
              Column() {
                Text('车辆状态')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })

                Row() {
                  Column() {
                    Text(this.vehicleStatus.systemTime)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                    Text('系统时间')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)

                Column() {
                  Text(`${this.vehicleStatus.distance}m`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  Text('行驶距离')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 15 })

              Row() {
                Column() {
                  Text(this.vehicleStatus.flawCount.toString())
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#f56c6c')
                  Text('故障数量')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                }
                .layoutWeight(1)

                Column() {
                  Text(`${Math.min(Math.max(Math.round(this.vehicleStatus.position / 10), 0), 100)}%`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLORS.PRIMARY)
                  Text('巡检进度')
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
          }

          // 进度条
          if (this.vehicleStatus) {
            Column() {
              Text('巡检进度')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 15 })

              Stack() {
                // 进度条背景
                Row()
                  .width('100%')
                  .height(8)
                  .backgroundColor('#f0f0f0')
                  .borderRadius(4)

                // 进度条填充
                Row()
                  .width(`${Math.min(Math.max(Math.round(this.vehicleStatus.position / 10), 0), 100)}%`)
                  .height(8)
                  .backgroundColor(AppConstants.COLORS.PRIMARY)
                  .borderRadius(4)

                // 车辆位置标记
                Text('🚛')
                  .fontSize(20)
                  .position({ x: `${Math.min(Math.max(Math.round(this.vehicleStatus.position / 10), 0), 100)}%`, y: -6 })

                // 故障标记
                ForEach(this.liveFlaws, (flaw: LiveFlaw) => {
                  Button()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(this.getFlawStatusColor(flaw.status))
                    .position({ x: `${flaw.position}%`, y: -2 })
                    .onClick(() => this.openFlawDetail(flaw))
                }, (flaw: LiveFlaw) => flaw.id.toString())
              }
              .width('100%')
              .height(20)
              .margin({ bottom: 20 })
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .border({ width: 1, color: '#eeeeee' })
            .margin({ bottom: 20 })
          }

          // 实时故障列表
          Column() {
            Text('实时故障')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            if (this.liveFlaws.length === 0) {
              Text('暂无故障')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding(20)
            } else {
              List() {
                ForEach(this.liveFlaws, (flaw: LiveFlaw) => {
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

                      Text('📍')
                        .fontSize(16)
                        .fontColor(this.getFlawStatusColor(flaw.status))
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#ffffff')
                    .border({ width: 1, color: '#eeeeee' })
                    .borderRadius(6)
                    .onClick(() => this.openFlawDetail(flaw))
                  }
                  .margin({ bottom: 8 })
                }, (flaw: LiveFlaw) => flaw.id.toString())
              }
              .width('100%')
              .height(200)
            }
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
            Text('实时故障详情')
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
            Text(`故障名称: ${this.selectedFlaw.flawName}`)
              .fontSize(16)
              .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
              .margin({ bottom: 10 })

            Text(`故障类型: ${this.selectedFlaw.flawType}`)
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 10 })

            Text(`发现时间: ${this.selectedFlaw.createTime}`)
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 20 })

            Text('请在任务完成后进行详细确认')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(20)
          .alignItems(HorizontalAlign.Start)
        }
        .width(500)
        .height(300)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => this.closeFlawDetail())
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
}
}