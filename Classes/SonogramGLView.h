//
//  SonogramGLView.h
//  grid
//
//  Created by Robert Olivier on 5/28/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "FFTBufferManager.h"

#define SPECTRUM_BAR_WIDTH 4

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

typedef struct SpectrumLinkedTexture {
	GLuint							texName; 
	struct SpectrumLinkedTexture	*nextTex;
} SpectrumLinkedTexture;

inline double linearInterp(double valA, double valB, double fract)
{
	return valA + ((valB - valA) * fract);
}

@interface SonogramGLView : UIView {

    UInt32*						texBitBuffer;
    CGRect						spectrumRect;
	SpectrumLinkedTexture*		firstTex;
    BOOL                        ready;
    
    SInt32*						fftData;
    NSUInteger					fftLength;
	BOOL						hasNewFFTData;
	int32_t*					l_fftData;
    
    NSTimer*                    animationTimer;
	NSTimeInterval              animationInterval;
	NSTimeInterval              animationStarted;

	EAGLContext *context;
	GLuint viewRenderbuffer, viewFramebuffer;

}

@property (nonatomic, assign) FFTBufferManager* fftBufferManager;
@property NSTimeInterval animationInterval;

- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH;
- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;

@end
