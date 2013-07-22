//
//  SpectrumGLView.h
//  grid
//
//  Created by Robert Olivier on 5/28/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "FNAudioVisualizer.h"
#import "FFTBufferManager.h"

#define kNumDrawBuffers 1
#define kDefaultDrawSamples 1024
#define kMinDrawSamples 64
#define kMaxDrawSamples 4096

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

typedef enum {
	DisplayModeOscilloscopeWaveform, 
	DisplayModeOscilloscopeFFT, 
} DisplayMode;

@interface SpectrumGLView : UIView <FNAudioVisualizer> {

    GLint           backingWidth;
	GLint           backingHeight;

    GLuint			bgTexture;
    GLuint			muteOffTexture, muteOnTexture;
    GLuint			fftOffTexture, fftOnTexture;
    GLuint			sonoTexture;
	BOOL            mute;
	DisplayMode     displayMode;

    SInt32*			fftData;
    NSUInteger		fftLength;
    BOOL			hasNewFFTData;

	int32_t*		l_fftData;
 
    GLfloat*		oscilLine;
	BOOL			resetOscilLine;

    SInt16*          drawBuffers[kNumDrawBuffers];
    int             drawBufferIdx;
    int             drawBufferLen;
    int             drawBufferLen_alloced;

    
	GLuint          viewRenderbuffer, viewFramebuffer;
    GLuint          depthRenderbuffer;

	EAGLContext*    context;

	NSTimer*        animationTimer;
	NSTimeInterval  animationInterval;
	NSTimeInterval  animationStarted;

}

@property (nonatomic, assign) FFTBufferManager* fftBufferManager;
@property (nonatomic, assign) NSTimeInterval animationInterval;

- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH;
- (void)startAnimation;
- (void)stopAnimation;
- (void)processAudioBuffer:(AudioBuffer*)buffer frameCount:(UInt32)frameCount;


@end
