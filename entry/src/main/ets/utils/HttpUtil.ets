import http from '@ohos.net.http';
import { AppConstants } from '../constants/AppConstants';

// HTTP响应接口
export interface HttpResponse<T = Object> {
  code: number;
  msg: string;
  data?: T;
}

// 请求配置接口
export interface RequestConfig {
  method?: http.RequestMethod;
  headers?: Record<string, string>;
  timeout?: number;
  data?: Object;
}

// HTTP工具类
export class HttpUtil {
  private static readonly BASE_URL = AppConstants.API_BASE_URL;
  private static readonly TIMEOUT = AppConstants.REQUEST_TIMEOUT;

  /**
   * 发送HTTP请求
   * @param url 请求URL
   * @param config 请求配置
   * @returns Promise<HttpResponse>
   */
  static async request<T = Object>(url: string, config: RequestConfig = {}): Promise<HttpResponse<T>> {
    const httpRequest = http.createHttp();
    
    try {
      const fullUrl = url.startsWith('http') ? url : `${HttpUtil.BASE_URL}${url}`;
      console.info(`[HttpUtil] 发起请求: ${fullUrl}`);
      
      const requestOptions: http.HttpRequestOptions = {
        method: config.method || http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: config.timeout || HttpUtil.TIMEOUT,
        readTimeout: config.timeout || HttpUtil.TIMEOUT,
        extraData: config.data ? JSON.stringify(config.data) : undefined
      };
      
      console.info(`[HttpUtil] 请求配置:`, JSON.stringify(requestOptions));
      
      // 合并自定义headers
      if (config.headers) {
        const mergedHeaders: Record<string, string> = {};
        // 复制默认headers
        if (requestOptions.header) {
          const defaultHeaderKeys = Object.keys(requestOptions.header);
          for (let i = 0; i < defaultHeaderKeys.length; i++) {
            const key = defaultHeaderKeys[i];
            mergedHeaders[key] = requestOptions.header[key];
          }
        }
        // 复制自定义headers
        const customHeaderKeys = Object.keys(config.headers);
        for (let i = 0; i < customHeaderKeys.length; i++) {
          const key = customHeaderKeys[i];
          mergedHeaders[key] = config.headers[key];
        }
        requestOptions.header = mergedHeaders;
      }

      const response = await httpRequest.request(fullUrl, requestOptions);
      console.info(`[HttpUtil] 响应状态码: ${response.responseCode}`);
      console.info(`[HttpUtil] 响应内容: ${response.result}`);
      
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as HttpResponse<T>;
        console.info(`[HttpUtil] 解析后的响应:`, JSON.stringify(result));
        return result;
      } else {
        console.warn(`[HttpUtil] HTTP错误: ${response.responseCode}`);
        return {
          code: response.responseCode,
          msg: `HTTP ${response.responseCode}`,
          data: undefined
        };
      }
    } catch (error) {
      console.error('[HttpUtil] HTTP请求失败:', error);
      return {
        code: -1,
        msg: '网络请求失败',
        data: undefined
      };
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * GET请求
   */
  static get<T = Object>(url: string, config: RequestConfig = {}): Promise<HttpResponse<T>> {
    const getConfig: RequestConfig = {
      method: http.RequestMethod.GET,
      headers: config.headers,
      timeout: config.timeout,
      data: config.data
    };
    return HttpUtil.request<T>(url, getConfig);
  }

  /**
   * POST请求
   */
  static post<T = Object>(url: string, data?: Object, config: RequestConfig = {}): Promise<HttpResponse<T>> {
    const postConfig: RequestConfig = {
      method: http.RequestMethod.POST,
      headers: config.headers,
      timeout: config.timeout,
      data: data
    };
    return HttpUtil.request<T>(url, postConfig);
  }

  /**
   * PUT请求
   */
  static put<T = Object>(url: string, data?: Object, config: RequestConfig = {}): Promise<HttpResponse<T>> {
    const putConfig: RequestConfig = {
      method: http.RequestMethod.PUT,
      headers: config.headers,
      timeout: config.timeout,
      data: data
    };
    return HttpUtil.request<T>(url, putConfig);
  }

  /**
   * DELETE请求
   */
  static delete<T = Object>(url: string, config: RequestConfig = {}): Promise<HttpResponse<T>> {
    const deleteConfig: RequestConfig = {
      method: http.RequestMethod.DELETE,
      headers: config.headers,
      timeout: config.timeout,
      data: config.data
    };
    return HttpUtil.request<T>(url, deleteConfig);
  }
}