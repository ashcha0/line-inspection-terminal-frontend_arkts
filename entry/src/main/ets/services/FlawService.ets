import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 故障缺陷接口定义
export interface AgvFlaw {
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
  createTime: Date;
  remark?: string;
  flawLength?: number;
  flawArea?: number;
  level?: string;
  countNum?: number;
  deleteFlag?: boolean;
}

// 分页参数接口
export interface FlawPageParam {
  pageNum: number;
  pageSize: number;
  taskId?: number;
  flawType?: string;
  confirmed?: boolean;
}

// 分页返回结果接口
export interface TableDataInfo<T> {
  total: number;
  rows: T[];
  code: number;
  msg: string;
}

/**
 * 故障管理服务类
 * 提供故障的增删改查、确认等功能
 */
export class FlawService {
  
  /**
   * 获取故障列表
   * @param params 分页和筛选参数
   * @returns 故障列表数据
   */
  static async listFlaw(params: FlawPageParam): Promise<TableDataInfo<AgvFlaw>> {
    try {
      console.info('[FlawService] 🔍 获取故障列表，参数:', JSON.stringify(params));
      
      const queryParams = new URLSearchParams();
      queryParams.append('pageNum', params.pageNum.toString());
      queryParams.append('pageSize', params.pageSize.toString());
      
      if (params.taskId) queryParams.append('taskId', params.taskId.toString());
      if (params.flawType) queryParams.append('flawType', params.flawType);
      if (params.confirmed !== undefined) queryParams.append('confirmed', params.confirmed.toString());
      
      const response = await HttpUtil.get(`/agv/flaw/list?${queryParams.toString()}`);
      console.info('[FlawService] ✅ 故障列表获取成功，数量:', response.data?.total || 0);
      
      return {
        total: response.data?.total || 0,
        rows: response.data?.rows || [],
        code: response.code,
        msg: response.msg
      };
    } catch (error) {
      console.error('[FlawService] ❌ 获取故障列表失败:', error);
      throw error;
    }
  }
  
  /**
   * 获取故障详情
   * @param id 故障ID
   * @returns 故障详情
   */
  static async getFlaw(id: number): Promise<AgvFlaw> {
    try {
      console.info(`[FlawService] 🔍 获取故障详情，ID: ${id}`);
      const response = await HttpUtil.get(`/agv/flaw/${id}`);
      console.info('[FlawService] ✅ 故障详情获取成功:', response.data?.flawName || '未知故障');
      return response.data as AgvFlaw;
    } catch (error) {
      console.error(`[FlawService] ❌ 获取故障详情失败，ID: ${id}`, error);
      throw error;
    }
  }
  
  /**
   * 新增故障
   * @param flaw 故障数据
   * @returns 创建结果
   */
  static async addFlaw(flaw: Partial<AgvFlaw>): Promise<any> {
    try {
      console.info('[FlawService] 📝 创建新故障:', flaw.flawName);
      const response = await HttpUtil.post('/agv/flaw', flaw);
      console.info('[FlawService] ✅ 故障创建成功，ID:', response.data?.id);
      return response;
    } catch (error) {
      console.error('[FlawService] ❌ 创建故障失败:', error);
      throw error;
    }
  }
  
  /**
   * 更新故障
   * @param flaw 故障数据
   * @returns 更新结果
   */
  static async updateFlaw(flaw: Partial<AgvFlaw>): Promise<any> {
    try {
      console.info(`[FlawService] 📝 更新故障，ID: ${flaw.id}`);
      const response = await HttpUtil.put('/agv/flaw', flaw);
      console.info('[FlawService] ✅ 故障更新成功');
      return response;
    } catch (error) {
      console.error(`[FlawService] ❌ 更新故障失败，ID: ${flaw.id}`, error);
      throw error;
    }
  }
  
  /**
   * 删除故障
   * @param id 故障ID
   * @returns 删除结果
   */
  static async delFlaw(id: number): Promise<any> {
    try {
      console.info(`[FlawService] 🗑️ 删除故障，ID: ${id}`);
      const response = await HttpUtil.delete(`/agv/flaw/${id}`);
      console.info('[FlawService] ✅ 故障删除成功');
      return response;
    } catch (error) {
      console.error(`[FlawService] ❌ 删除故障失败，ID: ${id}`, error);
      throw error;
    }
  }
  
  /**
   * 轮询获取任务实时故障信息
   * @param taskId 任务ID
   * @returns 实时故障信息
   */
  static async liveInfo(taskId: number): Promise<AgvFlaw[]> {
    try {
      console.info(`[FlawService] 🔄 轮询获取实时故障信息，任务ID: ${taskId}`);
      const response = await HttpUtil.get(`/agv/flaw/live/${taskId}`);
      console.info('[FlawService] ✅ 实时故障信息获取成功，数量:', response.data?.length || 0);
      return response.data || [];
    } catch (error) {
      console.error(`[FlawService] ❌ 获取实时故障信息失败，任务ID: ${taskId}`, error);
      throw error;
    }
  }
  
  /**
   * 检查任务缺陷是否已全部确认
   * @param taskId 任务ID
   * @returns 检查结果
   */
  static async checkAllConfirmed(taskId: number): Promise<boolean> {
    try {
      console.info(`[FlawService] 🔍 检查任务缺陷是否已全部确认，任务ID: ${taskId}`);
      const response = await HttpUtil.get(`/agv/flaw/check/${taskId}`);
      console.info('[FlawService] ✅ 检查完成，全部确认:', response.data);
      return response.data === true;
    } catch (error) {
      console.error(`[FlawService] ❌ 检查任务缺陷确认状态失败，任务ID: ${taskId}`, error);
      throw error;
    }
  }
  
  /**
   * 确认故障
   * @param id 故障ID
   * @param confirmed 是否确认
   * @param remark 备注信息
   * @returns 确认结果
   */
  static async confirmFlaw(id: number, confirmed: boolean, remark?: string): Promise<any> {
    try {
      console.info(`[FlawService] ✅ 确认故障，ID: ${id}, 确认: ${confirmed}`);
      const data = {
        id: id,
        confirmed: confirmed,
        remark: remark
      };
      const response = await HttpUtil.put('/agv/flaw', data);
      console.info('[FlawService] ✅ 故障确认状态更新成功');
      return response;
    } catch (error) {
      console.error(`[FlawService] ❌ 更新故障确认状态失败，ID: ${id}`, error);
      throw error;
    }
  }
}

// 添加水印标识
console.info('🏷️ [FlawService] 智能巡线车手持终端 - 故障管理服务已加载');