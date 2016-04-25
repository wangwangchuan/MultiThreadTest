//
//  ViewController.m
//  MultiThreadTest
//
//  Created by Daniel on 16/2/18.
//  Copyright © 2016年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 5
#define COLUMN_COUNT 3
#define IMAGE_COUNT 9
#define ROW_HEIGHT 100
#define ROW_WIDTH ROW_HEIGHT
#define CELL_SPACING 10
@interface ViewController () {
    NSMutableArray *_imageViews;
//#define SEMAPHORE
#ifdef SEMAPHORE
    dispatch_semaphore_t _semaphore;//定义一个信号量
#endif
    NSCondition *_condition;
//#define LOCK
#ifdef LOCK
    //NSMutableArray *_imageNames;
    NSLock *_lock;
#endif
//#define THREAD
#ifdef THREAD
    NSMutableArray *_threads;
#endif
}



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self layoutUI];
}

#pragma mark 界面布局
-(void)layoutUI{
    //创建多个图片控件用于显示图片
    _imageViews=[NSMutableArray array];
    for (int r=0; r<ROW_COUNT; r++) {
        for (int c=0; c<COLUMN_COUNT; c++) {
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(c*ROW_WIDTH+(c*CELL_SPACING), r*ROW_HEIGHT+(r*CELL_SPACING                           ), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            //            imageView.backgroundColor=[UIColor redColor];
            [self.view addSubview:imageView];
            [_imageViews addObject:imageView];
            
        }
    }
    //加载按钮
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(50, 400, 100, 25);
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    //停止按钮
//    UIButton *buttonStop=[UIButton buttonWithType:UIButtonTypeRoundedRect];
//    buttonStop.frame=CGRectMake(160, 400, 100, 25);
//    [buttonStop setTitle:@"停止加载" forState:UIControlStateNormal];
//    [buttonStop addTarget:self action:@selector(stopLoadImage) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:buttonStop];
    
    UIButton *btnCreate=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnCreate.frame=CGRectMake(160, 400, 100, 25);
    [btnCreate setTitle:@"创建图片" forState:UIControlStateNormal];
    [btnCreate addTarget:self action:@selector(createImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnCreate];
    
    //创建图片链接
    _imageNames=[NSMutableArray array];
//    for (int i=0; i<IMAGE_COUNT; i++) {
//        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",i]];
//    }
    //初始化锁对象
    _condition=[[NSCondition alloc]init];
    
    _currentIndex=0;
#ifdef SEMAPHORE
    /*初始化信号量
     参数是信号量初始值
     */
    _semaphore=dispatch_semaphore_create(1);
#endif
    
#ifdef LOCK
    //初始化锁对象
    _lock=[[NSLock alloc]init];
#endif
    
}


#pragma mark 创建图片
-(void)createImageName{
    [_condition lock];
    //如果当前已经有图片了则不再创建，线程处于等待状态
    if (_imageNames.count>0) {
        NSLog(@"createImageName wait, current:%i",_currentIndex);
        [_condition wait];
    }else{
        NSLog(@"createImageName work, current:%i",_currentIndex);
        //生产者，每次生产1张图片
        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",_currentIndex++]];
        
        //创建完图片则发出信号唤醒其他等待线程
        [_condition signal];
    }
    [_condition unlock];
}

#pragma mark 加载图片并将图片显示到界面
-(void)loadAnUpdateImageWithIndex:(int )index{
    //请求数据
    NSData *data= [self requestData:index];
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        UIImage *image=[UIImage imageWithData:data];
        UIImageView *imageView= _imageViews[index];
        imageView.image=image;
    });
}

#pragma mark 将图片显示到界面
-(void)updateImage:(KCImageData *)imageData{
    UIImage *image=[UIImage imageWithData:imageData.data];
    UIImageView *imageView= _imageViews[imageData.index];
    imageView.image=image;
}

#pragma mark 将图片显示到界面
-(void)updateImageWithData:(NSData *)data andIndex:(int )index{
    UIImage *image=[UIImage imageWithData:data];
    UIImageView *imageView= _imageViews[index];
    imageView.image=image;
}

#pragma mark 请求图片数据
-(NSData *)requestData:(int )index{
    NSData *data;
    NSString *name;
#ifdef LOCK
    //加锁
    [_lock lock];
#endif
#ifdef SYNC
    //@synchronized(self) 同步
    @synchronized(self) {
        if (_imageNames.count>0) {
            name=[_imageNames lastObject];
            [NSThread sleepForTimeInterval:0.001f];
            [_imageNames removeObject:name];
        }
    }
#endif
#ifdef SEMAPHORE
    //信号同步
    /*信号等待
     第二个参数：等待时间
     */
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (_imageNames.count>0) {
        name=[_imageNames lastObject];
        [_imageNames removeObject:name];
    }
    //信号通知
    dispatch_semaphore_signal(_semaphore);
#endif
#ifdef LOCK
    //使用完解锁
    [_lock unlock];
#endif
    name=[_imageNames lastObject];
    [_imageNames removeObject:name];
    if(name){
        NSURL *url=[NSURL URLWithString:name];
        data=[NSData dataWithContentsOfURL:url];
    }
    return data;
}

