//
//  ViewController.m
//  SocketSvs
//
//  Created by tangzhi on 17/4/17.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "ViewController.h"
//#import <netdb.h>
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate,NSTextFieldDelegate>
@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) NSMutableArray *clientSockets;//保存客户端scoket
@end

@implementation ViewController
{
    __weak IBOutlet NSTextField *port;
    
    __weak IBOutlet NSTextField *content;
    __weak IBOutlet NSTextField *titletext;
    __weak IBOutlet NSImageView *showImgView;
    
    __weak IBOutlet NSTextField *name;
    NSMutableData *imgdata;
}

- (NSMutableArray *)clientSockets
{
    if (_clientSockets == nil) {
        _clientSockets = [[NSMutableArray alloc]init];
    }
    return _clientSockets;
}

- (IBAction)ljAct:(id)sender {
    if (port.stringValue.length == 0) {
        NSLog(@"请输入端口");
        content.stringValue = @"请输入端口";
        return ;
    }
    if([port.stringValue intValue] <= 1024 || [port.stringValue intValue] > 65535) {
        NSLog(@"端口输入不合法");
        content.stringValue = @"端口输入不合法";
        return ;
    }
    //1.创建scoket对象
    GCDAsyncSocket *serviceScoket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    
    //2.绑定端口(5288)
    //端口任意，但遵循有效端口原则范围：0~65535，其中0~1024由系统使用或者保留端口，开发中建议使用1024以上的端口
    NSError *error = nil;
    int p = [port.stringValue intValue];
    [serviceScoket acceptOnPort:p error:&error];
    
    //3.开启服务(实质第二步绑定端口的同时默认开启服务)
    if (error == nil)
    {
        NSLog(@"开启成功");
        dispatch_async(dispatch_get_main_queue(), ^{
            content.stringValue = @"服务器开启成功";
        });
    }
    else
    {
        NSLog(@"开启失败");
        dispatch_async(dispatch_get_main_queue(), ^{
            content.stringValue = @"服务器开启失败";
        });
    }
    self.socket = serviceScoket;
}

#pragma mark GCDAsyncSocketDelegate
//连接到客户端socket
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //sock 服务端的socket
    //newSocket 客户端连接的socket
    NSLog(@"%@----%@",sock, newSocket);
    
    //1.保存连接的客户端socket(否则newSocket释放掉后链接会自动断开)
    [self.clientSockets addObject:newSocket];
    
//    //连接成功服务端立即向客户端提供服务
//    NSMutableString *serviceContent = [NSMutableString string];
//    [newSocket writeData:[serviceContent dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    //2.监听客户端有没有数据上传
    //-1代表不超时
    //tag标示作用
    [newSocket readDataWithTimeout:-1 tag:0];
}

//接收到客户端数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //1.接受到用户数据
//    char *buffer = [data bytes];
//    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//    NSLog(@"%@",dic);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        titletext.stringValue = dic[@"message"];
//        name.stringValue = dic[@"from"];
//    });
//
    
    Byte b0 = ((Byte*)([data bytes]))[0];//获取某一位置的数据
//    NSData *subData =[data subdataWithRange:NSMakeRange(0, 1)];
    if (b0 == 0x00) {
        [imgdata resetBytesInRange:NSMakeRange(0, imgdata.length)];
        [imgdata setLength:0];
    }
    [imgdata appendData:data];
    if (b0 == 0x00) {
        [imgdata replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];//删除索引0到索引1的数据
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSImage *img = [[NSImage alloc]initWithData:imgdata];
        showImgView.image = img;
    });
    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSInteger code = [str integerValue];
    NSString *responseString = nil;
    
    //处理请求 返回数据
    [sock writeData:[responseString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    if (code == 0) {
        [self.clientSockets removeObject:sock];
    }
    //CocoaAsyncSocket每次读取完成后必须调用一次监听数据方法
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    imgdata = [NSMutableData data];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
