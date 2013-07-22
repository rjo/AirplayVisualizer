//
//  EAGLView.m
//  Hello World
//
//  Created by Robert Olivier on 4/12/09.
//  Copyright RJO Management, Inc. 2009. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "RotatingCubeGLView.h"

#define USE_DEPTH_BUFFER 1

// A class extension to declare private methods
@interface RotatingCubeGLView ()

@property (nonatomic) EAGLContext *context;
@property (nonatomic, retain) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end

void gluPerspective(GLfloat fovy ,GLfloat aspect, GLfloat zNear, GLfloat zFar)
{
	GLfloat xmin, xmax, ymin, ymax;
	
	ymax = zNear * tan(fovy * M_PI / 360.0);
	ymin = -ymax;
	xmin = ymin * aspect;
	xmax = ymax * aspect;
	
	
	glFrustumf(xmin, xmax, ymin, ymax, zNear, zFar);
}

void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
			   GLfloat centerx, GLfloat centery, GLfloat centerz,
			   GLfloat upx, GLfloat upy, GLfloat upz)
{
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;
    
    /* Make rotation matrix */
    
    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
    if (mag) {          /* mpichler, 19950515 */
        z[0] /= mag;
        z[1] /= mag;
        z[2] /= mag;
    }
    
    /* Y vector */
    y[0] = upx;
    y[1] = upy;
    y[2] = upz;
    
    /* X vector = Y cross Z */
    x[0] = y[1] * z[2] - y[2] * z[1];
    x[1] = -y[0] * z[2] + y[2] * z[0];
    x[2] = y[0] * z[1] - y[1] * z[0];
    
    /* Recompute Y = Z cross X */
    y[0] = z[1] * x[2] - z[2] * x[1];
    y[1] = -z[0] * x[2] + z[2] * x[0];
    y[2] = z[0] * x[1] - z[1] * x[0];
    
    /* mpichler, 19950515 */
    /* cross product gives area of parallelogram, which is < 1.0 for
     * non-perpendicular unit-length vectors; so normalize x, y here
     */
    
    mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }
    
    mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
    if (mag) {
        y[0] /= mag;
        y[1] /= mag;
        y[2] /= mag;
    }
    
#define M(row,col)  m[col*4+row]
    M(0, 0) = x[0];
    M(0, 1) = x[1];
    M(0, 2) = x[2];
    M(0, 3) = 0.0;
    M(1, 0) = y[0];
    M(1, 1) = y[1];
    M(1, 2) = y[2];
    M(1, 3) = 0.0;
    M(2, 0) = z[0];
    M(2, 1) = z[1];
    M(2, 2) = z[2];
    M(2, 3) = 0.0;
    M(3, 0) = 0.0;
    M(3, 1) = 0.0;
    M(3, 2) = 0.0;
    M(3, 3) = 1.0;
#undef M
    glMultMatrixf(m);
    
    /* Translate Eye to Origin */
    glTranslatef(-eyex, -eyey, -eyez);
    
}

@implementation RotatingCubeGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)init {
    
    if ((self = [super init])) {
        // Get the layer
		NSLog(@"glview init");
        CGRect frame = CGRectMake(0,0,1280,734);
        self.frame = frame;
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }
        NSLog(@"initializing");
        animationInterval = 1.0 / 60.0;
		
		step = 3;
		w = 20;
		h = 20;
		d = 20;
		ws = w/step;
		hs = h/step;
		ds = d/step;
		x = w/2;
		y = h/2;
		z = d/2;
		
		/*
		 glShadeModel(GL_SMOOTH);
		 glClearDepthf(0.5f);                                                     // Depth Buffer Setup
		 glEnable(GL_DEPTH_TEST);                                                // Enables Depth Testing
		 glDepthFunc(GL_LEQUAL);
		 
		 glClearDepthf(1.0);
		 glDepthRangef(-20.0f,20.0f);
		 glClearColor(0.0, 0.0, 0.0, 1.0);
		 glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		 */
		
		
    }
    return self;
}


