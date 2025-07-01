import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HttpUtil } from '../utils/HttpUtil';
import { AppConstants } from '../constants/AppConstants';

// 任务接口
interface Task {
  id: number;
  taskNo: string;
  taskName: string;
  startLocation: string;
  endLocation: string;
  distance: number;
  creator: string;
  executor: string;
  status: string;
  createTime: string;
  remark?: string;
}

// 搜索条件接口
interface SearchParams {
  taskNo?: string;
  creator?: string;
  executor?: string;
  status?: string;
}

// 任务数据接口
interface TaskData {
  taskName: string;
  taskNo?: string;
  startLocation: string;
  endLocation: string;
  distance: number;
  creator: string;
  executor: string;
  remark?: string;
}

@Entry
@Component
struct TaskView {
  @State tasks: Task[] = [];
  @State loading: boolean = true;
  @State showAddTask: boolean = false;
  @State searchParams: SearchParams = {};
  @State newTask: Partial<Task> = {};
  
  // 搜索表单状态
  @State searchTaskNo: string = '';
  @State searchCreator: string = '';
  @State searchExecutor: string = '';
  @State searchStatus: string = '';
  
  // 新增任务表单状态
  @State taskName: string = '';
  @State taskNo: string = '';
  @State startLocation: string = '';
  @State endLocation: string = '';
  @State distance: string = '';
  @State creator: string = '';
  @State executor: string = '';
  @State remark: string = '';

  aboutToAppear() {
    this.loadTasks();
  }

  async loadTasks(): Promise<void> {
    try {
      this.loading = true;
      let queryString = '';
      const params: string[] = [];
      
      if (this.searchParams.taskNo) {
        params.push(`taskNo=${encodeURIComponent(this.searchParams.taskNo)}`);
      }
      if (this.searchParams.creator) {
        params.push(`creator=${encodeURIComponent(this.searchParams.creator)}`);
      }
      if (this.searchParams.executor) {
        params.push(`executor=${encodeURIComponent(this.searchParams.executor)}`);
      }
      if (this.searchParams.status) {
        params.push(`status=${encodeURIComponent(this.searchParams.status)}`);
      }
      
      if (params.length > 0) {
        queryString = '?' + params.join('&');
      }
      
      const url = `/agv/task/list${queryString}`;
      const response = await HttpUtil.get(url);
      
      if (response.code === 200 && response.data && typeof response.data === 'object') {
        const data = response.data as Record<string, Object>;
        this.tasks = (data['rows'] as Task[]) || [];
      }
    } catch (error) {
      console.error('加载任务列表失败:', error);
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
      taskNo: this.searchTaskNo || undefined,
      creator: this.searchCreator || undefined,
      executor: this.searchExecutor || undefined,
      status: this.searchStatus || undefined
    };
    this.loadTasks();
  }

  resetSearch() {
    this.searchTaskNo = '';
    this.searchCreator = '';
    this.searchExecutor = '';
    this.searchStatus = '';
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
    this.taskNo = '';
    this.startLocation = '';
    this.endLocation = '';
    this.distance = '';
    this.creator = '';
    this.executor = '';
    this.remark = '';
  }

  async addTask() {
    // 表单验证
    if (!this.taskName || !this.startLocation || !this.endLocation || !this.distance || !this.creator || !this.executor) {
      promptAction.showToast({
        message: '请填写所有必填字段',
        duration: 2000
      });
      return;
    }

    try {
      const taskData: TaskData = {
        taskName: this.taskName,
        taskNo: this.taskNo || undefined,
        startLocation: this.startLocation,
        endLocation: this.endLocation,
        distance: parseInt(this.distance),
        creator: this.creator,
        executor: this.executor,
        remark: this.remark || undefined
      };

      const response = await HttpUtil.post('/agv/task', taskData);
      
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
      const response = await HttpUtil.delete(`/agv/task/${taskId}`);
      
      if (response.code === 200) {
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
      const response = await HttpUtil.post(`/agv/task/start/${taskId}`);
      
      if (response.code === 200) {
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

  getStatusColor(status: string): string {
    switch (status) {
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

  getStatusText(status: string): string {
    switch (status) {
      case AppConstants.TASK_STATUS.PENDING:
        return '待巡视';
      case AppConstants.TASK_STATUS.RUNNING:
        return '巡视中';
      case AppConstants.TASK_STATUS.UPLOADING:
        return '待上传';
      case AppConstants.TASK_STATUS.COMPLETED:
        return '已完成';
      default:
        return status;
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
                this.searchTaskNo = value;
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
               .selected(0)
               .value('全部')
               .onSelect((index: number, value: string) => {
                 this.searchStatus = index === 0 ? '' : value;
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
              
              Text('结束地点')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(100)
                .textAlign(TextAlign.Center)
              
              Text('距离(m)')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                .width(80)
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
          ForEach(this.tasks, (task: Task, index: number) => {
            ListItem() {
              Row() {
                Text(task.taskNo)
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
                
                Text(task.startLocation)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(100)
                  .textAlign(TextAlign.Center)
                
                Text(task.endLocation)
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(100)
                  .textAlign(TextAlign.Center)
                
                Text(task.distance.toString())
                  .fontSize(14)
                  .fontColor(AppConstants.COLORS.TEXT_PRIMARY)
                  .width(80)
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
                
                Text(this.getStatusText(task.status))
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor(this.getStatusColor(task.status))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .width(80)
                  .textAlign(TextAlign.Center)
                
                Row() {
                  if (task.status === AppConstants.TASK_STATUS.PENDING) {
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
                  } else if (task.status === AppConstants.TASK_STATUS.UPLOADING) {
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
          }, (task: Task) => task.id.toString())
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
                        this.taskNo = value;
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
                    TextInput({ placeholder: '请输入起始地点' })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.startLocation = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

                  Column() {
                    Text('结束地点 *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入结束地点' })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.endLocation = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 20 })

                Row() {
                  Column() {
                    Text('任务距离(米) *')
                      .fontSize(14)
                      .fontColor(AppConstants.COLORS.TEXT_REGULAR)
                      .margin({ bottom: 5 })
                    TextInput({ placeholder: '请输入任务距离' })
                      .fontSize(14)
                      .type(InputType.Number)
                      .onChange((value: string) => {
                        this.distance = value;
                      })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ right: 15 })

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
                }
                .width('100%')
                .margin({ bottom: 20 })

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
                .width('100%')
                .alignItems(HorizontalAlign.Start)
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