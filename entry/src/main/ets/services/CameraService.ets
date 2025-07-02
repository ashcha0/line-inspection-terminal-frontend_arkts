import http from '@ohos.net.http';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 摄像头设备接口
export interface CameraDevice {
  id: string;
  name: string;
  status?: string;
  ip?: string;
  port?: number;
  channel?: number;
}

// 摄像头信息接口（用于UI显示）
export interface CameraInfo {
  id: string;
  name: string;
  url: string;
  status: string;
}

// 摄像头服务响应数据接口
interface CameraResponseData {
  items: CameraDevice[];
  total: number;
}

// 摄像头服务响应接口
interface CameraListResponse {
  code: number;
  msg: string;
  data: CameraResponseData;
}

// 日志信息接口（移除索引签名）
interface LogInfo {
  message?: string;
  data?: string;
}

// 设备日志信息接口
interface DeviceLogInfo {
  deviceCount: number;
  deviceIds: string[];
}

// 摄像头日志信息接口
interface CameraLogInfo {
  deviceId: string;
  cameraName: string;
  streamUrl: string;
}

// 流URL日志信息接口
interface StreamLogInfo {
  cameraId: string;
  streamUrl: string;
}

// 刷新URL日志信息接口
interface RefreshLogInfo {
  cameraId: string;
  timestamp: number;
  refreshUrl: string;
}

// 摄像头信息项接口
interface CameraInfoItem {
  id: string;
  name: string;
}

// 摄像头列表日志信息接口
interface CameraListLogInfo {
  totalCount: number;
  cameras: CameraInfoItem[];
}

// 连接测试日志信息接口
interface ConnectionLogInfo {
  isConnected: boolean;
  deviceCount: number;
}

/**
 * 摄像头服务类
 * 负责管理摄像头设备列表获取和视频流URL生成
 */
export class CameraService {
  // 摄像头服务认证头
  private static readonly AUTH_HEADER = 'Basic YWRtaW4xMjM6QWRtaW5AMTIz';
  
  /**
   * 获取摄像头设备列表
   * @returns Promise<CameraDevice[]> 摄像头设备列表
   */
  static async getCameraDevices(): Promise<CameraDevice[]> {
    try {
      console.info('[CameraService] 📹 开始获取摄像头设备列表');
      
      const url = `${AppConstants.CAMERA_BASE_URL}/devices?page=1&size=999&status=&id&name`;
      console.info('[CameraService] 📹 请求URL:', url);
      
      const response = await HttpUtil.request(url, {
        method: http.RequestMethod.GET,
        headers: {
          'Authorization': CameraService.AUTH_HEADER,
          'Content-Type': 'application/json'
        },
        timeout: AppConstants.REQUEST_TIMEOUT
      });
      
      console.info('[CameraService] 📹 摄像头服务响应:', JSON.stringify({
        code: response.code,
        dataType: typeof response.data,
        hasData: response.data ? true : false
      }));
      
      if (response.code === 200) {
        // 摄像头API直接返回数据，不是包装在HttpResponse中
        let responseData: CameraResponseData;
        
        if (response.data) {
          // 如果data存在，说明是包装的响应
          responseData = response.data as CameraResponseData;
        } else {
          // 如果data不存在，可能需要从原始响应中解析
          console.warn('[CameraService] ⚠️ 响应数据为空，尝试其他解析方式');
          return [];
        }
        
        if (responseData && responseData.items) {
          const devices = responseData.items;
          const logInfo: DeviceLogInfo = {
            deviceCount: devices.length,
            deviceIds: devices.map((d: CameraDevice) => d.id)
          };
          console.info('[CameraService] ✅ 成功获取摄像头设备列表:', JSON.stringify(logInfo));
          return devices;
        }
      }
      
      console.warn('[CameraService] ⚠️ 摄像头服务返回异常:', JSON.stringify({
         code: response.code,
         msg: response.msg,
         data: response.data
       }));
        return [];
    } catch (error) {
      console.error('[CameraService] ❌ 获取摄像头设备列表失败:', error);
      throw new Error(`获取摄像头设备列表失败: ${error}`);
    }
  }
  