- (void)drawView {
	
	
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	gluPerspective(50.0,(GLfloat)backingWidth/(GLfloat)backingHeight,0.1f,300.0f);

    glMatrixMode(GL_MODELVIEW);
	
	glPushMatrix();
    glLoadIdentity(); // Reset The View
	
	glTranslatef(0.0,0.0,-35.0);                               // Move Left And Into The Screen
    
    glScalef(1.0,1.0,1.0);
	// glRotatef(rtri,1.0f,1.0,0.0f);                        
    glRotatef(-3.0*rtri,-2.0f,1.0f,0.0f);
    glTranslatef(0.0,0.0,0.0);
	
	glLineWidth(2.0);
	
	//gluLookAt(0.0,0.0,5.0,0.0,0.0,1.0,0.0,1.0,0.0);
	
	/*
	 glTranslatef(0.0,0.0,0.0);                                  
	 glScalef(1.0,1.0,1.0);
	 glRotatef(-3.0*rtri,-1.0f,1.0,0.0f);
	 glTranslatef(0.0,0.0,0.0);                                  
	 */
	glColor4f(1.0,0.0,0.7,1.0);
	
	GLfloat vertices[78];
	
	int i;
	
	
    for(i=0; i<step+1;i++) {
		int vertexIndex = 0;
		
		
        vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y+i*hs;
		vertices[vertexIndex+2] = -z;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = -y+i*hs;
		vertices[vertexIndex+5] = -z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x+i*ws;
		vertices[vertexIndex+1] = y;
		vertices[vertexIndex+2] = -z;
		
		vertices[vertexIndex+3] = -x+i*ws;
		vertices[vertexIndex+4] = -y;
		vertices[vertexIndex+5] = -z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y+i*hs;
		vertices[vertexIndex+2] = z;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = -y+i*hs;
		vertices[vertexIndex+5] = z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x+i*ws;
		vertices[vertexIndex+1] = y;
		vertices[vertexIndex+2] = z;
		
		vertices[vertexIndex+3] = -x+i*ws;
		vertices[vertexIndex+4] = -y;
		vertices[vertexIndex+5] = z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y;
		vertices[vertexIndex+2] = -z+i*ds;
		
		vertices[vertexIndex+3] = -x;
		vertices[vertexIndex+4] = y;
		vertices[vertexIndex+5] = -z+i*ds;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y;
		vertices[vertexIndex+2] = -z+i*ds;
		
		vertices[vertexIndex+3] = -x;
		vertices[vertexIndex+4] = y;
		vertices[vertexIndex+5] = -z+i*ds;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y+i*hs;
		vertices[vertexIndex+2] = -z;
		
		vertices[vertexIndex+3] = -x;
		vertices[vertexIndex+4] = -y+i*hs;
		vertices[vertexIndex+5] = z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = x;
		vertices[vertexIndex+1] = -y;
		vertices[vertexIndex+2] = -z+i*ds;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = y;
		vertices[vertexIndex+5] = -z+i*ds;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = x;
		vertices[vertexIndex+1] = -y+i*hs;
		vertices[vertexIndex+2] = -z;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = -y+i*hs;
		vertices[vertexIndex+5] = z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = y;
		vertices[vertexIndex+2] = -z+i*hs;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = y;
		vertices[vertexIndex+5] = -z+i*hs;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x+i*ws;
		vertices[vertexIndex+1] = y;
		vertices[vertexIndex+2] = z;
		
		vertices[vertexIndex+3] = -x+i*ws;
		vertices[vertexIndex+4] = y;
		vertices[vertexIndex+5] = -z;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x;
		vertices[vertexIndex+1] = -y;
		vertices[vertexIndex+2] = -z+i*hs;
		
		vertices[vertexIndex+3] = x;
		vertices[vertexIndex+4] = -y;
		vertices[vertexIndex+5] = -z+i*hs;
		
		vertexIndex += 6;
		
		vertices[vertexIndex+0] = -x+i*ws;
		vertices[vertexIndex+1] = -y;
		vertices[vertexIndex+2] = z;
		
		vertices[vertexIndex+3] = -x+i*ws;
		vertices[vertexIndex+4] = -y;
		vertices[vertexIndex+5] = -z;
		
		
		glDrawArrays(GL_LINES, 0, 26);
		
		
    }
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glPopMatrix();
	rtri+=0.05f; 
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews {
    NSLog(@"layout subviews");
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    NSLog(@"backing width/height:%d,%d ",backingWidth,backingHeight);
    if (USE_DEPTH_BUFFER) {
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


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation {
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}

- (void)processAudioBuffer:(AudioBuffer*)audioBuffer frameCount:(UInt32)count {
    
}

/*
- (void)setAnimationInterval:(NSTimeInterval)interval {
    
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}
*/

- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
}

@end

