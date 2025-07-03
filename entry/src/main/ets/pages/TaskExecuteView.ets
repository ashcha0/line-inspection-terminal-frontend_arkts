import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';
import { AgvMovementService } from '../services/AgvMovementService';
import { AgvTask } from '../services/TaskService';
import { CameraService, CameraInfo } from '../services/CameraService';
import { FlawService, AgvFlaw } from '../services/FlawService';

// 摄像头接口（使用CameraService中的CameraInfo）
type Camera = CameraInfo;

// 摄像头信息项接口
interface CameraInfoItem {
  id: string;
  name: string;
}

// 摄像头加载日志信息接口
interface CameraLoadLogInfo {
  cameraCount: number;
  cameras: CameraInfoItem[];
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

// 故障接口 - 使用FlawService中的AgvFlaw接口
type LiveFlaw = AgvFlaw;

// 新故障弹窗状态接口
interface NewFlawAlert {
  show: boolean;
  flaw: LiveFlaw | null;
}

// 路由参数接口
interface RouterParamsData {
  taskId: number;
}

interface RouterParams {
  url: string;
  params: RouterParamsData;
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
  @State cameraConnectionStatus: string = '检测中...';
  @State lastCameraCheck: string = '';
  @State newFlawAlert: NewFlawAlert = { show: false, flaw: null };
  @State lastFlawCount: number = 0;
  
