import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';
import { AgvMovementService } from './AgvMovementService';

// AGV配置接口定义
export interface AgvConfig {
  id: number;
  host: string;
  drivePort: number;
  analysisPort: number;
  cloudUrl: string;
  cam1: string;
  cam2: string;
  cam3: string;
  cam4: string;
  username1: string;
  username2: string;
  username3: string;
  username4: string;
  password1: string;
  password2: string;
  password3: string;
  password4: string;
  deleteFlag?: boolean;
}

// 摄像头设备接口
export interface CameraDevice {
  id: string;
  name: string;
  status: string;
  ip?: string;
  port?: number;
  username?: string;
  password?: string;
}

// 摄像头设备列表响应接口
export interface CameraDeviceResponse {
  total: number;
  rows: CameraDevice[];
  code: number;
  msg: string;
}

// 配置验证结果接口
export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

/**
 * 配置管理服务类
 * 提供系统配置的获取、更新和摄像头设备管理功能
 */
export class ConfigService {
  
  /**
   * 获取系统配置
   * @returns 系统配置信息
   */
  static async getConfig(): Promise<AgvConfig> {
    try {
      console.info('[ConfigService] 🔧 获取系统配置');
      const response = await HttpUtil.get('/agv/config');
      console.info('[ConfigService] ✅ 系统配置获取成功');
      return response.data as AgvConfig;
    } catch (error) {
      console.error('[ConfigService] ❌ 获取系统配置失败:', error);
      throw new Error('获取系统配置失败');
    }
  }
  
  /**
   * 更新系统配置
   * @param config 配置对象
   * @returns 更新结果
   */
  static async updateConfig(config: AgvConfig): Promise<Object> {
    try {
      console.info('[ConfigService] 📝 更新系统配置');
      const response = await HttpUtil.put('/agv/config', config);
      console.info('[ConfigService] ✅ 系统配置更新成功');
      return response;
    } catch (error) {
      console.error('[ConfigService] ❌ 更新系统配置失败:', error);
      throw new Error('更新系统配置失败');
    }
  }
  
  /**
   * 获取摄像头设备列表
   * @param page 页码，默认1
   * @param size 每页大小，默认999
   * @param status 设备状态筛选
   * @param id 设备ID筛选
   * @param name 设备名称筛选
   * @returns 摄像头设备列表
   */
  static async getDeviceList(
    page: number = 1, 
    size: number = 999, 
    status?: string, 
    id?: string, 
    name?: string
  ): Promise<CameraDeviceResponse> {
    try {
      console.info('[ConfigService] 📹 获取摄像头设备列表');
      
      let queryString = `page=${page}&size=${size}`;
      
      if (status) queryString += `&status=${status}`;
      if (id) queryString += `&id=${id}`;
      if (name) queryString += `&name=${name}`;
      
      const response = await HttpUtil.get(
        `${AppConstants.CAMERA_BASE_URL}/devices?${queryString}`,
        {
          headers: {
            'Authorization': 'Basic YWRtaW4xMjM6QWRtaW5AMTIz'
          }
        }
      );
      
      interface DeviceResponseData {
        total?: number;
        rows?: CameraDevice[];
      }
      const deviceData = response.data as DeviceResponseData;
      console.info('[ConfigService] ✅ 摄像头设备列表获取成功，数量:', deviceData?.total || 0);
      
      return {
        total: deviceData?.total || 0,
        rows: deviceData?.rows || [],
        code: response.code,
        msg: response.msg
      };
    } catch (error) {
      console.error('[ConfigService] ❌ 获取摄像头设备列表失败:', error);
      throw new Error('获取摄像头设备列表失败');
    }
  }
  
  /**
   * 测试AGV连接
   * @param host AGV主机地址
   * @param port AGV端口
   * @returns 连接测试结果
   */
  static async testAgvConnection(host: string, port: number): Promise<boolean> {
    try {
      console.info(`[ConfigService] 🔗 测试AGV连接: ${host}:${port}`);
      
      // 使用AgvMovementService的心跳检测来测试连接
      const heartbeatResult = await AgvMovementService.heartbeat();
      
      const isConnected = heartbeatResult.success;
      console.info(`[ConfigService] ${isConnected ? '✅' : '❌'} AGV连接测试${isConnected ? '成功' : '失败'}`);
      console.info(`[ConfigService] 📊 AGV状态: ${heartbeatResult.status}, 消息: ${heartbeatResult.message || '无'}`);
      
      return isConnected;
    } catch (error) {
      console.error('[ConfigService] ❌ AGV连接测试失败:', error);
      return false;
    }
  }
  