#pragma mark 加载图片
-(void)loadImage:(NSNumber *)index{
    int i=[index integerValue];
    
 //   NSData *data= [self requestData:i];
#define CONDITION
#ifdef THREAD
    NSThread *currentThread=[NSThread currentThread];
    
    //如果当前线程处于取消状态，则退出当前线程
    if (currentThread.isCancelled) {
        NSLog(@"thread(%@) will be cancelled!",currentThread);
        [NSThread exit];//取消当前线程
    }
#elif OPERATION
    KCImageData *imageData=[[KCImageData alloc]init];
    imageData.index=i;
    imageData.data=data;
    /*将数据显示到UI控件,注意只能在主线程中更新UI,
     另外performSelectorOnMainThread方法是NSObject的分类方法，每个NSObject对象都有此方法，
     它调用的selector方法是当前调用控件的方法，例如使用UIImageView调用的时候selector就是UIImageView的方法
     Object：代表调用方法的参数,不过只能传递一个参数(如果有多个参数请使用对象进行封装)
     waitUntilDone:是否线程任务完成执行
     */
    [self performSelectorOnMainThread:@selector(updateImage:) withObject:imageData waitUntilDone:YES];
#elif OPERATIONTWO
    NSLog(@"%@",[NSThread currentThread]);
    //更新UI界面,此处调用了主线程队列的方法（mainQueue是UI主线程）
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self updateImageWithData:data andIndex:i];
    }];
#elif QUEUE
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        [self updateImageWithData:data andIndex:i];
    });
#else
    //加锁
    [_condition lock];
    //如果当前有图片资源则加载，否则等待
    if (_imageNames.count>0) {
        NSLog(@"loadImage work,index is %i",i);
        [self loadAnUpdateImageWithIndex:i];
        [_condition broadcast];
    }else{
        NSLog(@"loadImage wait,index is %i",i);
        NSLog(@"%@",[NSThread currentThread]);
        //线程等待
        [_condition wait];
        NSLog(@"loadImage resore,index is %i",i);
        //一旦创建完图片立即加载
        [self loadAnUpdateImageWithIndex:i];
    }
    //解锁
    [_condition unlock];
#endif
}

#pragma mark - UI调用方法
#pragma mark 异步创建一张图片链接
-(void)createImageWithMultiThread{
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建图片链接
    dispatch_async(globalQueue, ^{
        [self createImageName];
    });
}

#pragma mark 多线程下载图片
-(void)loadImageWithMultiThread{
    //方法1：使用对象方法
    //创建一个线程，第一个参数是请求的操作，第二个参数是操作方法的参数
    //    NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(loadImage) object:nil];
    //    //启动一个线程，注意启动一个线程并非就一定立即执行，而是处于就绪状态，当系统调度时才真正执行
    //    [thread start];
    
    //方法2：使用类方法
    //创建多个线程用于填充图片
//#define THREAD
#ifdef THREAD
    int count=ROW_COUNT*COLUMN_COUNT;
    _threads=[NSMutableArray arrayWithCapacity:count];
    //创建多个线程用于填充图片
    for (int i=0; i<count; ++i) {
        //        [NSThread detachNewThreadSelector:@selector(loadImage:) toTarget:self withObject:[NSNumber numberWithInt:i]];
        NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(loadImage:) object:[NSNumber numberWithInt:i]];
        thread.name=[NSString stringWithFormat:@"myThread%i",i];//设置线程名称
        if(i==(count-1)){
            thread.threadPriority=1.0;
        }else{
            thread.threadPriority=0.0;
        }
        [_threads addObject:thread];
    }
    for (int i=0; i<count; i++) {
        NSThread *thread=_threads[i];
        [thread start];
    }
    
#elif OPERATION
    /*创建一个调用操作
     object:调用方法参数
     */
    int count=ROW_COUNT*COLUMN_COUNT;
    //创建操作队列
    NSOperationQueue *operationQueue=[[NSOperationQueue alloc]init];
    operationQueue.maxConcurrentOperationCount=5;//设置最大并发线程数
    //创建多个线程用于填充图片
    NSBlockOperation *lastBlockOperation=[NSBlockOperation blockOperationWithBlock:^{
        [self loadImage:[NSNumber numberWithInt:(count-1)]];
    }];
    //创建多个线程用于填充图片
    for (int i=0; i<count-1; ++i) {
        //方法1：创建操作块添加到队列
        //创建多线程操作
        NSBlockOperation *blockOperation=[NSBlockOperation blockOperationWithBlock:^{
            [self loadImage:[NSNumber numberWithInt:i]];
        }];
        //设置依赖操作为最后一张图片加载操作
        [blockOperation addDependency:lastBlockOperation];
        
        [operationQueue addOperation:blockOperation];
        
    }
    //将最后一个图片的加载操作加入线程队列
    [operationQueue addOperation:lastBlockOperation];
#else 
    int count=ROW_COUNT*COLUMN_COUNT;
    /*创建一个串行队列
     第一个参数：队列名称
     第二个参数：队列类型
     */
    //dispatch_queue_t serialQueue=dispatch_queue_create("myThreadQueue1", DISPATCH_QUEUE_SERIAL);//注意queue对象不是指针类型
    /*取得全局队列
     第一个参数：线程优先级
     第二个参数：标记参数，目前没有用，一般传入0
     */
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //这里创建一个并发队列（使用全局并发队列也可以）
   // dispatch_queue_t queue=dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
    //创建多个线程用于填充图片
    for (int i=0; i<count; ++i) {
        //异步执行队列任务
        dispatch_async(globalQueue, ^{
            [self loadImage:[NSNumber numberWithInt:i]];
        });
        
    }
    //非ARC环境请释放
    //    dispatch_release(seriQueue);

#endif

}

#pragma mark 停止加载图片
-(void)stopLoadImage{
//    for (int i=0; i<ROW_COUNT*COLUMN_COUNT; i++) {
//        NSThread *thread= _threads[i];
//        //判断线程是否完成，如果没有完成则设置为取消状态
//        //注意设置为取消状态仅仅是改变了线程状态而言，并不能终止线程
//        if (!thread.isFinished) {
//            [thread cancel];
//            
//        }
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