  private taskId: number = 0;
  private statusTimer: number = -1;
  private flawTimer: number = -1;
  private cameraTimer: number = -1;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['taskId']) {
      this.taskId = params['taskId'] as number;
      this.loadTaskDetail();
      this.loadCameras();
      this.startStatusPolling();
      this.startFlawPolling();
      // 移除摄像头轮询，改为手动刷新
      // this.startCameraPolling();
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
      console.info('[TaskExecuteView] 📹 开始加载摄像头列表');
      
      // 使用CameraService获取摄像头信息列表
      this.cameras = await CameraService.getCameraInfoList();
      
      const logInfo: CameraLoadLogInfo = {
        cameraCount: this.cameras.length,
        cameras: this.cameras.map((c: CameraInfo): CameraInfoItem => ({ id: c.id, name: c.name }))
      };
      console.info('[TaskExecuteView] ✅ 摄像头列表加载成功:', JSON.stringify(logInfo));
      
      // 如果有摄像头，默认选择第一个并开始播放
      if (this.cameras.length > 0) {
        this.switchCamera(0);
        console.info('[TaskExecuteView] 🎥 默认选择第一个摄像头:', this.cameras[0].name);
        
        // 显示成功提示
        setTimeout(() => {
          try {
            promptAction.showToast({
              message: `已连接${this.cameras.length}个摄像头，开始实时监控`,
              duration: 2000
            });
          } catch (toastError) {
            console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
          }
        }, 0);
      } else {
        console.warn('[TaskExecuteView] ⚠️ 未发现可用摄像头');
        
        // 显示无摄像头提示
        setTimeout(() => {
          try {
            promptAction.showToast({
              message: '未发现可用摄像头，请检查设备连接',
              duration: 3000
            });
          } catch (toastError) {
            console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
          }
        }, 0);
      }
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 加载摄像头列表失败:', error);
      
      // 显示错误提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '摄像头服务连接失败，请检查网络连接和服务状态',
            duration: 3000
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
    } finally {
      this.loading = false;
    }
  }

  switchCamera(index: number) {
    if (index >= 0 && index < this.cameras.length) {
      this.currentCameraIndex = index;
      this.videoUrl = this.cameras[index].url;
      
      console.info('[TaskExecuteView] 🔄 切换摄像头:', JSON.stringify({
        cameraIndex: index,
        cameraId: this.cameras[index].id,
        cameraName: this.cameras[index].name,
        videoUrl: this.videoUrl
      }));
    } else {
      console.warn('[TaskExecuteView] ⚠️ 无效的摄像头索引:', index);
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

  // 移除自动摄像头轮询，改为手动刷新
  // startCameraPolling() {
  //   this.cameraTimer = setInterval(() => {
  //     this.checkCameraConnection();
  //   }, 10000); // 每10秒检查一次摄像头连接状态
  // }

  stopPolling() {
    if (this.statusTimer !== -1) {
      clearInterval(this.statusTimer);
      this.statusTimer = -1;
    }
    if (this.flawTimer !== -1) {
      clearInterval(this.flawTimer);
      this.flawTimer = -1;
    }
    // 移除摄像头定时器相关逻辑
    // if (this.cameraTimer !== -1) {
    //   clearInterval(this.cameraTimer);
    //   this.cameraTimer = -1;
    // }
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
      console.info('[TaskExecuteView] 🔄 更新实时故障数据');
      console.info(`[TaskExecuteView] 📊 请求参数 - taskId: ${this.taskId}`);
      console.info(`[TaskExecuteView] 📊 当前故障计数: ${this.lastFlawCount}`);
      
      // 测试：同时使用两个接口获取故障数据进行对比
      console.info(`[TaskExecuteView] 📊 测试 - 使用实时接口: /agv/flaw/live/${this.taskId}`);
      const liveFlaws = await FlawService.liveInfo(this.taskId);
      console.info(`[TaskExecuteView] 📊 实时接口返回数据: ${JSON.stringify(liveFlaws)}`);
      
      console.info(`[TaskExecuteView] 📊 测试 - 使用列表接口: /agv/flaw/list?taskId=${this.taskId}`);
      const listResponse = await HttpUtil.get(`/agv/flaw/list?taskId=${this.taskId}`);
      console.info(`[TaskExecuteView] 📊 列表接口响应: ${JSON.stringify(listResponse)}`);
      
      // 定义响应数据类型
      interface TableDataInfo {
        total?: number;
        rows?: LiveFlaw[];
      }
      
      let newFlaws: LiveFlaw[] = [];
      if (listResponse.code === 200 && listResponse.data) {
        const responseData = listResponse.data as TableDataInfo;
        if (responseData && Array.isArray(responseData.rows)) {
          newFlaws = responseData.rows;
          console.info(`[TaskExecuteView] 📊 使用列表接口数据，故障数量: ${newFlaws.length}`);
        } else {
          newFlaws = liveFlaws;
          console.info(`[TaskExecuteView] 📊 列表接口数据格式异常，使用实时接口数据，故障数量: ${newFlaws.length}`);
        }
      } else {
        newFlaws = liveFlaws;
        console.info(`[TaskExecuteView] 📊 列表接口调用失败，使用实时接口数据，故障数量: ${newFlaws.length}`);
      }
      
      // 详细记录响应数据
      console.info(`[TaskExecuteView] 📊 响应数据类型: ${typeof newFlaws}`);
      console.info(`[TaskExecuteView] 📊 响应数据长度: ${Array.isArray(newFlaws) ? newFlaws.length : 'N/A'}`);
      console.info(`[TaskExecuteView] 📊 响应数据内容: ${JSON.stringify(newFlaws)}`);
      
      if (Array.isArray(newFlaws) && newFlaws.length > 0) {
        console.info(`[TaskExecuteView] 📊 故障详情列表:`);
        newFlaws.forEach((flaw, index) => {
          console.info(`[TaskExecuteView] 📊 故障${index + 1}: ID=${flaw.id}, 名称=${flaw.flawName}, 类型=${flaw.flawType}, 确认状态=${flaw.confirmed ? '已确认' : '待确认'}`);
        });
      } else {
        console.info(`[TaskExecuteView] 📊 当前任务无故障数据或响应格式异常`);
      }
      
      // 检查是否有新故障
      if (newFlaws.length > this.lastFlawCount) {
        const newFlawsAdded = newFlaws.slice(this.lastFlawCount);
        
        console.info(`[TaskExecuteView] 🚨 检测到新故障: 之前${this.lastFlawCount}个，现在${newFlaws.length}个，新增${newFlawsAdded.length}个`);
        
        // 显示新故障提示
        setTimeout(() => {
          try {
            promptAction.showToast({
              message: `发现${newFlawsAdded.length}个新故障，请及时处理`,
              duration: 3000
            });
          } catch (toastError) {
            console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
          }
        }, 0);
        
        // 如果有新故障，显示弹窗提醒第一个新故障
        if (newFlawsAdded.length > 0) {
          this.showNewFlawAlert(newFlawsAdded[0]);
          console.info(`[TaskExecuteView] 🔔 显示新故障弹窗: ${newFlawsAdded[0].flawName}`);
        }
        
        console.info(`[TaskExecuteView] 🚨 新增故障列表: ${newFlawsAdded.map(f => f.flawName).join(', ')}`);
      } else {
        console.info(`[TaskExecuteView] 📊 故障数量无变化: ${newFlaws.length}`);
      }
      
      this.liveFlaws = newFlaws;
      this.lastFlawCount = newFlaws.length;
      
      console.info(`[TaskExecuteView] ✅ 实时故障数据更新完成 - 当前故障数: ${newFlaws.length}, 上次计数: ${this.lastFlawCount}`);
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 更新实时故障失败:', error);
      console.error(`[TaskExecuteView] 📊 错误详情 - taskId: ${this.taskId}, 错误类型: ${typeof error}`);
      console.error(`[TaskExecuteView] 📊 错误内容: ${JSON.stringify(error)}`);
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
      console.info('[finishTask] 🏁 完成任务 - 开始执行');
      console.info('[finishTask] 📊 当前状态 taskId:', this.taskId);
      console.info('[finishTask] 📊 当前状态 isTaskRunning:', this.isTaskRunning);
      console.info('[finishTask] 📊 当前状态 timestamp:', new Date().toISOString());
      
      // 先停止AGV确保安全
      console.info('[finishTask] 🛑 正在停止AGV...');
      await AgvMovementService.agvStop();
      console.info('[finishTask] ✅ AGV已停止');
      
      // 调用后端接口结束任务
      console.info('[finishTask] 📡 正在调用后端接口结束任务...');
      const endTaskUrl = `/agv/task/end/${this.taskId}?isAbort=false`;
      console.info('[finishTask] 🔗 请求URL:', endTaskUrl);
      
      const response = await HttpUtil.post(endTaskUrl);
      console.info('[finishTask] 📥 后端响应 code:', response.code);
      console.info('[finishTask] 📥 后端响应 message:', response.msg);
      console.info('[finishTask] 📥 后端响应 timestamp:', new Date().toISOString());
      
      if (response.code === 200) {
        console.info('[finishTask] ✅ 后端任务结束成功');
        
        // 显示成功提示
        try {
          promptAction.showToast({
            message: '任务已完成',
            duration: 2000
          });
          console.info('[finishTask] ✅ 成功提示已显示');
        } catch (toastError) {
          console.warn('[finishTask] ⚠️ 显示提示失败:', toastError);
        }
        
        // 停止轮询和更新状态
        console.info('[finishTask] 🔄 正在停止轮询和更新状态...');
        this.stopPolling();
        this.isTaskRunning = false;
        console.info('[finishTask] ✅ 轮询已停止，状态已更新');
        
        // 准备页面跳转参数
        const routerParams: RouterParams = {
          url: 'pages/TaskReviewView',
          params: {
            taskId: this.taskId
          }
        };
        console.info('[finishTask] 🔄 准备页面跳转 url:', routerParams.url);
        console.info('[finishTask] 🔄 准备页面跳转 taskId:', routerParams.params.taskId);
        
        // 延迟执行页面跳转，确保UI上下文稳定
        setTimeout(() => {
          try {
            console.info('[finishTask] 🚀 开始执行页面跳转...');
            router.replaceUrl(routerParams).then(() => {
              console.info('[finishTask] ✅ 页面跳转成功');
            }).catch((routerError: Error) => {
              console.error('[finishTask] ❌ 页面跳转失败:', String(routerError));
              console.error('[finishTask] 🔍 跳转参数 url:', routerParams.url);
              console.error('[finishTask] 🔍 跳转参数 taskId:', routerParams.params.taskId);
              
              // 跳转失败时的备用方案
              try {
                promptAction.showToast({
                  message: '页面跳转失败，请手动返回任务列表',
                  duration: 3000
                });
              } catch (backupToastError) {
                console.error('[finishTask] ❌ 备用提示也失败:', backupToastError);
              }
            });
          } catch (routerSyncError) {
            console.error('[finishTask] ❌ 同步路由调用失败:', routerSyncError);
          }
        }, 500); // 延迟500ms执行跳转
        
        console.info('[finishTask] ✅ 任务完成流程执行完毕');
      } else {
        console.error('[finishTask] ❌ 后端返回错误 code:', response.code);
        console.error('[finishTask] ❌ 后端返回错误 message:', response.msg);
        throw new Error(`后端返回错误: ${response.msg}`);
      }
    } catch (error) {
      console.error('[finishTask] ❌ 完成任务失败:', error);
      console.error('[finishTask] 🔍 任务ID:', this.taskId);
      console.error('[finishTask] 🔍 错误时间:', new Date().toISOString());
      
      try {
        promptAction.showToast({
          message: '完成任务失败，请重试',
          duration: 2000
        });
      } catch (toastError) {
        console.error('[finishTask] ❌ 错误提示显示失败:', toastError);
      }
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

  async checkCameraConnection() {
    try {
      console.info('[TaskExecuteView] 🔍 检查摄像头连接状态');
      const isConnected = await CameraService.testConnection();
      this.cameraConnectionStatus = isConnected ? '连接正常' : '连接异常';
      this.lastCameraCheck = new Date().toLocaleTimeString();
      
      console.info('[TaskExecuteView] 📊 摄像头连接检查结果 isConnected:', isConnected);
      console.info('[TaskExecuteView] 📊 摄像头连接检查结果 checkTime:', this.lastCameraCheck);
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 摄像头连接检查失败:', error);
      this.cameraConnectionStatus = '检查失败';
      this.lastCameraCheck = new Date().toLocaleTimeString();
    }
  }

  refreshVideo() {
    if (this.cameras.length > 0 && this.currentCameraIndex >= 0) {
      const currentCamera = this.cameras[this.currentCameraIndex];
      this.videoUrl = CameraService.generateRefreshStreamUrl(currentCamera.id);
      
      console.info('[TaskExecuteView] 🔄 刷新视频流:', JSON.stringify({
        cameraId: currentCamera.id,
        cameraName: currentCamera.name,
        refreshUrl: this.videoUrl
      }));
      
      // 显示刷新提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: `正在刷新${currentCamera.name}视频流`,
            duration: 2000
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
    } else {
      console.warn('[TaskExecuteView] ⚠️ 无可用摄像头进行刷新');
    }
  }

  /**
   * 手动刷新摄像头列表
   */
  async refreshCameraList() {
    try {
      console.info('[TaskExecuteView] 🔄 手动刷新摄像头列表');
      
      // 显示加载提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '正在刷新摄像头列表...',
            duration: 1500
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
      
      // 重新获取摄像头列表
      const newCameras = await CameraService.getCameraInfoList();
      const oldCameraCount = this.cameras.length;
      this.cameras = newCameras;
      
      // 检查摄像头连接状态
      await this.checkCameraConnection();
      
      const logInfo: CameraLoadLogInfo = {
        cameraCount: this.cameras.length,
        cameras: this.cameras.map((c: CameraInfo): CameraInfoItem => ({ id: c.id, name: c.name }))
      };
      console.info('[TaskExecuteView] ✅ 摄像头列表刷新成功:', JSON.stringify(logInfo));
      
      // 如果当前选择的摄像头索引超出范围，重置为第一个
      if (this.currentCameraIndex >= this.cameras.length) {
        this.currentCameraIndex = 0;
      }
      
      // 如果有摄像头且当前没有选择，选择第一个
      if (this.cameras.length > 0 && this.currentCameraIndex >= 0) {
        this.switchCamera(this.currentCameraIndex);
      }
      
      // 显示刷新结果
      setTimeout(() => {
        try {
          const changeText = this.cameras.length !== oldCameraCount ? 
            `摄像头数量从${oldCameraCount}个变为${this.cameras.length}个` : 
            `摄像头列表已更新(${this.cameras.length}个)`;
          promptAction.showToast({
            message: changeText,
            duration: 2500
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
      
    } catch (error) {
      console.error('[TaskExecuteView] ❌ 刷新摄像头列表失败:', error);
      
      // 显示错误提示
      setTimeout(() => {
        try {
          promptAction.showToast({
            message: '刷新摄像头列表失败，请检查网络连接',
            duration: 3000
          });
        } catch (toastError) {
          console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
        }
      }, 0);
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

  // 显示新故障弹窗提醒
  showNewFlawAlert(flaw: LiveFlaw) {
    this.newFlawAlert = {
      show: true,
      flaw: flaw
    };
    console.info('[TaskExecuteView] 🔔 显示新故障弹窗:', flaw.flawName);
  }

  // 关闭新故障弹窗
  closeNewFlawAlert() {
    this.newFlawAlert = {
      show: false,
      flaw: null
    };
  }

  // 从新故障弹窗查看详情
  viewFlawFromAlert() {
    if (this.newFlawAlert.flaw) {
      this.openFlawDetail(this.newFlawAlert.flaw);
      this.closeNewFlawAlert();
    }
  }

  getFlawStatusColor(status: string): string {
    switch (status) {
      case 'confirmed':
        return '#f56c6c';
      case 'pending':
        return '#e6a23c';
      default:
        return '#909399';
    }
  }

  /**
   * 获取摄像头状态颜色
   * @param status 摄像头状态
   * @returns 状态对应的颜色
   */
  getStatusColor(status: string): string {
    switch (status) {
      case 'online':
        return AppConstants.COLORS.SUCCESS;
      case 'offline':
        return AppConstants.COLORS.DANGER;
      default:
        return AppConstants.COLORS.WARNING;
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
        // 主要内容 - 添加滚动功能
        Scroll() {
          Row() {
          // 左侧视频区域
          Column() {
            // 摄像头连接状态信息
            Row() {
              Column() {
                Row() {
                  Text('摄像头服务:')
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                  
                  Text(this.cameraConnectionStatus)
                    .fontSize(12)
                    .fontColor(this.cameraConnectionStatus === '连接正常' ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.DANGER)
                    .margin({ left: 8 })
                  
                  if (this.lastCameraCheck) {
                    Text(`(${this.lastCameraCheck})`)
                      .fontSize(10)
                      .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                      .margin({ left: 5 })
                  }
                  
                  Text(`视频源: ${this.cameras.length}个`)
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ left: 15 })
                }
                .alignItems(VerticalAlign.Center)
              }
              .layoutWeight(1)
              
              // 手动刷新摄像头列表按钮
              Button('🔄 刷新摄像头列表')
                .fontSize(11)
                .fontColor(AppConstants.COLORS.PRIMARY)
                .backgroundColor('transparent')
                .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .onClick(() => this.refreshCameraList())
            }
            .width('100%')
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor('#f8f9fa')
            .border({ width: { bottom: 1 }, color: '#eeeeee' })
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            // 视频播放器
            Stack() {
              if (this.videoUrl && this.cameras.length > 0) {
                Video({
                  src: this.videoUrl
                })
                  .width('100%')
                  .height(450)
                  .autoPlay(true)
                  .controls(false)
                  .objectFit(ImageFit.Contain)
                  .backgroundColor('#000000')
                  .onStart(() => {
                    console.info('[TaskExecuteView] ▶️ 视频开始播放:', this.cameras[this.currentCameraIndex]?.name);
                  })
                  .onPause(() => {
                    console.info('[TaskExecuteView] ⏸️ 视频暂停');
                  })
                  .onFinish(() => {
                    console.info('[TaskExecuteView] 🔚 视频播放结束');
                  })
                  .onError(() => {
                    console.error('[TaskExecuteView] ❌ 视频播放错误');
                    setTimeout(() => {
                      try {
                        promptAction.showToast({
                          message: `视频流连接失败，请检查网络或重新刷新`,
                          duration: 3000
                        });
                      } catch (toastError) {
                        console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
                      }
                    }, 0);
                  })
              } else {
                Column() {
                  Text('📹')
                    .fontSize(48)
                    .fontColor('#cccccc')
                  Text(this.cameras.length === 0 ? '无可用摄像头' : '正在连接视频流...')
                    .fontSize(16)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ top: 10 })
                  
                  if (this.cameras.length === 0) {
                    Text('请检查摄像头设备连接状态')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                      .margin({ top: 5 })
                  }
                }
                .width('100%')
                .height(450)
                .justifyContent(FlexAlign.Center)
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
                  .enabled(this.cameras.length > 0)
                  .onClick(() => this.refreshVideo())

                Button(this.isAudioEnabled ? '🔊' : '🔇')
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor('rgba(0,0,0,0.6)')
                  .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
                  .borderRadius(4)
                  .margin({ left: 10 })
                  .enabled(this.cameras.length > 0)
                  .onClick(() => {
                    this.isAudioEnabled = !this.isAudioEnabled;
                    const statusText = this.isAudioEnabled ? '音频已开启' : '音频已关闭';
                    setTimeout(() => {
                      try {
                        promptAction.showToast({
                          message: statusText,
                          duration: 1500
                        });
                      } catch (toastError) {
                        console.warn('[TaskExecuteView] ⚠️ Toast显示失败:', toastError);
                      }
                    }, 0);
                  })
                
                // 显示当前摄像头状态
                if (this.cameras.length > 0 && this.currentCameraIndex >= 0) {
                  Text(`📹 ${this.cameras[this.currentCameraIndex].name}`)
                    .fontSize(12)
                    .fontColor('#ffffff')
                    .backgroundColor('rgba(0,0,0,0.6)')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(4)
                    .margin({ left: 10 })
                }
              }
              .position({ x: 10, y: 10 })
            }
            .width('100%')
            .borderRadius(8)
            .border({ width: 1, color: '#dddddd' })

            // 摄像头切换
            if (this.cameras.length > 0) {
              Column() {
                Text(`摄像头列表 (${this.cameras.length}个)`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .margin({ bottom: 10 })
                
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.cameras, (camera: Camera, index: number) => {
                    Button() {
                      Column() {
                        Text(camera.name)
                          .fontSize(12)
                          .fontColor(index === this.currentCameraIndex ? '#ffffff' : AppConstants.COLORS.TEXT_PRIMARY)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        
                        Text(camera.status || 'unknown')
                          .fontSize(10)
                          .fontColor(index === this.currentCameraIndex ? 'rgba(255,255,255,0.8)' : this.getStatusColor(camera.status || 'unknown'))
                          .margin({ top: 2 })
                      }
                      .alignItems(HorizontalAlign.Center)
                    }
                    .backgroundColor(index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#ffffff')
                    .border({ 
                      width: 1, 
                      color: index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#dddddd' 
                    })
                    .borderRadius(6)
                    .margin({ right: 8, bottom: 8 })
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .onClick(() => this.switchCamera(index))
                  }, (camera: Camera) => camera.id)
                }
                .width('100%')
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#f8f9fa')
              .border({ width: { top: 1 }, color: '#eeeeee' })
            }
      

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

              Stack({ alignContent: Alignment.Start }) {
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
                  .alignSelf(ItemAlign.Start)

                // 车辆位置标记
                Text('🚛')
                  .fontSize(20)
                  .position({ x: `${Math.min(Math.max(Math.round(this.vehicleStatus.position / 10), 0), 100)}%`, y: -6 })

                // 故障标记
                ForEach(this.liveFlaws, (flaw: LiveFlaw, index: number) => {
                  Button()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(this.getFlawStatusColor(flaw.confirmed ? 'confirmed' : 'pending'))
                    .position({ x: `${(index + 1) * 20}%`, y: -2 })
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
                        .fontColor(this.getFlawStatusColor(flaw.confirmed ? 'confirmed' : 'pending'))
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
      .alignItems(VerticalAlign.Top)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .scrollBarColor('#CCCCCC')
        .scrollBarWidth(6)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .layoutWeight(1)
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

    // 新故障提醒弹窗
    if (this.newFlawAlert.show && this.newFlawAlert.flaw) {
      Stack() {
        Column() {
          // 弹窗标题
          Row() {
            Text('⚠️')
              .fontSize(24)
              .fontColor('#FF6B35')
            
            Text('发现新故障')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B35')
              .margin({ left: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ bottom: 16 })

          // 故障信息
          Column() {
            Row() {
              Text('故障名称：')
                .fontSize(14)
                .fontColor('#666666')
                .width(80)
              Text(this.newFlawAlert.flaw.flawName || '未知故障')
                .fontSize(14)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('故障类型：')
                .fontSize(14)
                .fontColor('#666666')
                .width(80)
              Text(this.newFlawAlert.flaw.flawType || '未知类型')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('发现时间：')
                .fontSize(14)
                .fontColor('#666666')
                .width(80)
              Text(this.newFlawAlert.flaw.createTime ? new Date(this.newFlawAlert.flaw.createTime).toLocaleString() : '')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 20 })

          // 操作按钮
          Row() {
            Button('稍后处理')
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(6)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .onClick(() => {
                this.closeNewFlawAlert();
              })

            Button('查看详情')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#007AFF')
              .borderRadius(6)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .margin({ left: 12 })
              .onClick(() => {
                this.viewFlawFromAlert();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
        }
        .width(320)
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({
          radius: 20,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
}
}