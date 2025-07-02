import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 检查结果接口
export interface CheckResult {
  success: boolean;
  message?: string;
  errorCode?: number;
}

// 系统检查全部结果接口
export interface SystemCheckAllResult {
  fs: CheckResult;
  db: CheckResult;
  agv: CheckResult;
  cam: CheckResult;
  allPassed: boolean;
}

// 系统检查服务类
export class SystemCheckService {
  
  /**
   * 检查文件系统
   */
  static async checkFileSystem(): Promise<CheckResult> {
    try {
      console.info('[SystemCheckService] 开始检查文件系统');
      const response = await HttpUtil.get(AppConstants.API.SYSTEM_CHECK_FS);
      console.info('[SystemCheckService] 文件系统检查响应:', JSON.stringify(response));
      return {
        success: response.code === 200,
        message: response.msg,
        errorCode: response.code
      };
    } catch (error) {
      console.error('[SystemCheckService] 文件系统检查异常:', error);
      return {
        success: false,
        message: '文件系统检查失败',
        errorCode: -1
      };
    }
  }

  /**
   * 检查数据库连接
   */
  static async checkDatabase(): Promise<CheckResult> {
    try {
      console.info('[SystemCheckService] 开始检查数据库连接');
      const response = await HttpUtil.get(AppConstants.API.SYSTEM_CHECK_DB);
      console.info('[SystemCheckService] 数据库检查响应:', JSON.stringify(response));
      return {
        success: response.code === 200,
        message: response.msg,
        errorCode: response.code
      };
    } catch (error) {
      console.error('[SystemCheckService] 数据库检查异常:', error);
      return {
        success: false,
        message: '数据库连接检查失败',
        errorCode: -1
      };
    }
  }

  /**
   * 检查AGV连接
   */
  static async checkAgv(): Promise<CheckResult> {
    try {
      console.info('[SystemCheckService] 开始检查AGV连接');
      const response = await HttpUtil.get(AppConstants.API.SYSTEM_CHECK_AGV);
      console.info('[SystemCheckService] AGV检查响应:', JSON.stringify(response));
      return {
        success: response.code === 200,
        message: response.msg,
        errorCode: response.code
      };
    } catch (error) {
      console.error('[SystemCheckService] AGV检查异常:', error);
      return {
        success: false,
        message: 'AGV连接检查失败',
        errorCode: -1
      };
    }
  }

  /**
   * 检查摄像头连接
   */
  static async checkCamera(): Promise<CheckResult> {
    try {
      console.info('[SystemCheckService] 开始检查摄像头连接');
      const response = await HttpUtil.get(AppConstants.API.SYSTEM_CHECK_CAM);
      console.info('[SystemCheckService] 摄像头检查响应:', JSON.stringify(response));
      return {
        success: response.code === 200,
        message: response.msg,
        errorCode: response.code
      };
    } catch (error) {
      console.error('[SystemCheckService] 摄像头检查异常:', error);
      return {
        success: false,
        message: '摄像头连接检查失败',
        errorCode: -1
      };
    }
  }

  /**
   * 执行所有系统检查
   */
  static async checkAll(): Promise<SystemCheckAllResult> {
    const fsResult = await SystemCheckService.checkFileSystem();
    const dbResult = await SystemCheckService.checkDatabase();
    const agvResult = await SystemCheckService.checkAgv();
    const camResult = await SystemCheckService.checkCamera();

    const allPassed = fsResult.success && dbResult.success && agvResult.success && camResult.success;

    const result: SystemCheckAllResult = {
      fs: fsResult,
      db: dbResult,
      agv: agvResult,
      cam: camResult,
      allPassed: allPassed
    };
    
    return result;
  }
}