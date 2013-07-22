//
//  FNAudioUnitPlaybackManager.m
//  
//
//  Created by Robert Olivier on 5/29/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//
//  Guidance taken from:
//  http://atastypixel.com/blog/using-remoteio-audio-unit/
//  http://atastypixel.com/blog/a-simple-fast-circular-buffer-implementation-for-audio-processing/
//  http://cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html

#import "FNAudioUnitPlaybackManager.h"

#define kOutputBus 0
#define kInputBus 1

static OSStatus playbackCallback(void *inRefCon, 
                                 AudioUnitRenderActionFlags *ioActionFlags, 
                                 const AudioTimeStamp *inTimeStamp, 
                                 UInt32 inBusNumber, 
                                 UInt32 inNumberFrames, 
                                 AudioBufferList *ioData) {    
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
    FNAudioUnitPlaybackManager* playbackManager = (__bridge FNAudioUnitPlaybackManager*)inRefCon;
    OSStatus err = [playbackManager audioUnitOutputCallback:ioActionFlags timestamp:inTimeStamp busNumber:inBusNumber frameCount:inNumberFrames bufferList:ioData];
    return err;
}

@implementation FNAudioUnitPlaybackManager

@synthesize reader;
@synthesize asset;
@synthesize track;
@synthesize readerOutput;
@synthesize visualizer;
@synthesize delegate;
@synthesize playbackState;
@synthesize stashedMediaItem;

- (id)init {
    if((self = [super init]) != nil) {
        assetReadingShouldContinue = NO;
        TPCircularBufferInit(&circularBuffer,kBufferLength);
        readThread = nil;
        sampleBufferOffset = 0;
        self.playbackState = FNAUPlaybackStateStopped;
    }
    return self;
}

- (void)dealloc {
    TPCircularBufferCleanup(&circularBuffer);
}

/*
 switch(self.playbackState) {
 case FNAUPlaybackStateWaitingToStop:
 break;
 case FNAUPlaybackStateStopped:
 break;
 case FNAUPlaybackStateWaitingToPlay:
 break;
 case FNAUPlaybackStatePaused:
 break;
 case FNAUPlaybackStatePlaying:
 break;
 }
*/

- (void)transportStopped {
    NSLog(@"transportStopped");
    switch(self.playbackState) {
        case FNAUPlaybackStateWaitingToStop:
            AudioOutputUnitStop(audioUnit);
            TPCircularBufferClear(&circularBuffer);
            self.playbackState = FNAUPlaybackStateStopped;
            [self.delegate playbackDidStop];
            break;
        case FNAUPlaybackStateStopped:
            break;
        case FNAUPlaybackStateWaitingToPlay:
            // TODO refactor this to remove duplicate code
            AudioOutputUnitStop(audioUnit);
            TPCircularBufferClear(&circularBuffer);
            self.playbackState = FNAUPlaybackStatePlaying;
            [self startPlaying];
            [self.delegate playbackDidStart];
            break;
        case FNAUPlaybackStatePaused:
            break;
        case FNAUPlaybackStatePlaying:
            break;
    }
}

- (void)pauseTransport {
    NSLog(@"pauseTransport");
    switch(self.playbackState) {
        case FNAUPlaybackStateWaitingToStop:
            break;
        case FNAUPlaybackStateStopped:
            break;
        case FNAUPlaybackStateWaitingToPlay:
            AudioOutputUnitStop(audioUnit);
            self.playbackState = FNAUPlaybackStatePaused;
            [self.delegate playbackDidPause];
            break;
        case FNAUPlaybackStatePaused:
            break;
        case FNAUPlaybackStatePlaying:
            AudioOutputUnitStop(audioUnit);
            self.playbackState = FNAUPlaybackStatePaused;
            [self.delegate playbackDidPause];
            break;
    }
}

- (void)resumeTransport {
    NSLog(@"resumeTransport");
    switch(self.playbackState) {
        case FNAUPlaybackStateWaitingToStop:
            break;
        case FNAUPlaybackStateStopped:
            break;
        case FNAUPlaybackStateWaitingToPlay:
            break;
        case FNAUPlaybackStatePaused:
            AudioOutputUnitStart(audioUnit);
            self.playbackState = FNAUPlaybackStatePlaying;
            [self.delegate playbackDidStart];
            break;
        case FNAUPlaybackStatePlaying:
            break;
    }
}

- (OSStatus)setup {
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if(status) {
        [self printStatus:status];   
        return status;
    }
    
    UInt32 flag = 1;
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioOutputUnitProperty_EnableIO, 
                                  kAudioUnitScope_Output, 
                                  kOutputBus,
                                  &flag, 
                                  sizeof(flag));
    if(status) {
        [self printStatus:status];
        return status;
    }
    
    // Describe format
    audioFormat.mSampleRate			= 44100.0;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger;
    audioFormat.mFormatFlags        &= ~kAudioFormatFlagIsBigEndian;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    audioFormat.mBitsPerChannel     = 16;
    
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioUnitProperty_StreamFormat, 
                                  kAudioUnitScope_Input, 
                                  //                                      kOutputBus, 
                                  0,
                                  &audioFormat, 
                                  sizeof(audioFormat));
    if(status) {
        [self printStatus:status];
        return status;
    }
    
    // Set output callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioUnitProperty_SetRenderCallback, 
                                  kAudioUnitScope_Input, 
                                  //                                      kOutputBus,
                                  0,
                                  &callbackStruct, 
                                  sizeof(callbackStruct));
    if(status) {
        [self printStatus:status];
        return status;
    }
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    if(status) {
        [self printStatus:status];
        return status;
    }

    return noErr;
}

