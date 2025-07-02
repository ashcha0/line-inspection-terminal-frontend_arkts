import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigService, AgvConfig } from '../services/ConfigService';
import { SystemCheckService } from '../services/SystemCheckService';
import { AppConstants } from '../constants/AppConstants';

@Entry
@Component
struct SettingsView {
  @State config: AgvConfig = ConfigService.getDefaultConfig();
  @State loading: boolean = true;
  @State saving: boolean = false;
  @State testing: boolean = false;
  @State showPasswords: boolean[] = [false, false, false, false];
  @State expandedSections: boolean[] = [true, true, true]; // AGV配置、摄像头配置、云端配置
  @State validationErrors: string[] = [];
  
  aboutToAppear() {
    console.info('🏷️ [SettingsView] 智能巡线车手持终端 - 系统设置页面已加载');
    this.loadConfig();
  }
  
  async loadConfig() {
    try {
      console.info('[SettingsView] 📥 加载系统配置');
      this.config = await ConfigService.getConfig();
      console.info('[SettingsView] ✅ 系统配置加载成功');
    } catch (error) {
      console.error('[SettingsView] ❌ 加载系统配置失败:', error);
      promptAction.showToast({
        message: '加载配置失败，使用默认配置',
        duration: 2000
      });
    } finally {
      this.loading = false;
    }
  }
  
  async saveConfig() {
    try {
      // 验证配置
      const validation = ConfigService.validateConfig(this.config);
      if (!validation.valid) {
        this.validationErrors = validation.errors;
        promptAction.showToast({
          message: '配置验证失败，请检查输入',
          duration: 3000
        });
        return;
      }
      
      this.saving = true;
      console.info('[SettingsView] 💾 保存系统配置');
      
      await ConfigService.updateConfig(this.config);
      
      promptAction.showToast({
        message: '配置保存成功，请重新执行系统自检',
        duration: 3000
      });
      
      console.info('[SettingsView] ✅ 系统配置保存成功');
      
      // 保存成功后返回初始化页面重新自检
      setTimeout(() => {
        router.replaceUrl({
          url: AppConstants.ROUTES.INIT
        });
      }, 1000);
      
    } catch (error) {
      console.error('[SettingsView] ❌ 保存系统配置失败:', error);
      promptAction.showToast({
        message: '保存配置失败，请重试',
        duration: 2000
      });
    } finally {
      this.saving = false;
    }
  }
  
  async testConnection() {
    try {
      this.testing = true;
      console.info('[SettingsView] 🔗 测试连接');
      
      // 测试AGV连接
      const agvConnected = await ConfigService.testAgvConnection(this.config.host, this.config.drivePort);
      
      // 测试摄像头连接（测试第一个配置的摄像头）
      let cameraConnected = false;
      if (this.config.cam1 && this.config.username1 && this.config.password1) {
        cameraConnected = await ConfigService.testCameraConnection(
          this.config.cam1, 
          this.config.username1, 
          this.config.password1
        );
      }
      
      const message = `AGV连接: ${agvConnected ? '成功' : '失败'}\n摄像头连接: ${cameraConnected ? '成功' : '失败'}`;
      
      promptAction.showToast({
        message: message,
        duration: 3000
      });
      
      console.info(`[SettingsView] 🔗 连接测试完成 - AGV: ${agvConnected}, 摄像头: ${cameraConnected}`);
      
    } catch (error) {
      console.error('[SettingsView] ❌ 测试连接失败:', error);
      promptAction.showToast({
        message: '连接测试失败',
        duration: 2000
      });
    } finally {
      this.testing = false;
    }
  }
  
  togglePasswordVisibility(index: number) {
    this.showPasswords[index] = !this.showPasswords[index];
  }
  
  toggleSection(index: number) {
    this.expandedSections[index] = !this.expandedSections[index];
  }
  
