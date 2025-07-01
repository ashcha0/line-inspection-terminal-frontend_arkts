// 接口定义
interface ApiEndpoints {
  SYSTEM_CHECK_FS: string;
  SYSTEM_CHECK_DB: string;
  SYSTEM_CHECK_AGV: string;
  SYSTEM_CHECK_CAM: string;
}

interface Routes {
  INIT: string;
  TASK_LIST: string;
  TASK_DETAIL: string;
  TASK_EXECUTE: string;
  SETTINGS: string;
}

interface TaskStatus {
  PENDING: string;
  RUNNING: string;
  UPLOADING: string;
  COMPLETED: string;
}

interface CheckItem {
  id: string;
  name: string;
  solution: string;
}

interface CheckItems {
  FS: CheckItem;
  DB: CheckItem;
  AGV: CheckItem;
  CAM: CheckItem;
}

interface Colors {
  PRIMARY: string;
  SUCCESS: string;
  WARNING: string;
  DANGER: string;
  INFO: string;
  TEXT_PRIMARY: string;
  TEXT_REGULAR: string;
  TEXT_SECONDARY: string;
  BORDER_BASE: string;
  BORDER_LIGHT: string;
  BACKGROUND_BASE: string;
}

interface Sizes {
  FONT_LARGE: number;
  FONT_MEDIUM: number;
  FONT_REGULAR: number;
  FONT_SMALL: number;
  BORDER_RADIUS: number;
  BORDER_RADIUS_LARGE: number;
  SPACING_SMALL: number;
  SPACING_MEDIUM: number;
  SPACING_LARGE: number;
}

// 应用常量配置
export class AppConstants {
  // API地址配置
  static readonly API_BASE_URL = 'http://192.168.2.57/prod-api';
  static readonly WEBRTC_BASE_URL = 'http://192.168.2.57/webrtc-api';
  static readonly CAMERA_BASE_URL = 'http://192.168.2.57/easy-api';
  
  // API端点配置
  static readonly API: ApiEndpoints = {
    SYSTEM_CHECK_FS: '/system/check/fs',
    SYSTEM_CHECK_DB: '/system/check/db',
    SYSTEM_CHECK_AGV: '/system/check/agv',
    SYSTEM_CHECK_CAM: '/system/check/cam'
  };
  
  // WiFi配置
  static readonly WIFI_SSID = 'inhand';
  static readonly WIFI_PASSWORD = '12345678';
  
  // 请求超时配置
  static readonly REQUEST_TIMEOUT = 10000;
  static readonly UPLOAD_TIMEOUT = 30000;
  
  // 页面路由
  static readonly ROUTES: Routes = {
    INIT: 'pages/InitView',
    TASK_LIST: 'pages/TaskView',
    TASK_DETAIL: 'pages/TaskDetailView',
    TASK_EXECUTE: 'pages/TaskExecuteView',
    SETTINGS: 'pages/SettingsView'
  };
  
  // 任务状态
  static readonly TASK_STATUS: TaskStatus = {
    PENDING: '待巡视',
    RUNNING: '巡视中',
    UPLOADING: '待上传',
    COMPLETED: '已完成'
  };
  
  // 检查项配置
  static readonly CHECK_ITEMS: CheckItems = {
    FS: {
      id: 'fs',
      name: '正在检查系统文件完整性',
      solution: '解决方案：请重新安装本系统。'
    },
    DB: {
      id: 'db',
      name: '正在检测数据库系统连接',
      solution: '解决方案：请检查数据库连接设置是否正确。'
    },
    AGV: {
      id: 'agv',
      name: '正在与车辆控制系统通信',
      solution: '解决方案：请检查巡检车IP与端口配置是否正确。'
    },
    CAM: {
      id: 'cam',
      name: '正在检测摄像头通道状态',
      solution: '解决方案：请检查摄像头IP及账号密码是否正确。'
    }
  };
  
  // 颜色配置
  static readonly COLORS: Colors = {
    PRIMARY: '#409eff',
    SUCCESS: '#67c23a',
    WARNING: '#e6a23c',
    DANGER: '#f56c6c',
    INFO: '#909399',
    TEXT_PRIMARY: '#333333',
    TEXT_REGULAR: '#666666',
    TEXT_SECONDARY: '#999999',
    BORDER_BASE: '#dddddd',
    BORDER_LIGHT: '#eeeeee',
    BACKGROUND_BASE: '#f5f5f5'
  };
  
  // 尺寸配置
  static readonly SIZES: Sizes = {
    FONT_LARGE: 24,
    FONT_MEDIUM: 18,
    FONT_REGULAR: 14,
    FONT_SMALL: 12,
    BORDER_RADIUS: 4,
    BORDER_RADIUS_LARGE: 8,
    SPACING_SMALL: 8,
    SPACING_MEDIUM: 16,
    SPACING_LARGE: 24
  };
}