import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TaskService, AgvTask, PageParam } from '../services/TaskService';
import { AppConstants } from '../constants/AppConstants';

// 使用TaskService中定义的接口
interface SearchParams {
  taskCode?: string;
  creator?: string;
  executor?: string;
  taskStatus?: string;
}

@Entry
@Component
struct TaskView {
  @State tasks: AgvTask[] = [];
  @State loading: boolean = true;
  @State showAddTask: boolean = false;
  @State searchParams: SearchParams = {};
  @State newTask: Partial<AgvTask> = {};
  
  // 搜索表单状态
  @State searchTaskCode: string = '';
  @State searchCreator: string = '';
  @State searchExecutor: string = '';
  @State searchTaskStatus: string = '';
  @State selectedStatusIndex: number = 0; // 状态选择器的选中索引
  
  // 新增/编辑任务表单状态
  @State taskName: string = '';
  @State taskCode: string = '';
  @State startPos: string = '';
  @State taskTrip: string = '';
  @State creator: string = '';
  @State executor: string = '';
  @State remark: string = '';
  
  // 编辑任务相关状态
  @State isEditMode: boolean = false;
  @State editingTaskId: number = 0;
  
  // 上传任务相关状态
  @State uploadingTasks: Set<number> = new Set();
  @State showUploadProgress: boolean = false;
  @State uploadProgress: number = 0;
  @State currentUploadTaskId: number = 0;

  aboutToAppear() {
    this.loadTasks();
  }

