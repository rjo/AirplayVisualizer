//
//  SpectrumGLView.m
//  grid
//
//  Created by Robert Olivier on 5/28/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <OpenGLES/EAGLDrawable.h>
#import "SpectrumGLView.h"

#define USE_DEPTH_BUFFER 1

@implementation SpectrumGLView

@synthesize fftBufferManager;

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
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
			return nil;
		}
		
		animationInterval = 1.0 / 60.0;

        drawBufferIdx = 0;
        drawBufferLen = kDefaultDrawSamples;
        drawBufferLen_alloced = 0;
        displayMode = DisplayModeOscilloscopeWaveform;
        self.fftBufferManager = new FFTBufferManager(4096);
        
        int drawBuffer_i;
        
        // Allocate our draw buffer if needed
        if (drawBufferLen_alloced == 0)
            for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
                drawBuffers[drawBuffer_i] = NULL;
        
        // Fill the first element in the draw buffer with PCM data
        for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
        {
            drawBuffers[drawBuffer_i] = (SInt16 *)realloc(drawBuffers[drawBuffer_i], drawBufferLen*sizeof(SInt16));
            bzero(drawBuffers[drawBuffer_i], drawBufferLen*sizeof(SInt16));
        }
   //     for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
   //     {
   //         bzero(drawBuffers[drawBuffer_i], drawBufferLen);
   //     }

        resetOscilLine = YES;
        
        CGImageRef img;
        img = [UIImage imageNamed:@"oscilloscope.png"].CGImage;
        [self createGLTexture:&bgTexture fromCGImage:img];
        [self setupView];
        [self drawView];

    }
    return self;
}

- (void)dealloc
{
	[self stopAnimation];
	
	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	context = nil;
	
}

- (void)processAudioBuffer:(AudioBuffer*)buffer frameCount:(UInt32)frameCount {
    
//    [self cycleOscilloscopeLines];
    SInt16 *data_ptr = (SInt16 *)(buffer->mData);
    for (int i=0; i<1024; i++) {
        drawBuffers[0][i] = data_ptr[0];
        data_ptr += 2;
    }
   
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


- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}


- (BOOL)createFramebuffer
{
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if(USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
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


- (void)createGLTexture:(GLuint *)texName fromCGImage:(CGImageRef)img
{
	GLubyte *spriteData = NULL;
	CGContextRef spriteContext;
	GLuint imgW, imgH, texW, texH;
	
	imgW = CGImageGetWidth(img);
	imgH = CGImageGetHeight(img);
	
	// Find smallest possible powers of 2 for our texture dimensions
	for (texW = 1; texW < imgW; texW *= 2) ;
	for (texH = 1; texH < imgH; texH *= 2) ;
	
	// Allocated memory needed for the bitmap context
	spriteData = (GLubyte *) calloc(texH, texW * 4);
	// Uses the bitmatp creation function provided by the Core Graphics framework. 
	spriteContext = CGBitmapContextCreate(spriteData, texW, texH, 8, texW * 4, CGImageGetColorSpace(img), kCGImageAlphaPremultipliedLast);
	
	// Translate and scale the context to draw the image upside-down (conflict in flipped-ness between GL textures and CG contexts)
	CGContextTranslateCTM(spriteContext, 0., texH);
	CGContextScaleCTM(spriteContext, 1., -1.);
	
	// After you create the context, you can draw the sprite image to the context.
	CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, imgW, imgH), img);
	// You don't need the context at this point, so you need to release it to avoid memory leaks.
	CGContextRelease(spriteContext);
	
	// Use OpenGL ES to generate a name for the texture.
	glGenTextures(1, texName);
	// Bind the texture name. 
	glBindTexture(GL_TEXTURE_2D, *texName);
	// Speidfy a 2D texture image, provideing the a pointer to the image data in memory
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texW, texH, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	free(spriteData);
}

- (void)setupView
{
	
	// Sets up matrices and transforms for OpenGL ES
	glViewport(0, 0, backingWidth, backingHeight);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, backingWidth, 0, backingHeight, -1.0f, 1.0f);
    NSLog(@"backing size %d,%d",backingWidth,backingHeight);
	glMatrixMode(GL_MODELVIEW);
	
	// Clears the view with black
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	///glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
}

