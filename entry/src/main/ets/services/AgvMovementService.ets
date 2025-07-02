import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// AGV状态接口定义
export interface AgvStatusVO {
  sysTime: string;
  isRunning: boolean;
  currentPosition: number;
}

// AGV心跳状态接口
export interface HeartbeatResult {
  success: boolean;
  status: string;
  timestamp: string;
  message?: string;
}

/**
 * AGV移动控制服务类
 * 提供AGV的移动控制、状态查询等功能
 */
export class AgvMovementService {
  
  /**
   * 查询AGV心跳状态
   * @returns AGV心跳状态
   */
  static async heartbeat(): Promise<HeartbeatResult> {
    try {
      console.info('[AgvMovementService] 💓 查询AGV心跳状态');
      const response = await HttpUtil.get('/agv/movement/heartbeat');
      interface HeartbeatData {
        status?: string;
      }
      const heartbeatData = response.data as HeartbeatData;
      console.info('[AgvMovementService] ✅ AGV心跳状态获取成功:', heartbeatData?.status || '未知');
      
      return {
        success: response.code === 200,
        status: heartbeatData?.status || 'unknown',
        timestamp: new Date().toISOString(),
        message: response.msg
      };
    } catch (error) {
      console.error('[AgvMovementService] ❌ 查询AGV心跳状态失败:', error);
      return {
        success: false,
        status: 'offline',
        timestamp: new Date().toISOString(),
        message: '心跳检测失败'
      };
    }
  }
  
  /**
   * 控制AGV向前移动
   * @returns 控制结果
   */
  static async agvForward(): Promise<Object> {
    try {
      console.info('[AgvMovementService] ⬆️ 控制AGV向前移动');
      const response = await HttpUtil.post('/agv/movement/forward');
      console.info('[AgvMovementService] ✅ AGV向前移动指令发送成功');
      return response;
    } catch (error) {
      console.error('[AgvMovementService] ❌ AGV向前移动失败:', error);
      throw new Error('AGV向前移动失败');
    }
  }
  
  /**
   * 停止AGV
   * @returns 控制结果
   */
  static async agvStop(): Promise<Object> {
    try {
      console.info('[AgvMovementService] ⏹️ 停止AGV');
      const response = await HttpUtil.post('/agv/movement/stop');
      console.info('[AgvMovementService] ✅ AGV停止指令发送成功');
      return response;
    } catch (error) {
      console.error('[AgvMovementService] ❌ 停止AGV失败:', error);
      throw new Error('停止AGV失败');
    }
  }
  
  /**
   * 控制AGV向后移动
   * @returns 控制结果
   */
  static async agvBackward(): Promise<Object> {
    try {
      console.info('[AgvMovementService] ⬇️ 控制AGV向后移动');
      const response = await HttpUtil.post('/agv/movement/backward');
      console.info('[AgvMovementService] ✅ AGV向后移动指令发送成功');
      return response;
    } catch (error) {
      console.error('[AgvMovementService] ❌ AGV向后移动失败:', error);
      throw new Error('AGV向后移动失败');
    }
  }
  
  /**
   * 获取AGV当前状态（模拟数据）
   * 注：由于接口文档中没有直接的状态获取接口，这里提供模拟数据
   * @returns AGV状态信息
   */
  static async getAgvStatus(): Promise<AgvStatusVO> {
    try {
      console.info('[AgvMovementService] 📊 获取AGV当前状态');
      
      // 先检查心跳状态
      const heartbeatResult = await AgvMovementService.heartbeat();
      
      // 模拟AGV状态数据
      const mockStatus: AgvStatusVO = {
        sysTime: new Date().toLocaleString('zh-CN'),
        isRunning: heartbeatResult.success && heartbeatResult.status === 'running',
        currentPosition: Math.floor(Math.random() * 1000) + 100 // 模拟当前位置
      };
      
      console.info('[AgvMovementService] ✅ AGV状态获取成功:', JSON.stringify(mockStatus));
      return mockStatus;
    } catch (error) {
      console.error('[AgvMovementService] ❌ 获取AGV状态失败:', error);
      // 返回默认状态
      return {
        sysTime: new Date().toLocaleString('zh-CN'),
        isRunning: false,
        currentPosition: 0
      };
    }
  }
  
  /**
   * 紧急停止AGV
   * @returns 控制结果
   */
  static async emergencyStop(): Promise<Object> {
    try {
      console.warn('[AgvMovementService] 🚨 紧急停止AGV');
      const response = await AgvMovementService.agvStop();
      console.info('[AgvMovementService] ✅ 紧急停止指令发送成功');
      return response;
    } catch (error) {
      console.error('[AgvMovementService] ❌ 紧急停止AGV失败:', error);
      throw new Error('紧急停止AGV失败');
    }
  }
  
  /**
   * 检查AGV是否在线
   * @returns 在线状态
   */
  static async isOnline(): Promise<boolean> {
    try {
      const heartbeatResult = await AgvMovementService.heartbeat();
      return heartbeatResult.success;
    } catch (error) {
      console.error('[AgvMovementService] ❌ 检查AGV在线状态失败:', error);
      return false;
    }
  }
}

// 添加水印标识
console.info('🏷️ [AgvMovementService] 智能巡线车手持终端 - AGV移动控制服务已加载');