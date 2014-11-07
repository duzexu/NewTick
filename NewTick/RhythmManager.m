//
//  RhythmManager.m
//  NewTick
//
//  Created by 杜 泽旭 on 14/11/6.
//  Copyright (c) 2014年 杜 泽旭. All rights reserved.
//

#import "RhythmManager.h"
#import <AudioToolbox/AudioToolbox.h>

#define NUM_BUFFERS 2 //buffer队列的数量
#define BYTES_PERSECOND 88200 //每秒钟buffer的大小
static UInt32 gBufferSizeBytes=0x30000;//buffer缓存的大小

@interface RhythmManager ()
{
    //播放音频文件ID
    AudioFileID audioFile_Sound_0;
    AudioFileID audioFile_Sound_1;
    
    //音频流描述对象
    AudioStreamBasicDescription dataFormat;
    
    //音频队列
    AudioQueueRef queue;
    
    SInt64 packetIndex;
    
    UInt32 numPacketsToRead;
    
    UInt32 bufferByteSize;
    
    AudioStreamPacketDescription *packetDescs;
    
    AudioQueueBufferRef buffers[NUM_BUFFERS];
    
    
    NSDictionary *sourceData;//节奏声音数据文件
    NSInteger totalRingCount;//每小节的数量
    
    NSInteger tactsIndex;//节奏index
    
}

@property (assign ,nonatomic) AudioQueueRef queue;//音频队列
@property (assign, nonatomic) NSInteger currentRingCount;//目前在第几拍
@property (assign, nonatomic) NSInteger bmpSpeed;//节拍速度

@end

@implementation RhythmManager
@synthesize queue = _queue;

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"plist"];
        sourceData = [NSDictionary dictionaryWithContentsOfFile:path];
        //初始化参数
        _currentRingCount = 1;
        _bmpSpeed = 100;
        tactsIndex = 100;
        [self rhythmAtIndex:3];
        //初始化audioqueue
        [self initAudioQueue];
    }
    return self;
}

- (NSArray*)rhythmArray
{
    return sourceData[@"Tacts"];
}

- (NSString*)rhythmAtIndex:(NSInteger)index
{
    tactsIndex = index;
    if (index >= [[self rhythmArray]count]) {
        tactsIndex = 0;
    }
    NSArray *rhythm = [sourceData[@"Tacts"][tactsIndex] componentsSeparatedByString:@"/"];
    totalRingCount = [rhythm[0] integerValue];
    _currentRingCount = totalRingCount;
    return [self rhythmArray][tactsIndex];
}

- (void)upTargetRate:(completeBlock)complete
{
    if (_bmpSpeed == 240) {
        complete(NO,_bmpSpeed);
        return;
    }
    _bmpSpeed++;
    complete(YES,_bmpSpeed);
}

- (void)downTargetRate:(completeBlock)complete
{
    if (_bmpSpeed == 30) {
        complete(NO,_bmpSpeed);
        return;
    }
    _bmpSpeed--;
    complete(YES,_bmpSpeed);
}

- (NSString*)currentSpeed
{
    return [NSString stringWithFormat:@"%ld",(long)_bmpSpeed];
}

- (void)pause
{
    AudioQueuePause(queue);
}
- (void)resume
{
    AudioQueueStart(queue, nil);
}
- (void)stop
{
    AudioQueueStop(queue, YES);
}

#pragma mark - AudioQueue播放方法实现
//回调函数(Callback)的实现
static void BufferCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef buffer){
    RhythmManager* player=(__bridge RhythmManager*)inUserData;
    [player audioQueueOutputWithQueue:inAQ queueBuffer:buffer];
}

//缓存数据读取方法的实现
-(void)audioQueueOutputWithQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBuffer
{
    [self readPacketsIntoBuffer:audioQueueBuffer];
}