  async loadTasks(): Promise<void> {
    try {
      this.loading = true;
      const params: PageParam = {
        pageNum: 1,
        pageSize: 100,
        taskCode: this.searchParams.taskCode,
        creator: this.searchParams.creator,
        executor: this.searchParams.executor,
        taskStatus: this.searchParams.taskStatus
      };
      
      console.info('[TaskView] 🔍 开始加载任务列表，参数:', JSON.stringify(params));
      const response = await TaskService.listTask(params);
      console.info('[TaskView] 📋 任务列表响应:', JSON.stringify(response));
      
      if (response.code === 200) {
        this.tasks = response.rows || [];
        console.info('[TaskView] ✅ 任务列表加载成功，数量:', this.tasks.length);
      } else {
        console.error('[TaskView] ❌ 任务列表加载失败，错误码:', response.code, '错误信息:', response.msg);
        promptAction.showToast({
          message: response.msg || '加载任务列表失败',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('[TaskView] ❌ 加载任务列表异常:', error);
      promptAction.showToast({
        message: '加载任务列表失败',
        duration: 2000
      });
    } finally {
      this.loading = false;
    }
  }

  searchTasks() {
    this.searchParams = {
      taskCode: this.searchTaskCode || undefined,
      creator: this.searchCreator || undefined,
      executor: this.searchExecutor || undefined,
      taskStatus: this.searchTaskStatus || undefined
    };
    this.loadTasks();
  }

  resetSearch() {
    console.info('[TaskView] 🔄 重置搜索条件');
    this.searchTaskCode = '';
    this.searchCreator = '';
    this.searchExecutor = '';
    this.searchTaskStatus = '';
    this.selectedStatusIndex = 0; // 重置状态选择器到"全部"
    this.searchParams = {};
    this.loadTasks();
  }

  openAddTask() {
    this.isEditMode = false;
    this.editingTaskId = 0;
    this.clearTaskForm();
    this.showAddTask = true;
  }

  openEditTask(task: AgvTask) {
    console.info('[TaskView] ✏️ 打开编辑任务，任务ID:', task.id);
    console.info('[TaskView] 📋 任务详细数据:', JSON.stringify(task));
    
    this.isEditMode = true;
    this.editingTaskId = task.id;
    
    // 填充表单数据
    this.taskName = task.taskName || '';
    this.taskCode = task.taskCode || '';
    this.startPos = task.startPos || '';
    this.taskTrip = task.taskTrip || '';
    this.creator = task.creator || '';
    this.executor = task.executor || '';
    this.remark = task.remark || '';
    
    console.info('[TaskView] 📝 表单数据填充完成:');
    console.info('[TaskView] - 任务名称:', this.taskName);
    console.info('[TaskView] - 任务编号:', this.taskCode);
    console.info('[TaskView] - 起始位置:', this.startPos);
    console.info('[TaskView] - 巡视路线:', this.taskTrip);
    console.info('[TaskView] - 创建人:', this.creator);
    console.info('[TaskView] - 执行人:', this.executor);
    console.info('[TaskView] - 备注:', this.remark);
    
    this.showAddTask = true;
    console.info('[TaskView] ✅ 编辑模态框已打开');
  }

  closeAddTask() {
    this.showAddTask = false;
    this.isEditMode = false;
    this.editingTaskId = 0;
    this.clearTaskForm();
  }

  clearTaskForm() {
    this.taskName = '';
    this.taskCode = '';
    this.startPos = '';
    this.taskTrip = '';
    this.creator = '';
    this.executor = '';
    this.remark = '';
  }

  async addTask() {
    if (this.isEditMode) {
      await this.updateTask();
    } else {
      await this.createTask();
    }
  }

  async createTask() {
    // 表单验证
    if (!this.taskName || !this.startPos || !this.taskTrip || !this.creator || !this.executor) {
      promptAction.showToast({
        message: '请填写所有必填字段',
        duration: 2000
      });
      return;
    }

    try {
      // 自动生成任务编号：TASK-年月日时分秒
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hour = String(now.getHours()).padStart(2, '0');
      const minute = String(now.getMinutes()).padStart(2, '0');
      const second = String(now.getSeconds()).padStart(2, '0');
      const autoTaskCode = `TASK-${year}${month}${day}${hour}${minute}${second}`;
      
      const taskData: Partial<AgvTask> = {
        taskName: this.taskName,
        taskCode: this.taskCode || autoTaskCode,
        startPos: this.startPos,
        taskTrip: this.taskTrip,
        creator: this.creator,
        executor: this.executor,
        remark: this.remark || undefined
      };
      
      console.info('[TaskView] 🔢 自动生成任务编号:', autoTaskCode);

      console.info('[TaskView] 📝 开始创建任务:', JSON.stringify(taskData));
      const response = await TaskService.addTask(taskData);
      
      console.info('[TaskView] 📋 任务创建响应:', JSON.stringify(response));
      
      // 检查响应状态
       interface ResponseWithCode {
         code: number;
         msg?: string;
         data?: Object;
       }
      
      const responseData = response as ResponseWithCode;
      
      if (responseData.code === 200) {
        console.info('[TaskView] ✅ 任务创建成功，准备更新UI');
        
        // 直接在当前上下文中执行UI操作
        try {
          console.info('[TaskView] 🔄 开始执行UI更新操作');
          
          // 先关闭模态框
          this.closeAddTask();
          console.info('[TaskView] 🔄 模态框已关闭');
          
          // 刷新任务列表
          this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成');
          
          // 显示成功提示
          promptAction.showToast({
            message: '任务创建成功',
            duration: 2000
          });
          
          console.info('[TaskView] ✅ UI更新完成');
        } catch (uiError) {
          console.error('[TaskView] ❌ UI更新失败:', uiError);
          // 如果UI更新失败，至少尝试关闭弹窗
          try {
            this.closeAddTask();
          } catch (closeError) {
            console.error('[TaskView] ❌ 关闭弹窗失败:', closeError);
          }
        }
      } else {
        console.error('[TaskView] ❌ 任务创建失败，错误码:', responseData.code, '错误信息:', responseData.msg);
        promptAction.showToast({
          message: responseData.msg || '创建任务失败',
          duration: 2000
        });
      }
      
    } catch (error) {
      console.error('[TaskView] ❌ 创建任务异常:', error);
      promptAction.showToast({
        message: '创建任务失败，请重试',
        duration: 2000
      });
    }
  }

  async updateTask() {
    // 表单验证
    if (!this.taskName || !this.startPos || !this.taskTrip || !this.creator || !this.executor) {
      promptAction.showToast({
        message: '请填写所有必填字段',
        duration: 2000
      });
      return;
    }

    try {
      // 先获取原有任务数据，保留完整的数据结构
      const originalTask = await TaskService.getTask(this.editingTaskId);
      console.info('[TaskView] 📋 获取原有任务数据:', JSON.stringify(originalTask));
      
      // 只更新用户修改的字段，保留其他原有数据
      const taskData: AgvTask = {
        id: originalTask.id,
        taskName: this.taskName,
        taskCode: this.taskCode,
        startPos: this.startPos,
        taskTrip: this.taskTrip,
        creator: this.creator,
        executor: this.executor,
        remark: this.remark || '',
        taskStatus: originalTask.taskStatus,
        round: originalTask.round,
        uploaded: originalTask.uploaded,
        execTime: originalTask.execTime,
        endTime: originalTask.endTime,
        createTime: originalTask.createTime,
        cloudTaskId: originalTask.cloudTaskId
      };
      
      console.info('[TaskView] ✏️ 开始更新任务:', JSON.stringify(taskData));
      const response = await TaskService.updateTask(taskData);
      
      console.info('[TaskView] 📋 任务更新响应:', JSON.stringify(response));
      
      // 检查响应状态
       interface ResponseWithCode {
         code: number;
         msg?: string;
         data?: Object;
       }
      
      const responseData = response as ResponseWithCode;
      
      if (responseData.code === 200) {
        console.info('[TaskView] ✅ 任务更新成功，准备更新UI');
        
        // 直接在当前上下文中执行UI操作
        try {
          console.info('[TaskView] 🔄 开始执行UI更新操作');
          
          // 先关闭模态框
          this.closeAddTask();
          console.info('[TaskView] 🔄 模态框已关闭');
          
          // 刷新任务列表
          this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成');
          
          // 显示成功提示
          promptAction.showToast({
            message: '任务更新成功',
            duration: 2000
          });
          
          console.info('[TaskView] ✅ UI更新完成');
        } catch (uiError) {
          console.error('[TaskView] ❌ UI更新失败:', uiError);
          // 如果UI更新失败，至少尝试关闭弹窗
          try {
            this.closeAddTask();
          } catch (closeError) {
            console.error('[TaskView] ❌ 关闭弹窗失败:', closeError);
          }
        }
      } else {
        console.error('[TaskView] ❌ 任务更新失败，错误码:', responseData.code, '错误信息:', responseData.msg);
        promptAction.showToast({
          message: responseData.msg || '更新任务失败',
          duration: 2000
        });
      }
      
    } catch (error) {
      console.error('[TaskView] ❌ 更新任务异常:', error);
      promptAction.showToast({
        message: '更新任务失败，请重试',
        duration: 2000
      });
    }
  }

  deleteTask(taskId: number) {
    console.info('[TaskView] 🗑️ 开始删除任务，ID:', taskId);
    console.info('[TaskView] 🔍 当前UI上下文状态检查 - 开始删除前');
    
    // 先显示加载状态
    this.loading = true;
    console.info('[TaskView] ⏳ 设置加载状态为true');
    
    // 使用Promise链式调用，避免async/await导致的上下文丢失
    TaskService.delTask(taskId)
      .then((response) => {
        console.info('[TaskView] 📋 删除任务响应:', JSON.stringify(response));
        console.info('[TaskView] 🔍 Promise then回调中的UI上下文检查');
        
        interface ResponseWithCode {
          code: number;
          msg?: string;
        }
        const responseWithCode = response as ResponseWithCode;
        
        if (responseWithCode.code === 200) {
          console.info('[TaskView] ✅ 任务删除成功，开始UI更新');
          console.info('[TaskView] 🔍 准备更新UI状态 - loading设为false前');
          
          // 在主线程中直接更新UI状态
          try {
            this.loading = false;
            console.info('[TaskView] ✅ 成功设置loading状态为false');
          } catch (error) {
            console.error('[TaskView] ❌ 设置loading状态失败:', error);
          }
          
          // 显示成功提示
          try {
            promptAction.showToast({
              message: '任务删除成功',
              duration: 2000
            });
            console.info('[TaskView] ✅ 成功显示删除成功提示');
          } catch (error) {
            console.error('[TaskView] ❌ 显示提示失败:', error);
          }
          
          // 延迟刷新任务列表，确保在正确的UI上下文中执行
          console.info('[TaskView] ⏰ 准备延迟刷新任务列表');
          setTimeout(() => {
            console.info('[TaskView] 🔄 开始执行延迟刷新任务列表');
            console.info('[TaskView] 🔍 setTimeout回调中的UI上下文检查');
            try {
              console.info('[TaskView] 📝 调用loadTasks前的状态检查');
              this.loadTasks();
              console.info('[TaskView] 🔄 任务列表刷新完成');
            } catch (error) {
              console.error('[TaskView] ❌ 刷新任务列表失败:', error);
              console.error('[TaskView] 🔍 错误详情:', JSON.stringify(error));
              // 备用方案：重置搜索参数并重新加载
               try {
                 console.info('[TaskView] 🔄 尝试备用刷新方案');
                 // 重置搜索参数
                 this.searchParams = {};
                 this.loadTasks();
               } catch (backupError) {
                 console.error('[TaskView] ❌ 备用刷新方案也失败:', backupError);
               }
            }
          }, 200); // 增加延迟时间到200ms
          
        } else {
          console.error('[TaskView] ❌ 任务删除失败，错误码:', responseWithCode.code);
          this.loading = false;
          
          promptAction.showToast({
            message: responseWithCode.msg || '删除任务失败',
            duration: 2000
          });
        }
      })
      .catch((error: Error) => {
        console.error('[TaskView] ❌ 删除任务异常:', error);
        console.error('[TaskView] 🔍 catch回调中的错误详情:', JSON.stringify(error));
        this.loading = false;
        
        promptAction.showToast({
          message: '删除任务失败，请重试',
          duration: 2000
        });
      });
  }

  async startTask(taskId: number) {
    try {
      console.info('[TaskView] 🚀 开始启动任务，ID:', taskId);
      const response = await TaskService.startTask(taskId);
      
      interface ResponseWithCode {
        code: number;
        msg?: string;
      }
      const responseWithCode = response as ResponseWithCode;
      if (responseWithCode.code === 200) {
        console.info('[TaskView] ✅ 任务启动成功，准备刷新列表');
        
        // 先刷新任务列表以获取最新状态
        try {
          await this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成');
        } catch (refreshError) {
          console.error('[TaskView] ❌ 刷新任务列表失败:', refreshError);
        }
        
        // 使用try-catch包装UI操作，避免UI上下文错误
        try {
          promptAction.showToast({
            message: '任务启动成功',
            duration: 2000
          });
          
          // 跳转到任务执行页面
          router.pushUrl({
            url: 'pages/TaskExecuteView',
            params: {
              taskId: taskId
            }
          });
        } catch (uiError) {
          console.error('[TaskView] ❌ UI操作失败:', uiError);
        }
      } else {
        console.error('[TaskView] ❌ 任务启动失败，错误码:', responseWithCode.code, '错误信息:', responseWithCode.msg);
        
        // 任务启动失败时，也需要刷新任务列表以确保状态同步
        try {
          await this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成（启动失败后）');
        } catch (refreshError) {
          console.error('[TaskView] ❌ 刷新任务列表失败（启动失败后）:', refreshError);
        }
        
        // 任务启动失败时，避免执行可能导致UI上下文错误的操作
        try {
          promptAction.showToast({
            message: responseWithCode.msg || '启动任务失败',
            duration: 2000
          });
        } catch (uiError) {
          console.error('[TaskView] ❌ 显示错误提示失败:', uiError);
        }
      }
    } catch (error) {
      console.error('[TaskView] ❌ 启动任务异常:', error);
      
      // 异常情况下，也需要刷新任务列表以确保状态同步
      try {
        await this.loadTasks();
        console.info('[TaskView] 🔄 任务列表刷新完成（异常后）');
      } catch (refreshError) {
        console.error('[TaskView] ❌ 刷新任务列表失败（异常后）:', refreshError);
      }
      
      // 异常情况下，避免执行可能导致UI上下文错误的操作
      try {
        promptAction.showToast({
          message: '启动任务失败，请重试',
          duration: 2000
        });
      } catch (uiError) {
        console.error('[TaskView] ❌ 显示异常提示失败:', uiError);
      }
    }
  }

  goToTaskExecute(taskId: number) {
    try {
      console.info('[TaskView] 🚀 跳转到任务执行页面，任务ID:', taskId);
      router.pushUrl({
        url: 'pages/TaskExecuteView',
        params: {
          taskId: taskId
        }
      });
    } catch (error) {
      console.error('[TaskView] ❌ 跳转到任务执行页面失败:', error);
      promptAction.showToast({
        message: '跳转失败，请重试',
        duration: 2000
      });
    }
  }

  async endTask(taskId: number) {
    try {
      console.info('[TaskView] 🛑 开始结束任务，ID:', taskId);
      const response = await TaskService.endTask(taskId, false); // false表示正常完成，不是中止
      
      interface ResponseWithCode {
        code: number;
        msg?: string;
      }
      const responseWithCode = response as ResponseWithCode;
      if (responseWithCode.code === 200) {
        console.info('[TaskView] ✅ 任务结束成功，准备刷新列表');
        
        // 刷新任务列表以获取最新状态
        try {
          await this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成');
        } catch (refreshError) {
          console.error('[TaskView] ❌ 刷新任务列表失败:', refreshError);
        }
        
        // 使用try-catch包装UI操作，避免UI上下文错误
        try {
          promptAction.showToast({
            message: '任务结束成功',
            duration: 2000
          });
        } catch (uiError) {
          console.error('[TaskView] ❌ UI操作失败:', uiError);
        }
      } else {
        console.error('[TaskView] ❌ 任务结束失败，错误码:', responseWithCode.code, '错误信息:', responseWithCode.msg);
        
        // 任务结束失败时，也需要刷新任务列表以确保状态同步
        try {
          await this.loadTasks();
          console.info('[TaskView] 🔄 任务列表刷新完成（结束失败后）');
        } catch (refreshError) {
          console.error('[TaskView] ❌ 刷新任务列表失败（结束失败后）:', refreshError);
        }
        
        // 显示错误提示
        try {
          promptAction.showToast({
            message: responseWithCode.msg || '结束任务失败',
            duration: 2000
          });
        } catch (uiError) {
          console.error('[TaskView] ❌ 显示错误提示失败:', uiError);
        }
      }
    } catch (error) {
      console.error('[TaskView] ❌ 结束任务异常:', error);
      
      // 异常情况下，也需要刷新任务列表以确保状态同步
      try {
        await this.loadTasks();
        console.info('[TaskView] 🔄 任务列表刷新完成（异常后）');
      } catch (refreshError) {
        console.error('[TaskView] ❌ 刷新任务列表失败（异常后）:', refreshError);
      }
      
      // 异常情况下，避免执行可能导致UI上下文错误的操作
      try {
        promptAction.showToast({
          message: '结束任务失败，请重试',
          duration: 2000
        });
      } catch (uiError) {
        console.error('[TaskView] ❌ 显示异常提示失败:', uiError);
      }
    }
  }

  // 移除uploadTask方法，上传功能已改为跳转到TaskReviewView页面

  // 移除TaskDetailView页面跳转功能
  viewTaskDetail(taskId: number) {
    // TaskDetailView页面已删除，此功能不再可用
    promptAction.showToast({
      message: '详情查看功能已移除',
      duration: 2000
    });
  }

  getStatusColor(taskStatus: string): string {
    switch (taskStatus) {
      case AppConstants.TASK_STATUS.PENDING:
        return '#e6a23c';
      case AppConstants.TASK_STATUS.RUNNING:
        return '#409eff';
      case AppConstants.TASK_STATUS.UPLOADING:
        return '#909399';
      case AppConstants.TASK_STATUS.COMPLETED:
        return '#67c23a';
      default:
        return '#909399';
    }
  }

  getStatusText(taskStatus: string): string {
    switch (taskStatus) {
      case AppConstants.TASK_STATUS.PENDING:
        return '待巡视';
      case AppConstants.TASK_STATUS.RUNNING:
        return '巡视中';
      case AppConstants.TASK_STATUS.UPLOADING:
        return '待上传';
      case AppConstants.TASK_STATUS.COMPLETED:
        return '已完成';
      default:
        return taskStatus;
    }
  }

  build() {
    Stack() {
      Column() {
      // 页面标题
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .backgroundColor('transparent')
          .onClick(() => {
            router.back();
          })
        
        Text('任务管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Row() {
          Button('🔄')
            .fontSize(16)
            .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
            .backgroundColor('transparent')
            .onClick(() => {
              console.info('[TaskView] 🔄 手动刷新任务列表');
              this.loadTasks();
            })
            .margin({ right: 10 })
          
          Button('📹')
            .fontSize(16)
            .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
            .backgroundColor('transparent')
            .onClick(() => {
              console.info('[TaskView] 📹 跳转到摄像头测试页面');
              router.pushUrl({
                url: 'pages/CameraTestView'
              });
            })
            .margin({ right: 10 })
          
          Button('⚙️')
            .fontSize(16)
            .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
            .backgroundColor('transparent')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/SettingsView'
              });
            })
        }
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: '#eeeeee' })

