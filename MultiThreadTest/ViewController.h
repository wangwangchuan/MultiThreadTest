//
//  ViewController.h
//  MultiThreadTest
//
//  Created by Daniel on 16/2/18.
//  Copyright © 2016年 Daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
#pragma mark 图片资源存储容器
@property (atomic,strong) NSMutableArray *imageNames;//原子属性，多线程

#pragma mark 当前加载的图片索引（图片链接地址连续）
@property (atomic,assign) int currentIndex;
@end

