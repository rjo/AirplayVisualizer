//
//  SpectrumGLView.m
//  grid
//
//  Created by Robert Olivier on 5/28/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import "SonogramGLView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SonogramGLView

@synthesize fftBufferManager;

// value, a, r, g, b
GLfloat colorLevels[] = {
    0., 1., 0., 0., 0., 
    .333, 1., .7, 0., 0., 
    .667, 1., 0., 0., 1., 
    1., 1., 0., 1., 1., 
};

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)init
{
    self = [super init];
    if (self) {
		NSLog(@"glview init");
        CGRect frame = CGRectMake(0,0,1280,734);
        self.frame = frame;
        [self setupView];
    }
    return self;
}


- (void)setupView
{
	glClearColor(0., 0., 0., 0.);
	
	spectrumRect = CGRectMake(10., 10., 460., 300.);
	
	// The bit buffer for the texture needs to be 512 pixels, because OpenGL textures are powers of 
	// two in either dimensions. Our texture is drawing a strip of 300 vertical pixels on the screen, 
	// so we need to step up to 512 (the nearest power of 2 greater than 300).
	texBitBuffer = (UInt32 *)(malloc(sizeof(UInt32) * 512));
	
	// Clears the view with black
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
	
	NSUInteger texCount = ceil(CGRectGetWidth(spectrumRect) / (CGFloat)SPECTRUM_BAR_WIDTH);
	GLuint *texNames;
	
	texNames = (GLuint *)(malloc(sizeof(GLuint) * texCount));
	glGenTextures(texCount, texNames);
	
	int i;
	SpectrumLinkedTexture *curTex = NULL;
	firstTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
	firstTex->texName = texNames[0];
	curTex = firstTex;
	
	bzero(texBitBuffer, sizeof(UInt32) * 512);
	
	glBindTexture(GL_TEXTURE_2D, curTex->texName);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	
	for (i=1; i<texCount; i++)
	{
		curTex->nextTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
		curTex = curTex->nextTex;
		curTex->texName = texNames[i];
		
		glBindTexture(GL_TEXTURE_2D, curTex->texName);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	}
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	ready = YES;
	
	free(texNames);
	
}

- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH
{
	if (LENGTH != fftLength)
	{
		fftLength = LENGTH;
		fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
	}
	memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
	hasNewFFTData = YES;
}

- (void)cycleSpectrum
{
	SpectrumLinkedTexture *newFirst;
	newFirst = (SpectrumLinkedTexture *)calloc(1, sizeof(SpectrumLinkedTexture));
	newFirst->nextTex = firstTex;
	firstTex = newFirst;
	
	SpectrumLinkedTexture *thisTex = firstTex;
	do {
		if (!(thisTex->nextTex->nextTex))
		{
			firstTex->texName = thisTex->nextTex->texName;
			free(thisTex->nextTex);
			thisTex->nextTex = NULL;
		} 
		thisTex = thisTex->nextTex;
	} while (thisTex);
}


