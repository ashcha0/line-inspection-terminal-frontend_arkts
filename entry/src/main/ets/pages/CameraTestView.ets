import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { CameraService, CameraInfo } from '../services/CameraService';
import { AppConstants } from '../constants/AppConstants';

/**
 * 摄像头测试页面
 * 用于测试实时视频流功能，包括摄像头列表获取、视频播放、摄像头切换等
 */
@Entry
@Component
struct CameraTestView {
  @State cameras: CameraInfo[] = [];
  @State currentCameraIndex: number = 0;
  @State videoUrl: string = '';
  @State loading: boolean = true;
  @State isPlaying: boolean = false;
  @State isAudioEnabled: boolean = true;
  @State connectionStatus: string = '连接中...';
  @State lastRefreshTime: string = '';

  aboutToAppear() {
    console.info('[CameraTestView] 📹 摄像头测试页面初始化');
    this.loadCameras();
    this.testConnection();
  }

  /**
   * 测试摄像头服务连接
   */
  async testConnection() {
    try {
      console.info('[CameraTestView] 🔍 测试摄像头服务连接');
      const isConnected = await CameraService.testConnection();
      this.connectionStatus = isConnected ? '连接正常' : '连接失败';
      
      console.info('[CameraTestView] 📊 连接测试结果:', this.connectionStatus);
    } catch (error) {
      console.error('[CameraTestView] ❌ 连接测试异常:', error);
      this.connectionStatus = '连接异常';
    }
  }

  /**
   * 加载摄像头列表
   */
  async loadCameras() {
    try {
      console.info('[CameraTestView] 📹 开始加载摄像头列表');
      this.loading = true;
      
      // 获取摄像头信息列表
      this.cameras = await CameraService.getCameraInfoList();
      
      console.info('[CameraTestView] ✅ 摄像头列表加载成功, 摄像头数量:', this.cameras.length.toString());
      
      // 如果有摄像头，默认选择第一个
      if (this.cameras.length > 0) {
        this.switchCamera(0);
        console.info('[CameraTestView] 🎥 默认选择第一个摄像头:', this.cameras[0].name);
      } else {
        console.warn('[CameraTestView] ⚠️ 未发现可用摄像头');
        this.showToast('未发现可用摄像头，请检查设备连接');
      }
    } catch (error) {
      console.error('[CameraTestView] ❌ 加载摄像头列表失败:', error);
      this.showToast('摄像头连接失败，请检查网络连接');
    } finally {
      this.loading = false;
    }
  }

  /**
   * 切换摄像头
   * @param index 摄像头索引
   */
  switchCamera(index: number) {
    if (index >= 0 && index < this.cameras.length) {
      this.currentCameraIndex = index;
      this.videoUrl = this.cameras[index].url;
      this.isPlaying = true;
      
      console.info('[CameraTestView] 🔄 切换摄像头:', JSON.stringify({
        cameraIndex: index,
        cameraId: this.cameras[index].id,
        cameraName: this.cameras[index].name,
        videoUrl: this.videoUrl
      }));
      
      this.showToast(`已切换到${this.cameras[index].name}`);
    } else {
      console.warn('[CameraTestView] ⚠️ 无效的摄像头索引:', index);
    }
  }

  /**
   * 刷新视频流
   */
  refreshVideo() {
    if (this.cameras.length > 0 && this.currentCameraIndex >= 0) {
      const currentCamera = this.cameras[this.currentCameraIndex];
      this.videoUrl = CameraService.generateRefreshStreamUrl(currentCamera.id);
      this.lastRefreshTime = new Date().toLocaleTimeString();
      
      console.info('[CameraTestView] 🔄 刷新视频流:', JSON.stringify({
        cameraId: currentCamera.id,
        cameraName: currentCamera.name,
        refreshUrl: this.videoUrl,
        refreshTime: this.lastRefreshTime
      }));
      
      this.showToast(`正在刷新${currentCamera.name}视频流`);
    } else {
      console.warn('[CameraTestView] ⚠️ 无可用摄像头进行刷新');
      this.showToast('无可用摄像头');
    }
  }

  /**
   * 重新加载摄像头列表
   */
  reloadCameras() {
    console.info('[CameraTestView] 🔄 重新加载摄像头列表');
    this.loadCameras();
    this.testConnection();
  }

