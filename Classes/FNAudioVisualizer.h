//
//  FNAudioVisualizer.h
//  grid
//
//  Created by Robert Olivier on 5/29/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol FNAudioVisualizer <NSObject>

- (void)processAudioBuffer:(AudioBuffer*)audioBuffer frameCount:(UInt32)count;

@end