  resetToDefault() {
    promptAction.showDialog({
      title: '确认重置',
      message: '确定要重置为默认配置吗？此操作不可撤销。',
      buttons: [
        {
          text: '取消',
          color: AppConstants.COLORS.TEXT_SECONDARY
        },
        {
          text: '确定',
          color: AppConstants.COLORS.DANGER
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.config = ConfigService.getDefaultConfig();
        this.validationErrors = [];
        console.info('[SettingsView] 🔄 配置已重置为默认值');
        promptAction.showToast({
          message: '已重置为默认配置',
          duration: 2000
        });
      }
    });
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
        
        Text('系统设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('重置')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.DANGER)
          .backgroundColor('transparent')
          .onClick(() => {
            this.resetToDefault();
          })
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: AppConstants.COLORS.BORDER_LIGHT })
      
      if (this.loading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(AppConstants.COLORS.PRIMARY)
          
          Text('加载配置中...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        
      } else {
        // 配置表单
        Scroll() {
          Column() {
            // 验证错误提示
            if (this.validationErrors.length > 0) {
              Column() {
                ForEach(this.validationErrors, (error: string) => {
                  Text(`• ${error}`)
                    .fontSize(12)
                    .fontColor(AppConstants.COLORS.DANGER)
                    .width('100%')
                    .margin({ bottom: 4 })
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#fef0f0')
              .borderRadius(8)
              .margin({ bottom: 16 })
            }
            
            // AGV配置区域
            this.buildAgvConfigSection()
            
            // 摄像头配置区域
            this.buildCameraConfigSection()
            
            
            // 云端配置区域
            this.buildCloudConfigSection()
            
            // 操作按钮
            Row() {
              Button('测试连接')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.INFO)
                .borderRadius(8)
                .width('48%')
                .height(44)
                .enabled(!this.testing && !this.saving)
                .onClick(() => {
                  this.testConnection();
                })
              
              Button(this.saving ? '保存中...' : '保存配置')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.PRIMARY)
                .borderRadius(8)
                .width('48%')
                .height(44)
                .enabled(!this.testing && !this.saving)
                .onClick(() => {
                  this.saveConfig();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 24, bottom: 24 })
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
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }
  
  @Builder
  buildAgvConfigSection() {
    Column() {
      // 区域标题
      Row() {
        Text('🚗 AGV配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Text(this.expandedSections[0] ? '▼' : '▶')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .onClick(() => {
        this.toggleSection(0);
      })
      
      // 区域内容
      if (this.expandedSections[0]) {
        Column() {
          this.buildAgvConfig()
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#ffffff')
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
    .border({ width: 1, color: AppConstants.COLORS.BORDER_LIGHT })
    .borderRadius(8)
  }
  
  @Builder
  buildCameraConfigSection() {
    Column() {
      // 区域标题
      Row() {
        Text('📹 摄像头配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Text(this.expandedSections[1] ? '▼' : '▶')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .onClick(() => {
        this.toggleSection(1);
      })
      
      // 区域内容
      if (this.expandedSections[1]) {
        Column() {
          this.buildCameraConfig()
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#ffffff')
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
    .border({ width: 1, color: AppConstants.COLORS.BORDER_LIGHT })
    .borderRadius(8)
  }
  
  @Builder
  buildCloudConfigSection() {
    Column() {
      // 区域标题
      Row() {
        Text('☁️ 云端配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Text(this.expandedSections[2] ? '▼' : '▶')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .borderRadius({ topLeft: 8, topRight: 8 })
      .onClick(() => {
        this.toggleSection(2);
      })
      
      // 区域内容
      if (this.expandedSections[2]) {
        Column() {
          this.buildCloudConfig()
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#ffffff')
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
    .border({ width: 1, color: AppConstants.COLORS.BORDER_LIGHT })
    .borderRadius(8)
  }
  
  @Builder
  buildAgvConfig() {
    Column() {
      // AGV主机地址
      this.buildInputField('主机地址', this.config.host, (value: string) => {
        this.config.host = value;
      }, '请输入AGV主机IP地址')
      
      // 驱动端口
      this.buildInputField('驱动端口', this.config.drivePort.toString(), (value: string) => {
        this.config.drivePort = parseInt(value) || 0;
      }, '请输入驱动端口', 'number')
      
      // 分析端口
      this.buildInputField('分析端口', this.config.analysisPort.toString(), (value: string) => {
        this.config.analysisPort = parseInt(value) || 0;
      }, '请输入分析端口', 'number')
    }
  }
  
  @Builder
  buildCameraConfig() {
    Column() {
      // 摄像头1
      this.buildCameraItem(1, this.config.cam1, this.config.username1, this.config.password1,
        (url: string) => { this.config.cam1 = url; },
        (username: string) => { this.config.username1 = username; },
        (password: string) => { this.config.password1 = password; }
      )
      
      // 摄像头2
      this.buildCameraItem(2, this.config.cam2, this.config.username2, this.config.password2,
        (url: string) => { this.config.cam2 = url; },
        (username: string) => { this.config.username2 = username; },
        (password: string) => { this.config.password2 = password; }
      )
      
      // 摄像头3
      this.buildCameraItem(3, this.config.cam3, this.config.username3, this.config.password3,
        (url: string) => { this.config.cam3 = url; },
        (username: string) => { this.config.username3 = username; },
        (password: string) => { this.config.password3 = password; }
      )
      
      // 摄像头4
      this.buildCameraItem(4, this.config.cam4, this.config.username4, this.config.password4,
        (url: string) => { this.config.cam4 = url; },
        (username: string) => { this.config.username4 = username; },
        (password: string) => { this.config.password4 = password; }
      )
    }
  }
  
  @Builder
  buildCloudConfig() {
    Column() {
      this.buildInputField('云端地址', this.config.cloudUrl, (value: string) => {
        this.config.cloudUrl = value;
      }, '请输入云端服务地址')
    }
  }
  
  @Builder
  buildCameraItem(
    index: number, 
    url: string, 
    username: string, 
    password: string,
    onUrlChange: (value: string) => void,
    onUsernameChange: (value: string) => void,
    onPasswordChange: (value: string) => void
  ) {
    Column() {
      Text(`摄像头${index}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
        .width('100%')
        .margin({ bottom: 8 })
      
      this.buildInputField('地址', url, onUrlChange, '请输入摄像头地址')
      this.buildInputField('用户名', username, onUsernameChange, '请输入用户名')
      this.buildPasswordField(`密码`, password, onPasswordChange, '请输入密码', index - 1)
    }
    .width('100%')
    .margin({ bottom: 16 })
    .padding(12)
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
    .borderRadius(6)
  }
  
  @Builder
  buildInputField(
    label: string, 
    value: string, 
    onChange: (value: string) => void, 
    placeholder: string = '',
    inputType: string = 'text'
  ) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 4 })
      
      TextInput({ text: value, placeholder: placeholder })
        .fontSize(14)
        .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
        .backgroundColor('#ffffff')
        .borderRadius(4)
        .border({ width: 1, color: AppConstants.COLORS.BORDER_BASE })
        .padding({ left: 12, right: 12 })
        .height(40)
        .width('100%')
        .type(inputType === 'number' ? InputType.Number : InputType.Normal)
        .onChange((value: string) => {
          onChange(value);
        })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
  
  @Builder
  buildPasswordField(
    label: string, 
    value: string, 
    onChange: (value: string) => void, 
    placeholder: string = '',
    index: number
  ) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 4 })
      
      Row() {
        TextInput({ text: value, placeholder: placeholder })
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .backgroundColor('#ffffff')
          .borderRadius(4)
          .border({ width: 1, color: AppConstants.COLORS.BORDER_BASE })
          .padding({ left: 12, right: 12 })
          .height(40)
          .layoutWeight(1)
          .type(this.showPasswords[index] ? InputType.Normal : InputType.Password)
          .onChange((value: string) => {
            onChange(value);
          })
        
        Button(this.showPasswords[index] ? '👁️' : '🙈')
          .fontSize(16)
          .fontColor(AppConstants.COLORS.TEXT_SECONDARY)
          .backgroundColor('transparent')
          .width(40)
          .height(40)
          .onClick(() => {
            this.togglePasswordVisibility(index);
          })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
}

// 添加水印标识
console.info('🏷️ [SettingsView] 智能巡线车手持终端 - 系统设置页面组件已加载');