  /**
   * 测试摄像头连接
   * @param cameraUrl 摄像头地址
   * @param username 用户名
   * @param password 密码
   * @returns 连接测试结果
   */
  static async testCameraConnection(cameraUrl: string, username: string, password: string): Promise<boolean> {
    try {
      console.info(`[ConfigService] 📹 测试摄像头连接: ${cameraUrl}`);
      
      // 这里可以尝试获取摄像头设备列表来测试连接
      const response = await HttpUtil.get(
        `${AppConstants.CAMERA_BASE_URL}/devices?page=1&size=1`,
        {
          headers: {
            'Authorization': 'Basic YWRtaW4xMjM6QWRtaW5AMTIz'
          },
          timeout: 5000 // 5秒超时
        }
      );
      
      const isConnected = response.code === 200;
      console.info(`[ConfigService] ${isConnected ? '✅' : '❌'} 摄像头连接测试${isConnected ? '成功' : '失败'}`);
      return isConnected;
    } catch (error) {
      console.error('[ConfigService] ❌ 摄像头连接测试失败:', error);
      return false;
    }
  }
  
  /**
   * 验证配置参数
   * @param config 配置对象
   * @returns 验证结果
   */
  static validateConfig(config: AgvConfig): ValidationResult {
    const errors: string[] = [];
    
    // 验证AGV配置
    if (!config.host || config.host.trim() === '') {
      errors.push('AGV主机地址不能为空');
    }
    
    if (!config.drivePort || config.drivePort <= 0 || config.drivePort > 65535) {
      errors.push('AGV驱动端口必须在1-65535之间');
    }
    
    if (!config.analysisPort || config.analysisPort <= 0 || config.analysisPort > 65535) {
      errors.push('AGV分析端口必须在1-65535之间');
    }
    
    // 验证云端地址
    if (!config.cloudUrl || config.cloudUrl.trim() === '') {
      errors.push('云端地址不能为空');
    }
    
    // 验证摄像头配置
    const cameras = [config.cam1, config.cam2, config.cam3, config.cam4];
    const usernames = [config.username1, config.username2, config.username3, config.username4];
    const passwords = [config.password1, config.password2, config.password3, config.password4];
    
    for (let i = 0; i < cameras.length; i++) {
      if (cameras[i] && cameras[i].trim() !== '') {
        if (!usernames[i] || usernames[i].trim() === '') {
          errors.push(`摄像头${i + 1}用户名不能为空`);
        }
        if (!passwords[i] || passwords[i].trim() === '') {
          errors.push(`摄像头${i + 1}密码不能为空`);
        }
      }
    }
    
    console.info(`[ConfigService] 🔍 配置验证${errors.length === 0 ? '通过' : '失败'}，错误数量: ${errors.length}`);
    
    const result: ValidationResult = {
      valid: errors.length === 0,
      errors: errors
    };
    return result;
  }
  
  /**
   * 获取默认配置
   * @returns 默认配置对象
   */
  static getDefaultConfig(): AgvConfig {
    const defaultConfig: AgvConfig = {
      id: 0,
      host: '192.168.2.57',
      drivePort: 8080,
      analysisPort: 8081,
      cloudUrl: 'http://192.168.2.57/prod-api',
      cam1: '',
      cam2: '',
      cam3: '',
      cam4: '',
      username1: 'admin123',
      username2: 'admin123',
      username3: 'admin123',
      username4: 'admin123',
      password1: 'Admin@123',
      password2: 'Admin@123',
      password3: 'Admin@123',
      password4: 'Admin@123'
    };
    return defaultConfig;
  }
}

// 添加水印标识
console.info('🏷️ [ConfigService] 智能巡线车手持终端 - 配置管理服务已加载');