  /**
   * 显示Toast提示
   * @param message 提示消息
   */
  showToast(message: string) {
    setTimeout(() => {
      try {
        promptAction.showToast({
          message: message,
          duration: 2000
        });
      } catch (error) {
        console.warn('[CameraTestView] ⚠️ Toast显示失败:', error);
      }
    }, 0);
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
      // 顶部导航栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .backgroundColor('transparent')
          .onClick(() => {
            router.back();
          })
        
        Text('摄像头测试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('🔄 重载')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.PRIMARY)
          .backgroundColor('transparent')
          .onClick(() => this.reloadCameras())
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
          
          Text('正在连接摄像头服务...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            .margin({ top: 10 })
          
          Text(`连接状态: ${this.connectionStatus}`)
            .fontSize(12)
            .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
            .margin({ top: 5 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 主要内容
        Column() {
          // 连接状态信息
          Row() {
            Text('服务状态:')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            
            Text(this.connectionStatus)
              .fontSize(14)
              .fontColor(this.connectionStatus === '连接正常' ? AppConstants.COLORS.SUCCESS : AppConstants.COLORS.DANGER)
              .margin({ left: 8 })
            
            Text(`摄像头数量: ${this.cameras.length}`)
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ left: 20 })
            
            if (this.lastRefreshTime) {
              Text(`最后刷新: ${this.lastRefreshTime}`)
                .fontSize(12)
                .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                .margin({ left: 20 })
            }
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#f8f9fa')
          .border({ width: { bottom: 1 }, color: '#eeeeee' })

          // 视频播放区域
          Column() {
            Stack() {
              if (this.videoUrl && this.cameras.length > 0) {
                Video({
                  src: this.videoUrl
                })
                  .width('100%')
                  .height(400)
                  .autoPlay(true)
                  .controls(false)
                  .objectFit(ImageFit.Contain)
                  .backgroundColor('#000000')
                  .onStart(() => {
                    this.isPlaying = true;
                    console.info('[CameraTestView] ▶️ 视频开始播放');
                  })
                  .onPause(() => {
                    this.isPlaying = false;
                    console.info('[CameraTestView] ⏸️ 视频暂停');
                  })
                  .onError(() => {
                    console.error('[CameraTestView] ❌ 视频播放错误');
                    this.showToast('视频播放失败，请检查网络连接');
                  })
              } else {
                Column() {
                  Text('📹')
                    .fontSize(48)
                    .fontColor('#cccccc')
                  Text(this.cameras.length === 0 ? '无可用摄像头' : '视频加载中...')
                    .fontSize(16)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ top: 10 })
                }
                .width('100%')
                .height(400)
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
                    this.showToast(this.isAudioEnabled ? '音频已开启' : '音频已关闭');
                  })
                
                Text(this.isPlaying ? '▶️ 播放中' : '⏸️ 已暂停')
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor('rgba(0,0,0,0.6)')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
                  .margin({ left: 10 })
              }
              .position({ x: 10, y: 10 })
            }
            .width('100%')
            .borderRadius(8)
            .border({ width: 1, color: '#dddddd' })

            // 当前摄像头信息
            if (this.cameras.length > 0 && this.currentCameraIndex >= 0) {
              Row() {
                Text('当前摄像头:')
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                
                Text(this.cameras[this.currentCameraIndex].name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .margin({ left: 8 })
                
                Text(`(${this.cameras[this.currentCameraIndex].id})`)
                  .fontSize(12)
                  .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
                  .margin({ left: 4 })
                
                Text(this.cameras[this.currentCameraIndex].status)
                  .fontSize(12)
                  .fontColor(this.getStatusColor(this.cameras[this.currentCameraIndex].status))
                  .margin({ left: 10 })
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#f8f9fa')
              .margin({ top: 10 })
            }
          }
          .layoutWeight(1)
          .padding(20)

          // 摄像头切换区域
          if (this.cameras.length > 0) {
            Column() {
              Text('摄像头列表')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })
              
              // 摄像头按钮列表
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.cameras, (camera: CameraInfo, index: number) => {
                  Button() {
                    Column() {
                      Text(camera.name)
                        .fontSize(14)
                        .fontColor(index === this.currentCameraIndex ? '#ffffff' : AppConstants.COLORS.TEXT_PRIMARY)
                      
                      Text(camera.status)
                        .fontSize(10)
                        .fontColor(index === this.currentCameraIndex ? 'rgba(255,255,255,0.8)' : this.getStatusColor(camera.status))
                        .margin({ top: 2 })
                    }
                  }
                  .backgroundColor(index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#ffffff')
                  .border({ 
                    width: 1, 
                    color: index === this.currentCameraIndex ? AppConstants.COLORS.PRIMARY : '#dddddd' 
                  })
                  .borderRadius(6)
                  .margin({ right: 10, bottom: 10 })
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .onClick(() => this.switchCamera(index))
                }, (camera: CameraInfo) => camera.id)
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#ffffff')
            .border({ width: { top: 1 }, color: '#eeeeee' })
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}