- (OSStatus)audioUnitOutputCallback:(AudioUnitRenderActionFlags*)ioActionFlags timestamp:(const AudioTimeStamp *)timestamp busNumber:(UInt32)inBusNumber frameCount:(UInt32)inNumberFrames bufferList:(AudioBufferList*)ioData {
    //NSLog(@"AU callback");
    int bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    SInt16 *targetBuffer = (SInt16*)ioData->mBuffers[0].mData;
    
    int32_t availableBytes;
    SInt16 *buffer = TPCircularBufferTail(&circularBuffer, &availableBytes);
    if(buffer == NULL) {
        NSLog(@"circular buffer is empty. end of track.");
        AudioOutputUnitStop(audioUnit);
        self.playbackState = FNAUPlaybackStateStopped;
        [self.delegate trackDidEnd];
        return noErr;
    }
    memcpy(targetBuffer, buffer, MIN(bytesToCopy, availableBytes));
    TPCircularBufferConsume(&circularBuffer,MIN(bytesToCopy, availableBytes));
    [visualizer processAudioBuffer:&ioData->mBuffers[0] frameCount:MIN(bytesToCopy, availableBytes)/4];
    return noErr;
}

-(void)printStatus:(OSStatus)status {
    if(status) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        @throw [NSException exceptionWithName:@"FNAudioUnitPlaybackManager exception" reason:[error description]  userInfo:nil];
    }
}

-(void)startReadingFromAVAssetReaderTrackOutput:(AVAssetReaderTrackOutput*)trackOutput {
    @autoreleasepool {
        assetReadingShouldContinue = YES;
        while(assetReadingShouldContinue) {
            //NSLog(@"reading sample buffer");
            CMSampleBufferRef sampleBuffer = [self.readerOutput copyNextSampleBuffer];

            if(sampleBuffer == NULL) {
                // TODO - send a notification that the track is over
                NSLog(@"end of sample buffers");
                break;
            }

            AudioBufferList audioBufferList;
            CMBlockBufferRef blockBuffer;
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
            AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
            TPCircularBufferProduceBytes(&circularBuffer, audioBuffer.mData, audioBuffer.mDataByteSize);
            CFRelease(blockBuffer);
            CFRelease(sampleBuffer);
        }
        assetReadingShouldContinue = NO;
        NSLog(@"assetReader stopped");
        [self assetReaderStopped];
    }
}

- (void)play:(MPMediaItem*)item {
    NSLog(@"play media item");
    self.stashedMediaItem = item;
    self.playbackState = FNAUPlaybackStateWaitingToPlay;
    [self stop];
}

- (void)startPlaying {
    
    OSStatus status;
    NSError* error = nil;        

    NSURL *currentSongURL = [self.stashedMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"currentSongURL url: %@",currentSongURL);
    
    self.asset = [AVURLAsset URLAssetWithURL:currentSongURL options:nil];
    NSLog(@"avurlasset url: %@",self.asset.URL);
    if(self.asset == nil) return;
    
    self.reader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
    if(error) {
        NSLog(@"%@",error);
    }
    if(self.reader == nil) {
        NSLog(@"reader is nil");
    }
    NSArray* tracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    for(AVAssetTrack* t in tracks) {
        NSLog(@"%@",t);
    }
    self.track = [tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        [NSNumber numberWithInt:44100],AVSampleRateKey,
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,                                        
                                        nil];

    self.readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:self.track outputSettings:outputSettingsDict]; //audioReadSettings
    if(self.readerOutput == nil) {
        NSLog(@"cannot construct a track output");
        return;
    }
    
    [self.reader addOutput:self.readerOutput];
    [self.reader startReading];

    CMSampleBufferRef sampleBuffer = [self.readerOutput copyNextSampleBuffer];
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    TPCircularBufferProduceBytes(&circularBuffer, audioBuffer.mData, audioBuffer.mDataByteSize);
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
    [NSThread detachNewThreadSelector:@selector(startReadingFromAVAssetReaderTrackOutput:) toTarget:self withObject:self.readerOutput];
    status = AudioOutputUnitStart(audioUnit);
    self.playbackState = FNAUPlaybackStatePlaying;
}

- (void)resume {
    [self resumeTransport];
}

- (void)pause {
    [self pauseTransport];
}

- (void)stop {
    NSLog(@"waiting to stop");
    if(!assetReadingShouldContinue) {
        NSLog(@"asset reader is not running");
        [self transportStopped];
        return;
    }
    assetReadingShouldContinue = NO;
    // signal the condition just in case we are locked
    TPCircularBufferSignal(&circularBuffer);
}

- (void)assetReaderStopped {
    [self transportStopped]; 
}

@end
