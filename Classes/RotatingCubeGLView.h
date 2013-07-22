//
//  EAGLView.h
//  Test
//
//  Created by Robert Olivier on 4/18/09.
//  Copyright RJO Management, Inc. 2009. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FNAudioVisualizer.h"

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/

@interface RotatingCubeGLView : UIView <FNAudioVisualizer> {
    
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer * animationTimer;
    NSTimeInterval animationInterval;
	
	int step;
    GLfloat     rtri;                                         
    float		x, y, z,w, h,d,ws,hs,ds;
	
	
}

@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;
- (void)processAudioBuffer:(AudioBuffer*)audioBuffer frameCount:(UInt32)count;

@end
