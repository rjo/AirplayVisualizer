//
//  FNAudioUnitPlaybackManager.h
//  grid
//
//  Created by Robert Olivier on 5/29/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TPCircularBuffer+AudioBufferList.h"
#import "FNAudioVisualizer.h"

#define kBufferLength 524288

typedef enum {
    FNAUPlaybackStateWaitingToStop,
    FNAUPlaybackStateStopped,
    FNAUPlaybackStateWaitingToPlay,
    FNAUPlaybackStatePaused,
    FNAUPlaybackStatePlaying
    
} FNAUPlaybackState;

typedef enum {
    FNAUPlaybackEventStopped
} FNAUPlaybackEvent;

@protocol FNAudioUnitPlaybackMangerDelegate <NSObject> 
- (void)playbackDidStop;
- (void)playbackDidStart;
- (void)playbackDidPause;
- (void)trackDidEnd;
@end

@interface FNAudioUnitPlaybackManager : NSObject  {
    AudioComponentInstance  audioUnit;
@public
    AVAssetReaderTrackOutput*   readerOutput;
    TPCircularBuffer            circularBuffer;
    NSThread*                   readThread;
    BOOL                        assetReadingShouldContinue;
    AudioStreamBasicDescription audioFormat;
    UInt32                      sampleBufferOffset;
}

@property  (nonatomic,retain) AVAssetReader*    reader;
@property  AVURLAsset*                          asset;
@property  AVAssetTrack*                        track;
@property  AVAssetReaderTrackOutput*            readerOutput;

@property (nonatomic,assign) id<FNAudioVisualizer>  visualizer;
@property (nonatomic,assign) id<FNAudioUnitPlaybackMangerDelegate> delegate;
@property (nonatomic,assign) FNAUPlaybackState  playbackState;
@property (nonatomic,retain) MPMediaItem*   stashedMediaItem;

- (OSStatus)audioUnitOutputCallback:(AudioUnitRenderActionFlags*)ioActionFlags timestamp:(const AudioTimeStamp *)timestamp busNumber:(UInt32)inBusNumber frameCount:(UInt32)inNumberFrames bufferList:(AudioBufferList*)ioData;
- (OSStatus)setup;
- (void)play:(MPMediaItem*)item;
- (void)resume;
- (void)pause;
- (void)stop;

@end