//音频播放的初始化、实现
-(void)initAudioQueue
{
    UInt32 size,maxPacketSize;
    
    char *cookie;
    
    int i;
    
    OSStatus status;
    
    //初始化声音文件
    NSArray *sound_0 = [sourceData[@"Sounds"][0][@"Sound1"] componentsSeparatedByString:@"."];
    NSArray *sound_1 = [sourceData[@"Sounds"][0][@"Sound2"] componentsSeparatedByString:@"."];
    NSString *fileName_Sound_0 = [[NSBundle mainBundle] pathForResource:sound_0[0] ofType:sound_0[1]];
    NSString *fileName_Sound_1 = [[NSBundle mainBundle] pathForResource:sound_1[0] ofType:sound_1[1]];
    
    //打开音频文件
    if (!(fileName_Sound_0 && fileName_Sound_1)) {
        return;
    }
    status=AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:fileName_Sound_0], kAudioFileReadPermission, 0, &audioFile_Sound_0);
    status=AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:fileName_Sound_1], kAudioFileReadPermission, 0, &audioFile_Sound_1);
    
    if (status != noErr) {
        //错误处理
        NSLog(@"*** Error *** PlayAudio - play:Path: could not open audio file. Path given was: %@", fileName_Sound_1);
    }
    
    for (int i=0; i<NUM_BUFFERS; i++) {
        AudioQueueEnqueueBuffer(queue, buffers[i], 0, nil);
    }
    
    //取得音频数据格式
    size = sizeof(dataFormat);
    
    AudioFileGetProperty(audioFile_Sound_0, kAudioFilePropertyDataFormat, &size, &dataFormat);
    
    //创建播放用的音频队列
    AudioQueueNewOutput(&dataFormat, BufferCallback, (__bridge void *)(self),nil, nil, 0, &queue);
    
    //计算单位时间包含的包数
    if (dataFormat.mBytesPerPacket==0 || dataFormat.mFramesPerPacket==0) {
        
        size=sizeof(maxPacketSize);
        
        AudioFileGetProperty(audioFile_Sound_0, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
        
        if (maxPacketSize > gBufferSizeBytes) {
            
            maxPacketSize= gBufferSizeBytes;
            
        }
        
        //算出单位时间内含有的包数
        numPacketsToRead = gBufferSizeBytes/maxPacketSize;
        
        packetDescs=malloc(sizeof(AudioStreamPacketDescription)*numPacketsToRead);
        
    }else {
        
        numPacketsToRead= gBufferSizeBytes/dataFormat.mBytesPerPacket;
        
        packetDescs=malloc(sizeof(AudioStreamPacketDescription)*numPacketsToRead);
        
    }
    
    //设置Magic Cookie，参见第二十七章的相关介绍
    AudioFileGetProperty(audioFile_Sound_0, kAudioFilePropertyMagicCookieData, &size, nil);
    
    if (size >0) {
        
        cookie=malloc(sizeof(char)*size);
        
        AudioFileGetProperty(audioFile_Sound_0, kAudioFilePropertyMagicCookieData, &size, cookie);
        
        AudioQueueSetProperty(queue, kAudioQueueProperty_MagicCookie, cookie, size);
        
    }
    
    //创建并分配缓冲空间
    packetIndex=0;
    
    for (i=0; i<NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(queue, gBufferSizeBytes, &buffers[i]);
        //读取包数据
        if ([self readPacketsIntoBuffer:buffers[i]]==1) {
            break;
        }
    }
    
    Float32 gain=1.0;
    
    //设置音量
    AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gain);
    
    //队列处理开始，此后系统开始自动调用回调(Callback)函数
    //AudioQueueStart(queue, nil);
    
}

-(UInt32)readPacketsIntoBuffer:(AudioQueueBufferRef)buffer {
    
    UInt32 numBytes,numPackets;
    
    //从文件中接受数据并保存到缓存(buffer)中
    numPackets = numPacketsToRead;
    
    UInt32 size = BYTES_PERSECOND*60/_bmpSpeed/totalRingCount;
    void *newBuffer = malloc(size);
    memset(newBuffer, 0, size);
    
    if (_currentRingCount%totalRingCount==0) {
        AudioFileReadPackets(audioFile_Sound_0, NO, &numBytes, packetDescs, packetIndex, &numPackets, newBuffer);
    }else{
        AudioFileReadPackets(audioFile_Sound_1, NO, &numBytes, packetDescs, packetIndex, &numPackets, newBuffer);
    }
    
    if(numPackets >0){
        buffer->mAudioDataByteSize=size;
        memcpy(buffer->mAudioData, newBuffer, size);
        _currentRingCount++;
        AudioQueueEnqueueBuffer(queue, buffer, (packetDescs ? numPackets : 0), packetDescs);
    }
    
    free(newBuffer);
    newBuffer = NULL;
    
    return 0;//0代表正常的退出
}


@end
