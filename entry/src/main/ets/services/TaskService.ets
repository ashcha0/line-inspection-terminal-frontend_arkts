import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 任务接口定义
export interface AgvTask {
  id: number;
  taskCode: string;
  taskName: string;
  startPos: string;
  taskTrip: string;
  creator: string;
  executor: string;
  execTime?: Date;
  endTime?: Date;
  createTime: Date;
  taskStatus: string;
  round: number;
  uploaded: boolean;
  remark?: string;
  cloudTaskId?: number;
  deleteFlag?: boolean;
}

// 分页参数接口
export interface PageParam {
  pageNum: number;
  pageSize: number;
  taskCode?: string;
  creator?: string;
  executor?: string;
  taskStatus?: string;
}

// 分页返回结果接口
export interface TableDataInfo<T> {
  total: number;
  rows: T[];
  code: number;
  msg: string;
}

// 上传信息接口
export interface AgvUploadInfoVO {
  info: string;
  type: string;
  status: string;
}

/**
 * 任务管理服务类
 * 提供任务的增删改查、启动、结束、上传等功能
 */
export class TaskService {
  
  /**
   * 获取任务列表
   * @param params 分页和筛选参数
   * @returns 任务列表数据
   */
  static async listTask(params: PageParam): Promise<TableDataInfo<AgvTask>> {
    try {
      console.info('[TaskService] 🔍 获取任务列表，参数:', JSON.stringify(params));
      
      let queryString = `pageNum=${params.pageNum}&pageSize=${params.pageSize}`;
      
      if (params.taskCode) queryString += `&taskCode=${encodeURIComponent(params.taskCode)}`;
      if (params.creator) queryString += `&creator=${encodeURIComponent(params.creator)}`;
      if (params.executor) queryString += `&executor=${encodeURIComponent(params.executor)}`;
      if (params.taskStatus) queryString += `&taskStatus=${encodeURIComponent(params.taskStatus)}`;
      
      const response = await HttpUtil.get(`/agv/task/list?${queryString}`);
      console.info('[TaskService] 📋 原始响应数据:', JSON.stringify(response));
      
      // 根据日志，API直接返回包含total和rows的对象，而不是嵌套在data中
      interface ResponseData {
        total?: number;
        rows?: AgvTask[];
        code?: number;
        msg?: string;
      }
      
      let responseData: ResponseData;
      // 检查数据是否在response.data中还是直接在response中
      if (response.data && typeof response.data === 'object' && (response.data as ResponseData).total !== undefined) {
        responseData = response.data as ResponseData;
      } else if ((response as ResponseData).total !== undefined) {
        responseData = response as ResponseData;
      } else {
        responseData = response.data as ResponseData;
      }
      
      console.info('[TaskService] ✅ 任务列表获取成功，数量:', responseData?.total || 0);
      console.info('[TaskService] 📋 解析后的任务数据:', responseData?.rows?.length || 0, '条');
      
      return {
        total: responseData?.total || 0,
        rows: responseData?.rows || [],
        code: responseData?.code || response.code || 200,
        msg: responseData?.msg || response.msg || '查询成功'
      } as TableDataInfo<AgvTask>;
    } catch (error) {
      console.error('[TaskService] ❌ 获取任务列表失败:', error);
      throw new Error('获取任务列表失败');
    }
  }
  
  /**
   * 获取任务详情
   * @param id 任务ID
   * @returns 任务详情
   */
  static async getTask(id: number): Promise<AgvTask> {
    try {
      console.info(`[TaskService] 🔍 获取任务详情，ID: ${id}`);
      const response = await HttpUtil.get(`/agv/task/${id}`);
      const taskData = response.data as AgvTask;
      console.info('[TaskService] ✅ 任务详情获取成功:', taskData?.taskName || '未知任务');
      return taskData;
    } catch (error) {
      console.error(`[TaskService] ❌ 获取任务详情失败，ID: ${id}`, error);
      throw new Error(`获取任务详情失败，ID: ${id}`);
    }
  }
  