      // 搜索表单
      Column() {
        Row() {
          Column() {
            Text('任务编号')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 5 })
            TextInput({ placeholder: '请输入任务编号' })
              .fontSize(14)
              .onChange((value: string) => {
                this.searchTaskCode = value;
              })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 15 })

          Column() {
            Text('创建人')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 5 })
            TextInput({ placeholder: '请输入创建人' })
              .fontSize(14)
              .onChange((value: string) => {
                this.searchCreator = value;
              })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 15 })

          Column() {
            Text('执行人')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 5 })
            TextInput({ placeholder: '请输入执行人' })
              .fontSize(14)
              .onChange((value: string) => {
                this.searchExecutor = value;
              })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 15 })

          Column() {
            Text('状态')
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 5 })
            Select([{ value: '全部' }, { value: '待巡视' }, { value: '巡视中' }, { value: '待上传' }, { value: '已完成' }])
               .selected(this.selectedStatusIndex)
               .value(this.selectedStatusIndex === 0 ? '全部' : 
                      this.selectedStatusIndex === 1 ? '待巡视' :
                      this.selectedStatusIndex === 2 ? '巡视中' :
                      this.selectedStatusIndex === 3 ? '待上传' : '已完成')
               .onSelect((index: number, value: string) => {
                 console.info('[TaskView] 🎯 选择状态筛选:', index, value);
                 this.selectedStatusIndex = index;
                 switch (index) {
                   case 0:
                     this.searchTaskStatus = '';
                     break;
                   case 1:
                     this.searchTaskStatus = AppConstants.TASK_STATUS.PENDING;
                     break;
                   case 2:
                     this.searchTaskStatus = AppConstants.TASK_STATUS.RUNNING;
                     break;
                   case 3:
                     this.searchTaskStatus = AppConstants.TASK_STATUS.UPLOADING;
                     break;
                   case 4:
                     this.searchTaskStatus = AppConstants.TASK_STATUS.COMPLETED;
                     break;
                 }
               })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 15 })

          Column() {
            Text(' ')
              .fontSize(14)
              .margin({ bottom: 5 })
            Row() {
              Button('搜索')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.PRIMARY)
                .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                .onClick(() => this.searchTasks())

              Button('重置')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#dddddd' })
                .margin({ left: 10 })
                .onClick(() => this.resetSearch())
            }
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#fafafa')
      .border({ width: { bottom: 1 }, color: '#eeeeee' })

      // 工具栏
      Row() {
        Button('📹 新增任务')
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor(AppConstants.COLORS.PRIMARY)
          .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
          .onClick(() => this.openAddTask())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 15 })
      .justifyContent(FlexAlign.Start)

      // 任务列表
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color(AppConstants.COLORS.PRIMARY)
          
          Text('加载中...')
            .fontSize(14)
            .fontColor(AppConstants.COLORS.TEXT_REGULAR)
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          // 表头
          ListItem() {
            Row() {
              Text('任务编号')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(120)
                .textAlign(TextAlign.Center)
              
              Text('任务名称')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
              
              Text('起始地点')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(100)
                .textAlign(TextAlign.Center)
              
              Text('距离')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(120)
                .textAlign(TextAlign.Center)
              
              Text('创建人')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(80)
                .textAlign(TextAlign.Center)
              
              Text('执行人')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(80)
                .textAlign(TextAlign.Center)
              
              Text('状态')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(80)
                .textAlign(TextAlign.Center)
              
              Text('操作')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(150)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height(50)
            .padding({ left: 15, right: 15 })
            .backgroundColor('#f8f9fa')
            .border({ width: { bottom: 1 }, color: '#eeeeee' })
          }

          // 数据行
          ForEach(this.tasks, (task: AgvTask, index: number) => {
            ListItem() {
              Row() {
                Text(task.taskCode)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.PRIMARY)
                  .width(120)
                  .textAlign(TextAlign.Center)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    // 移除TaskDetailView跳转，改为提示
                    promptAction.showToast({
                      message: '详情查看功能已移除',
                      duration: 2000
                    });
                  })
                
                Text(task.taskName)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                
                Text(task.startPos)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(100)
                  .textAlign(TextAlign.Center)
                
                Text(task.taskTrip)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(120)
                  .textAlign(TextAlign.Center)
                
                Text(task.creator)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(80)
                  .textAlign(TextAlign.Center)
                
                Text(task.executor)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(80)
                  .textAlign(TextAlign.Center)
                
                Text(this.getStatusText(task.taskStatus))
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor(this.getStatusColor(task.taskStatus))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .width(80)
                  .textAlign(TextAlign.Center)
                
                Row() {
                  if (task.taskStatus === AppConstants.TASK_STATUS.PENDING) {
                    Button('启动')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor(AppConstants.COLORS.SUCCESS)
                      .border({ width: 1, color: AppConstants.COLORS.SUCCESS })
                      .onClick(() => this.startTask(task.id))
                    
                    Button('编辑')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor(AppConstants.COLORS.PRIMARY)
                      .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                      .margin({ left: 5 })
                      .onClick(() => this.openEditTask(task))
                    
                    Button('删除')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor('#f56c6c')
                      .border({ width: 1, color: '#f56c6c' })
                      .margin({ left: 5 })
                      .onClick(() => this.deleteTask(task.id))
                  } else if (task.taskStatus === AppConstants.TASK_STATUS.RUNNING) {
                    Button('巡视')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor(AppConstants.COLORS.PRIMARY)
                      .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                      .onClick(() => this.goToTaskExecute(task.id))
                    
                    Button('结束')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor('#f56c6c')
                      .border({ width: 1, color: '#f56c6c' })
                      .margin({ left: 5 })
                      .onClick(() => this.endTask(task.id))
                    
                    Button('查看')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .backgroundColor('#ffffff')
                      .border({ width: 1, color: '#dddddd' })
                      .margin({ left: 5 })
                      .onClick(() => {
                        // 移除TaskDetailView跳转
                        promptAction.showToast({
                          message: '详情查看功能已移除',
                          duration: 2000
                        });
                      })
                  } else if (task.taskStatus === AppConstants.TASK_STATUS.UPLOADING) {
                    if (this.uploadingTasks.has(task.id)) {
                      Button('上传中...')
                        .fontSize(12)
                        .fontColor('#ffffff')
                        .backgroundColor('#909399')
                        .border({ width: 1, color: '#909399' })
                        .enabled(false)
                    } else {
                      Button('上传')
                        .fontSize(12)
                        .fontColor('#ffffff')
                        .backgroundColor(AppConstants.COLORS.PRIMARY)
                        .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                        .onClick(() => {
                          // 跳转到TaskReviewView页面进行复盘后上传
                          router.pushUrl({
                            url: 'pages/TaskReviewView',
                            params: {
                              taskId: task.id
                            }
                          });
                        })
                      
                      Button('删除')
                        .fontSize(12)
                        .fontColor('#ffffff')
                        .backgroundColor('#f56c6c')
                        .border({ width: 1, color: '#f56c6c' })
                        .margin({ left: 5 })
                        .onClick(() => this.deleteTask(task.id))
                    }
                    
                    Button('查看')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .backgroundColor('#ffffff')
                      .border({ width: 1, color: '#dddddd' })
                      .margin({ left: 5 })
                      .onClick(() => {
                        // 移除TaskDetailView跳转
                        promptAction.showToast({
                          message: '详情查看功能已移除',
                          duration: 2000
                        });
                      })
                  } else {
                    Button('查看')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .backgroundColor('#ffffff')
                      .border({ width: 1, color: '#dddddd' })
                      .onClick(() => {
                        // 移除TaskDetailView跳转
                        promptAction.showToast({
                          message: '详情查看功能已移除',
                          duration: 2000
                        });
                      })
                    
                    Button('删除')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor('#f56c6c')
                      .border({ width: 1, color: '#f56c6c' })
                      .margin({ left: 5 })
                      .onClick(() => this.deleteTask(task.id))
                  }
                }
                .width(200)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .height(60)
              .padding({ left: 15, right: 15 })
              .backgroundColor(index % 2 === 0 ? '#ffffff' : '#f8f9fa')
              .border({ width: { bottom: 1 }, color: '#eeeeee' })
            }
          }, (task: AgvTask) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .border({ width: 1, color: '#eeeeee' })
        .borderRadius(8)
        .margin({ left: 20, right: 20, bottom: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)

    // 新增任务模态框
    if (this.showAddTask) {
        Stack() {
          Column() {
            // 模态框标题
            Row() {
              Text(this.isEditMode ? '编辑任务' : '新增任务')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
              
              Button('✕')
                .fontSize(16)
                .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                .backgroundColor('transparent')
                .onClick(() => this.closeAddTask())
            }
            .width('100%')
            .padding(20)
            .border({ width: { bottom: 1 }, color: '#eeeeee' })

            // 表单内容
            Scroll() {
              Column() {
                Row() {
                  Column() {
                    Text('任务名称 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入任务名称', text: this.taskName })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.taskName = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

                  Column() {
                    Text('任务编号')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '留空自动生成', text: this.taskCode })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.taskCode = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 20 })

                Row() {
                  Column() {
                    Text('起始地点 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入起始地点', text: this.startPos })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.startPos = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

                  Column() {
                    Text('距离 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入距离（公里）', text: this.taskTrip })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.taskTrip = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 20 })

                Row() {
                  Column() {
                    Text('创建人 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入创建人', text: this.creator })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.creator = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

                  Column() {
                    Text('执行人 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入执行人', text: this.executor })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.executor = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 20 })



                Column() {
                  Text('备注')
                    .fontSize(14)
                    .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                    .margin({ bottom: 5 })
                  TextArea({ placeholder: '请输入备注信息', text: this.remark })
                    .fontSize(14)
                    .height(80)
                    .onChange((value: string) => {
                      this.remark = value;
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(20)
            }
            .layoutWeight(1)

            // 按钮区域
            Row() {
              Button('取消')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#dddddd' })
                .onClick(() => this.closeAddTask())

              Button(this.isEditMode ? '保存' : '新增')
                .fontSize(14)
                .fontColor('#ffffff')
                .backgroundColor(AppConstants.COLORS.PRIMARY)
                .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                .margin({ left: 15 })
                .onClick(() => this.addTask())
            }
            .justifyContent(FlexAlign.End)
            .width('100%')
            .padding(20)
          }
          .width(800)
          .height(600)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .alignContent(Alignment.Center)
         .position({ x: 0, y: 0 })
         .zIndex(1000)
         .onClick(() => this.closeAddTask())
      }
      
      // 上传进度弹窗
      if (this.showUploadProgress) {
        Stack() {
          Column() {
            Text('上传任务数据')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })
            
            Text(`任务ID: ${this.currentUploadTaskId}`)
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_REGULAR)
              .margin({ bottom: 15 })
            
            Progress({
              value: this.uploadProgress,
              total: 100,
              type: ProgressType.Linear
            })
              .width('100%')
              .height(8)
              .color(AppConstants.COLORS.PRIMARY)
              .margin({ bottom: 10 })
            
            Text(`${this.uploadProgress}%`)
              .fontSize(14)
              .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
              .textAlign(TextAlign.Center)
            
            if (this.uploadProgress === 100) {
              Text('上传完成！')
                .fontSize(14)
                .fontColor(AppConstants.COLORS.SUCCESS)
                .margin({ top: 10 })
            }
          }
          .width(300)
          .padding(30)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .alignContent(Alignment.Center)
        .position({ x: 0, y: 0 })
        .zIndex(1000)
      }
    }
    .width('100%')
    .height('100%')
  }
}