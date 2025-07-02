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
  
  // 新增任务表单状态
  @State taskName: string = '';
  @State taskCode: string = '';
  @State startPos: string = '';
  @State taskTrip: string = '';
  @State creator: string = '';
  @State executor: string = '';
  @State remark: string = '';

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
    this.clearTaskForm();
    this.showAddTask = true;
  }

  closeAddTask() {
    this.showAddTask = false;
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
    // 表单验证
    if (!this.taskName || !this.startPos || !this.taskTrip || !this.creator || !this.executor) {
      promptAction.showToast({
        message: '请填写所有必填字段',
        duration: 2000
      });
      return;
    }

    try {
      const taskData: Partial<AgvTask> = {
        taskName: this.taskName,
        taskCode: this.taskCode || undefined,
        startPos: this.startPos,
        taskTrip: this.taskTrip,
        creator: this.creator,
        executor: this.executor,
        remark: this.remark || undefined
      };

      interface ResponseWithCode {
        code: number;
      }
      const response = await TaskService.addTask(taskData) as ResponseWithCode;
      
      if (response.code === 200) {
        promptAction.showToast({
          message: '任务创建成功',
          duration: 2000
        });
        
        this.closeAddTask();
        this.loadTasks();
      }
    } catch (error) {
      console.error('创建任务失败:', error);
      promptAction.showToast({
        message: '创建任务失败，请重试',
        duration: 2000
      });
    }
  }

  async deleteTask(taskId: number) {
    try {
      const response = await TaskService.delTask(taskId);
      
      interface ResponseWithCode {
        code: number;
      }
      const responseWithCode = response as ResponseWithCode;
      if (responseWithCode.code === 200) {
        promptAction.showToast({
          message: '任务删除成功',
          duration: 2000
        });
        
        this.loadTasks();
      }
    } catch (error) {
      console.error('删除任务失败:', error);
      promptAction.showToast({
        message: '删除任务失败，请重试',
        duration: 2000
      });
    }
  }

  async startTask(taskId: number) {
    try {
      const response = await TaskService.startTask(taskId);
      
      interface ResponseWithCode {
        code: number;
      }
      const responseWithCode = response as ResponseWithCode;
      if (responseWithCode.code === 200) {
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
      }
    } catch (error) {
      console.error('启动任务失败:', error);
      promptAction.showToast({
        message: '启动任务失败，请重试',
        duration: 2000
      });
    }
  }

  viewTaskDetail(taskId: number) {
    router.pushUrl({
      url: 'pages/TaskDetailView',
      params: {
        taskId: taskId
      }
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
        
        Button('⚙️')
          .fontSize(16)
          .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
          .backgroundColor('transparent')
          .onClick(() => {
            promptAction.showToast({
              message: '设置功能开发中',
              duration: 2000
            });
          })
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
              
              Text('起始位置')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(100)
                .textAlign(TextAlign.Center)
              
              Text('任务行程')
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
                  .onClick(() => this.viewTaskDetail(task.id))
                
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
                    
                    Button('删除')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor('#f56c6c')
                      .border({ width: 1, color: '#f56c6c' })
                      .margin({ left: 5 })
                      .onClick(() => this.deleteTask(task.id))
                  } else if (task.taskStatus === AppConstants.TASK_STATUS.UPLOADING) {
                    Button('上传')
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor(AppConstants.COLORS.PRIMARY)
                      .border({ width: 1, color: AppConstants.COLORS.PRIMARY })
                      .onClick(() => {
                        promptAction.showToast({
                          message: '上传功能开发中',
                          duration: 2000
                        });
                      })
                  } else {
                    Button('查看')
                      .fontSize(12)
                      .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                      .backgroundColor('#ffffff')
                      .border({ width: 1, color: '#dddddd' })
                      .onClick(() => this.viewTaskDetail(task.id))
                  }
                }
                .width(150)
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

      // 新增任务模态框
      if (this.showAddTask) {
        Stack() {
          Column() {
            // 模态框标题
            Row() {
              Text('新增任务')
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
                    TextInput({ placeholder: '请输入任务名称' })
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
                    TextInput({ placeholder: '留空自动生成' })
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
                    Text('起始位置 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入起始位置' })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.startPos = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

                  Column() {
                    Text('任务行程 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入任务行程' })
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
                    TextInput({ placeholder: '请输入创建人' })
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
                    TextInput({ placeholder: '请输入执行人' })
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
                  TextArea({ placeholder: '请输入备注信息' })
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

              Button('保存')
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
         .onClick(() => this.closeAddTask())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLORS.BACKGROUND_BASE)
  }
}