  /**
   * 新建任务
   * @param task 任务数据
   * @returns 创建结果
   */
  static async addTask(task: Partial<AgvTask>): Promise<Object> {
    try {
      console.info('[TaskService] 📝 创建新任务:', task.taskName);
      const response = await HttpUtil.post('/agv/task', task);
      const responseData = response.data as AgvTask;
      console.info('[TaskService] ✅ 任务创建成功，ID:', responseData?.id);
      return response;
    } catch (error) {
      console.error('[TaskService] ❌ 创建任务失败:', error);
      throw new Error('创建任务失败');
    }
  }
  
  /**
   * 更新任务
   * @param task 任务数据
   * @returns 更新结果
   */
  static async updateTask(task: AgvTask): Promise<Object> {
    try {
      console.info(`[TaskService] 📝 更新任务，ID: ${task.id}`);
      const response = await HttpUtil.put('/agv/task', task);
      console.info('[TaskService] ✅ 任务更新成功');
      return response;
    } catch (error) {
      console.error(`[TaskService] ❌ 更新任务失败，ID: ${task.id}`, error);
      throw new Error(`更新任务失败，ID: ${task.id}`);
    }
  }
  
  /**
   * 删除任务
   * @param id 任务ID
   * @returns 删除结果
   */
  static async delTask(id: number): Promise<Object> {
    try {
      console.info(`[TaskService] 🗑️ 删除任务，ID: ${id}`);
      const response = await HttpUtil.delete(`/agv/task/${id}`);
      console.info('[TaskService] ✅ 任务删除成功');
      return response;
    } catch (error) {
      console.error(`[TaskService] ❌ 删除任务失败，ID: ${id}`, error);
      throw new Error(`删除任务失败，ID: ${id}`);
    }
  }
  
  /**
   * 启动任务
   * @param id 任务ID
   * @returns 启动结果
   */
  static async startTask(id: number): Promise<Object> {
    try {
      console.info(`[TaskService] 🚀 启动任务，ID: ${id}`);
      const response = await HttpUtil.post(`/agv/task/start/${id}`);
      console.info('[TaskService] ✅ 任务启动成功');
      return response;
    } catch (error) {
      console.error(`[TaskService] ❌ 启动任务失败，ID: ${id}`, error);
      throw new Error(`启动任务失败，ID: ${id}`);
    }
  }
  
  /**
   * 结束任务
   * @param id 任务ID
   * @param isAbort 是否中止（true: 中止, false: 完成）
   * @returns 结束结果
   */
  static async endTask(id: number, isAbort: boolean = false): Promise<Object> {
    try {
      console.info(`[TaskService] 🛑 结束任务，ID: ${id}, 中止: ${isAbort}`);
      const response = await HttpUtil.post(`/agv/task/end/${id}?isAbort=${isAbort}`);
      console.info('[TaskService] ✅ 任务结束成功');
      return response;
    } catch (error) {
      console.error(`[TaskService] ❌ 结束任务失败，ID: ${id}`, error);
      throw new Error(`结束任务失败，ID: ${id}`);
    }
  }
  
  /**
   * 查询待上传的数据
   * @param id 任务ID
   * @returns 待上传数据信息
   */
  static async preUploadTask(id: number): Promise<AgvUploadInfoVO[]> {
    try {
      console.info(`[TaskService] 📋 查询待上传数据，ID: ${id}`);
      const response = await HttpUtil.get(`/agv/task/preupload/${id}`);
      const uploadData = response.data as AgvUploadInfoVO[];
      console.info('[TaskService] ✅ 待上传数据查询成功，数量:', uploadData?.length || 0);
      return uploadData || [];
    } catch (error) {
      console.error(`[TaskService] ❌ 查询待上传数据失败，ID: ${id}`, error);
      throw new Error(`查询待上传数据失败，ID: ${id}`);
    }
  }
  
  /**
   * 上传任务数据
   * @param id 任务ID
   * @returns 上传结果
   */
  static async uploadTask(id: number): Promise<Object> {
    try {
      console.info(`[TaskService] 📤 上传任务数据，ID: ${id}`);
      const response = await HttpUtil.post(`/agv/task/upload/${id}`);
      console.info('[TaskService] ✅ 任务数据上传成功');
      return response;
    } catch (error) {
      console.error(`[TaskService] ❌ 上传任务数据失败，ID: ${id}`, error);
      throw new Error(`上传任务数据失败，ID: ${id}`);
    }
  }
}

// 添加水印标识
console.info('🏷️ [TaskService] 智能巡线车手持终端 - 任务管理服务已加载');