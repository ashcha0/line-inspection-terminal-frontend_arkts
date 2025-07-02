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
  status?: string; // 故障状态：pending, confirmed等
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

// 通用响应接口
export interface ApiResponse<T = object> {
  code: number;
  msg: string;
  data?: T;
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
      
      let queryString = `pageNum=${params.pageNum}&pageSize=${params.pageSize}`;
      
      if (params.taskId) queryString += `&taskId=${params.taskId}`;
      if (params.flawType) queryString += `&flawType=${encodeURIComponent(params.flawType)}`;
      if (params.confirmed !== undefined) queryString += `&confirmed=${params.confirmed}`;
      
      const response = await HttpUtil.get(`/agv/flaw/list?${queryString}`);
      const responseData = response.data as TableDataInfo<AgvFlaw>;
      console.info('[FlawService] ✅ 故障列表获取成功，数量:', responseData?.total || 0);
      
      const result: TableDataInfo<AgvFlaw> = {
        total: responseData?.total || 0,
        rows: responseData?.rows || [],
        code: response.code,
        msg: response.msg
      };
      return result;
    } catch (error) {
      console.error('[FlawService] ❌ 获取故障列表失败:', error);
      throw new Error('获取故障列表失败');
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
      const flawData = response.data as AgvFlaw;
      console.info('[FlawService] ✅ 故障详情获取成功:', flawData?.flawName || '未知故障');
      return response.data as AgvFlaw;
    } catch (error) {
      console.error(`[FlawService] ❌ 获取故障详情失败，ID: ${id}`, error);
      throw new Error(`获取故障详情失败，ID: ${id}`);
    }
  }
  
  /**
   * 新增故障
   * @param flaw 故障数据
   * @returns 创建结果
   */
  static async addFlaw(flaw: Partial<AgvFlaw>): Promise<ApiResponse<AgvFlaw>> {
    try {
      console.info('[FlawService] 📝 创建新故障:', flaw.flawName);
      const response = await HttpUtil.post('/agv/flaw', flaw);
      const createdFlaw = response.data as AgvFlaw;
      console.info('[FlawService] ✅ 故障创建成功，ID:', createdFlaw?.id);
      const result: ApiResponse<AgvFlaw> = {
        code: response.code,
        msg: response.msg,
        data: createdFlaw
      };
      return result;
    } catch (error) {
      console.error('[FlawService] ❌ 创建故障失败:', error);
      throw new Error('创建故障失败');
    }
  }
  
  /**
   * 更新故障
   * @param flaw 故障数据
   * @returns 更新结果
   */
  static async updateFlaw(flaw: Partial<AgvFlaw>): Promise<ApiResponse<object>> {
    try {
      console.info(`[FlawService] 📝 更新故障，ID: ${flaw.id}`);
      const response = await HttpUtil.put('/agv/flaw', flaw);
      console.info('[FlawService] ✅ 故障更新成功');
      const result: ApiResponse<object> = {
        code: response.code,
        msg: response.msg,
        data: response.data
      };
      return result;
    } catch (error) {
      console.error(`[FlawService] ❌ 更新故障失败，ID: ${flaw.id}`, error);
      throw new Error(`更新故障失败，ID: ${flaw.id}`);
    }
  }
  
  /**
   * 删除故障
   * @param id 故障ID
   * @returns 删除结果
   */
  static async delFlaw(id: number): Promise<ApiResponse<object>> {
    try {
      console.info(`[FlawService] 🗑️ 删除故障，ID: ${id}`);
      const response = await HttpUtil.delete(`/agv/flaw/${id}`);
      console.info('[FlawService] ✅ 故障删除成功');
      const result: ApiResponse<object> = {
        code: response.code,
        msg: response.msg,
        data: response.data
      };
      return result;
    } catch (error) {
      console.error(`[FlawService] ❌ 删除故障失败，ID: ${id}`, error);
      throw new Error(`删除故障失败，ID: ${id}`);
    }
  }
  
  /**
   * 轮询获取任务实时故障信息
   * @param taskId 任务ID
   * @returns 实时故障信息
   */
  static async liveInfo(taskId: number): Promise<AgvFlaw[]> {
    try {
      const requestUrl = `/agv/flaw/live/${taskId}`;
      console.info(`[FlawService] 🔄 轮询获取实时故障信息`);
      console.info(`[FlawService] 📊 请求参数: taskId=${taskId}`);
      console.info(`[FlawService] 📊 请求URL: ${requestUrl}`);
      
      const response = await HttpUtil.get(requestUrl);
      
      console.info(`[FlawService] 📊 响应状态码: ${response.code}`);
      console.info(`[FlawService] 📊 响应消息: ${response.msg}`);
      console.info(`[FlawService] 📊 响应数据类型: ${typeof response.data}`);
      console.info(`[FlawService] 📊 响应数据内容: ${JSON.stringify(response.data)}`);
      
      if (response.code !== 200) {
        console.warn(`[FlawService] ⚠️ 服务器返回非200状态码: ${response.code}, 消息: ${response.msg}`);
        return [];
      }
      
      const responseData = response.data as AgvFlaw[];
      
      if (!Array.isArray(responseData)) {
        console.warn(`[FlawService] ⚠️ 响应数据不是数组类型: ${typeof responseData}`);
        return [];
      }
      
      console.info(`[FlawService] ✅ 实时故障信息获取成功，数量: ${responseData.length}`);
      
      if (responseData.length > 0) {
         console.info(`[FlawService] 📊 故障详情:`);
         responseData.forEach((flaw, index) => {
           const status = flaw.confirmed ? 'confirmed' : 'pending';
           console.info(`[FlawService] 📊 故障${index + 1}: ID=${flaw.id}, 名称=${flaw.flawName}, 类型=${flaw.flawType}, 状态=${status}`);
         });
       } else {
         console.info(`[FlawService] 📊 当前任务无故障数据`);
       }
      
      return responseData;
    } catch (error) {
      console.error(`[FlawService] ❌ 获取实时故障信息失败，任务ID: ${taskId}`);
      console.error(`[FlawService] 📊 错误类型: ${typeof error}`);
      console.error(`[FlawService] 📊 错误内容: ${JSON.stringify(error)}`);
      console.error(`[FlawService] 📊 错误堆栈: ${error instanceof Error ? error.stack : '无堆栈信息'}`);
      
      // 返回空数组而不是抛出异常，避免中断轮询
      return [];
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
      throw new Error(`检查任务缺陷确认状态失败，任务ID: ${taskId}`);
    }
  }
  
  /**
   * 确认故障
   * @param id 故障ID
   * @param confirmed 是否确认 (可选，默认为true)
   * @param remark 备注信息
   * @returns 确认结果
   */
  static async confirmFlaw(id: number, confirmed: boolean = true, remark?: string): Promise<ApiResponse<object>> {
    try {
      console.info(`[FlawService] ✅ 确认故障，ID: ${id}, 确认: ${confirmed}`);
      const data: Partial<AgvFlaw> = {
        id: id,
        confirmed: confirmed,
        remark: remark
      };
      const response = await HttpUtil.put('/agv/flaw', data);
      console.info('[FlawService] ✅ 故障确认状态更新成功');
      const result: ApiResponse<object> = {
        code: response.code,
        msg: response.msg,
        data: response.data
      };
      return result;
    } catch (error) {
      console.error(`[FlawService] ❌ 更新故障确认状态失败，ID: ${id}`, error);
      throw new Error(`更新故障确认状态失败，ID: ${id}`);
    }
  }
}

// 添加水印标识
console.info('🏷️ [FlawService] 智能巡线车手持终端 - 故障管理服务已加载');