  /**
   * 将摄像头设备转换为UI显示信息
   * @param devices 摄像头设备列表
   * @returns CameraInfo[] UI显示的摄像头信息列表
   */
  static convertToCameraInfo(devices: CameraDevice[]): CameraInfo[] {
    return devices.map((device, index) => {
      const cameraInfo: CameraInfo = {
        id: device.id,
        name: device.name || `摄像头${index + 1}`,
        url: CameraService.generateStreamUrl(device.id),
        status: device.status || 'unknown'
      };
      
      const logInfo: CameraLogInfo = {
        deviceId: device.id,
        cameraName: cameraInfo.name,
        streamUrl: cameraInfo.url
      };
      console.info('[CameraService] 🎥 生成摄像头信息:', JSON.stringify(logInfo));
      
      return cameraInfo;
    });
  }
  
  /**
   * 生成视频流URL
   * @param cameraId 摄像头ID
   * @returns string 视频流URL
   */
  static generateStreamUrl(cameraId: string): string {
    const streamUrl = `${AppConstants.WEBRTC_BASE_URL}/live/${cameraId}_01.flv`;
    const logInfo: StreamLogInfo = {
      cameraId: cameraId,
      streamUrl: streamUrl
    };
    console.info('[CameraService] 🔗 生成视频流URL:', JSON.stringify(logInfo));
    return streamUrl;
  }
  
  /**
   * 生成带时间戳的视频流URL（用于刷新）
   * @param cameraId 摄像头ID
   * @returns string 带时间戳的视频流URL
   */
  static generateRefreshStreamUrl(cameraId: string): string {
    const timestamp = Date.now();
    const refreshUrl = `${CameraService.generateStreamUrl(cameraId)}?t=${timestamp}`;
    const logInfo: RefreshLogInfo = {
      cameraId: cameraId,
      timestamp: timestamp,
      refreshUrl: refreshUrl
    };
    console.info('[CameraService] 🔄 生成刷新视频流URL:', JSON.stringify(logInfo));
    return refreshUrl;
  }
  
  /**
   * 获取摄像头信息列表（设备列表 + UI信息转换的组合方法）
   * @returns Promise<CameraInfo[]> 摄像头信息列表
   */
  static async getCameraInfoList(): Promise<CameraInfo[]> {
    try {
      console.info('[CameraService] 🎬 开始获取摄像头信息列表');
      
      const devices = await CameraService.getCameraDevices();
      const cameraInfoList = CameraService.convertToCameraInfo(devices);
      
      const logInfo: CameraListLogInfo = {
        totalCount: cameraInfoList.length,
        cameras: cameraInfoList.map((c: CameraInfo): CameraInfoItem => ({ id: c.id, name: c.name }))
      };
      console.info('[CameraService] ✅ 摄像头信息列表获取成功:', JSON.stringify(logInfo));
      
      return cameraInfoList;
    } catch (error) {
      console.error('[CameraService] ❌ 获取摄像头信息列表失败:', error);
      throw new Error(`获取摄像头信息列表失败: ${error}`);
    }
  }
  
  /**
   * 测试摄像头服务连接
   * @returns Promise<boolean> 连接测试结果
   */
  static async testConnection(): Promise<boolean> {
    try {
      console.info('[CameraService] 🔍 测试摄像头服务连接');
      
      const devices = await CameraService.getCameraDevices();
      const isConnected = devices.length >= 0; // 即使没有设备，能正常响应也算连接成功
      
      const logInfo: ConnectionLogInfo = {
        isConnected: isConnected,
        deviceCount: devices.length
      };
      console.info('[CameraService] ✅ 摄像头服务连接测试结果:', JSON.stringify(logInfo));
      
      return isConnected;
    } catch (error) {
      console.error('[CameraService] ❌ 摄像头服务连接测试失败:', error);
      return false;
    }
  }
}