- (void)cycleOscilloscopeLines
{
	// Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	int drawBuffer_i;
	for (drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
		memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], 2048/*drawBufferLen*/);
}

- (void)drawOscilloscope
{
    // NSLog(@"draw oscilloscope");
	// Clear the view
	glClear(GL_COLOR_BUFFER_BIT);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	
	glColor4f(1., 1., 1., 1.);
	
	glPushMatrix();
	
	//glTranslatef(400., 200., 0.);
	//glRotatef(-90., 0., 0., 1.);
	
	
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	/*
	{
		// Draw our background oscilloscope screen
		const GLfloat vertices[] = {
			0., 0.,
			512., 0., 
			0.,  512.,
			512.,  512.,
		};
		const GLshort texCoords[] = {
			0, 0,
			1, 0,
			0, 1,
			1, 1,
		};
		
		
		glBindTexture(GL_TEXTURE_2D, bgTexture);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_SHORT, 0, texCoords);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	*/
	
	
	
	if (displayMode == DisplayModeOscilloscopeFFT)
	{			
		if (fftBufferManager->HasNewAudioData())
		{
			if (fftBufferManager->ComputeFFT(l_fftData))
				[self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
			else
				hasNewFFTData = NO;
		}
        
		if (hasNewFFTData)
		{
            
			int y, maxY;
			maxY = drawBufferLen;
			for (y=0; y<maxY; y++)
			{
				CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
				CGFloat fftIdx = yFract * ((CGFloat)fftLength);
				
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
				
				interpVal = CLAMP(0., interpVal, 1.);
                
				drawBuffers[0][y] = (interpVal * 120);
				
			}
			[self cycleOscilloscopeLines];
			
		}
		
	}
	
	GLfloat *oscilLine_ptr;
	GLfloat max = drawBufferLen;
	SInt16 *drawBuffer_ptr;
	
	// Alloc an array for our oscilloscope line vertices
	if (resetOscilLine) {
		oscilLine = (GLfloat*)realloc(oscilLine, drawBufferLen * 2 * sizeof(GLfloat));
		resetOscilLine = NO;
	}
	
	glPushMatrix();
	
	// Translate to the left side and vertical center of the screen, and scale so that the screen coordinates
	// go from 0 to 1 along the X, and -1 to 1 along the Y
	glTranslatef(0., 367., 0.);
	glScalef(1280.,240., 1.);
	
	// Set up some GL state for our oscilloscope lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisable(GL_LINE_SMOOTH);
	glLineWidth(2.5);
	
	int drawBuffer_i;
	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
	{
		if (!drawBuffers[drawBuffer_i]) continue;
		
		oscilLine_ptr = oscilLine;
		drawBuffer_ptr = drawBuffers[drawBuffer_i];
		
		GLfloat i;
		// Fill our vertex array with points
		for (i=0.; i<max; i=i+1.)
		{
			*oscilLine_ptr++ = i/max;
			*oscilLine_ptr++ = (Float32)(*drawBuffer_ptr++) / 32768.0;
		}
		
		// If we're drawing the newest line, draw it in solid green. Otherwise, draw it in a faded green.
		if (drawBuffer_i == 0)
			glColor4f(0., 1., 0., 1.);
		else
			glColor4f(0., 1., 0., (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
		
		// Set up vertex pointer,
		glVertexPointer(2, GL_FLOAT, 0, oscilLine);
		
		// and draw the line.
		glDrawArrays(GL_LINE_STRIP, 0, drawBufferLen);
		
	}
	
	glPopMatrix();
    
	glPopMatrix();
}


- (void)drawView
{
    // the NSTimer seems to fire one final time even though it's been invalidated
    // so just make sure and not draw if we're resigning active
    //   if (self.applicationResignedActive) return;
    
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
    if(fftBufferManager != nil) {
        //	[delegate drawView:self forTime:([NSDate timeIntervalSinceReferenceDate] - animationStarted)];
        [self drawOscilloscope];
    }
    [self drawOscilloscope];

	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
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