- (void)renderFFTToTex
{
	[self cycleSpectrum];
	
	UInt32 *texBitBuffer_ptr = texBitBuffer;
	
	static int numLevels = sizeof(colorLevels) / sizeof(GLfloat) / 5;
	
	int y, maxY;
	maxY = CGRectGetHeight(spectrumRect);
	for (y=0; y<maxY; y++)
	{
		CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
		CGFloat fftIdx = yFract * ((CGFloat)fftLength-1);
        
		double fftIdx_i, fftIdx_f;
		fftIdx_f = modf(fftIdx, &fftIdx_i);
		
		SInt8 fft_l, fft_r;
		CGFloat fft_l_fl, fft_r_fl;
		CGFloat interpVal;
		
		fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
		fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
		fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
		fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
		interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
		
		interpVal = sqrt(CLAMP(0., interpVal, 1.));
        
		UInt32 newPx = 0xFF000000;
		
		int level_i;
		const GLfloat *thisLevel = colorLevels;
		const GLfloat *nextLevel = colorLevels + 5;
		for (level_i=0; level_i<(numLevels-1); level_i++)
		{
			if ( (*thisLevel <= interpVal) && (*nextLevel >= interpVal) )
			{
				double fract = (interpVal - *thisLevel) / (*nextLevel - *thisLevel);
				newPx = 
				((UInt8)(255. * linearInterp(thisLevel[1], nextLevel[1], fract)) << 24)
				|
				((UInt8)(255. * linearInterp(thisLevel[2], nextLevel[2], fract)) << 16)
				|
				((UInt8)(255. * linearInterp(thisLevel[3], nextLevel[3], fract)) << 8)
				|
				(UInt8)(255. * linearInterp(thisLevel[4], nextLevel[4], fract))
				;
				break;
			}
			
			thisLevel+=5;
			nextLevel+=5;
		}
		
		*texBitBuffer_ptr++ = newPx;
	}
	
	glBindTexture(GL_TEXTURE_2D, firstTex->texName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBitBuffer);
	
	hasNewFFTData = NO;
}

- (void)drawSpectrum
{
	// Clear the view
	glClear(GL_COLOR_BUFFER_BIT);
	
	if (fftBufferManager->HasNewAudioData())
	{
		if (fftBufferManager->ComputeFFT(l_fftData))
		{
			[self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
		}
		else
			hasNewFFTData = NO;
	}
	
	if (hasNewFFTData) [self renderFFTToTex];
	
	glClear(GL_COLOR_BUFFER_BIT);
	
	glEnable(GL_TEXTURE);
	glEnable(GL_TEXTURE_2D);
	
	glPushMatrix();
	glTranslatef(0., 480., 0.);
	glRotatef(-90., 0., 0., 1.);
	glTranslatef(spectrumRect.origin.x + spectrumRect.size.width, spectrumRect.origin.y, 0.);
	
	GLfloat quadCoords[] = {
		0., 0., 
		SPECTRUM_BAR_WIDTH, 0., 
		0., 512., 
		SPECTRUM_BAR_WIDTH, 512., 
	};
	
	GLshort texCoords[] = {
		0, 0, 
		1, 0, 
		0, 1,
		1, 1, 
	};
	
	glVertexPointer(2, GL_FLOAT, 0, quadCoords);
	glEnableClientState(GL_VERTEX_ARRAY);
	glTexCoordPointer(2, GL_SHORT, 0, texCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
	
	glColor4f(1., 1., 1., 1.);
	
	SpectrumLinkedTexture *thisTex;
	glPushMatrix();
	for (thisTex = firstTex; thisTex; thisTex = thisTex->nextTex)
	{
		glTranslatef(-(SPECTRUM_BAR_WIDTH), 0., 0.);
		glBindTexture(GL_TEXTURE_2D, thisTex->texName);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	glPopMatrix();
	glPopMatrix();
	
	glFlush();
	
}

- (void)drawView
{
   // NSLog(@"drawView");
    // the NSTimer seems to fire one final time even though it's been invalidated
    // so just make sure and not draw if we're resigning active
 //   if (self.applicationResignedActive) return;
    
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
    if(fftBufferManager != nil) {
//	[delegate drawView:self forTime:([NSDate timeIntervalSinceReferenceDate] - animationStarted)];
        [self drawSpectrum];
    }
	/*
     glRotatef(3.0f, 0.0f, 0.0f, 1.0f);
     
     glClear(GL_COLOR_BUFFER_BIT);
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	 */
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];

}

- (void)startAnimation
{
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
	animationStarted = [NSDate timeIntervalSinceReferenceDate];
}

- (void)stopAnimation
{
	[animationTimer invalidate];
	animationTimer = nil;
}

- (NSTimeInterval)animationInterval {
    return animationInterval;
}

- (void)setAnimationInterval:(NSTimeInterval)interval
{
	animationInterval = interval;
	
	if(animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}

@end
