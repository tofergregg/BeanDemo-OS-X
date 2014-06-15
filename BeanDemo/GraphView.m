//
//  GraphView.m
//  beanDemo
//
//  Created by Chris Gregg on 6/12/14.
//  Copyright (c) 2014 Chris Gregg. All rights reserved.
//
//  The LightBlue Bean can be found here:
//  http://punchthrough.com/bean/
//
//  The libBean SDK can be found here:
//  https://github.com/PunchThrough/Bean-iOS-OSX-SDK

#import "GraphView.h"

@implementation GraphView
@synthesize dataX,dataY,dataZ;

-(void)awakeFromNib
{
        dataX = [[NSMutableArray alloc] init];
        dataY = [[NSMutableArray alloc] init];
        dataZ = [[NSMutableArray alloc] init];
}

- (void) drawRect : (NSRect) rect{
        [super drawRect:rect];
	[self resizeView: rect];
        
	glClearColor(1.0, 1.0, 1.0, 1.0);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        
        glLineWidth(3);
        
        // draw axis and grid
        glBegin (GL_LINES);
        glColor4f(0,0,0,1.0); // black
        glVertex3f(-1,0,0);
        glVertex3f(1,0,0);
        glEnd();
        
        glLineWidth(1);
        
        for (float x=-1;x<1;x+=0.2) {
                glBegin (GL_LINES);
                glColor4f(0,0,0,1.0); // black
                glVertex3f(x,-1,0);
                glVertex3f(x,1,0);
                glEnd();
        }
        
        for (float y=-1;y<1;y+=0.2) {
                glBegin (GL_LINES);
                glColor4f(0,0,0,1.0); // black
                glVertex3f(-1,y,0);
                glVertex3f(1,y,0);
                glEnd();
        }
        
        if ([dataX count] && [dataY count] && [dataZ count]) {
                // draw the accelerations on the OpenGLView
                // Only draw the most recent points
                
                int xScale = 4;
                int xPixels = rect.size.width / xScale;
                int minPt = (int)[dataX count] - xPixels;
                if (minPt < 0) minPt = 0;
                
                int maxPt = (int)[dataX count];
                
                glLineWidth(2);

                glBegin (GL_LINE_STRIP);
                {
                        int i;
                        
                        glColor4f(1.0, 0.0, 0.0, 1.0); // red
                        for (i = minPt; i < maxPt; i++){
                                Coord p;
                                [[dataX objectAtIndex:i] getValue:&p];
                                
                                //float t = p.t/rect.size.width * 2.0 - 1.0;
                                float t = (p.t-minPt)/xPixels * 2.0 - 1.0;
                                //float y = p.y * 2.0 - 1.0;
                                float y = p.y/2;
                                glVertex3f(t, y, 0.0f);
                        }
                }
                glEnd();
                
                glBegin (GL_LINE_STRIP);
                {
                        int i;
                        
                        glColor4f(0.0, 1.0, 0.0, 1.0); // green
                        for (i = minPt; i < maxPt; i++){
                                Coord p;
                                [[dataY objectAtIndex:i] getValue:&p];
                                
                                //float t = p.t/rect.size.width * 2.0 - 1.0;
                                float t = (p.t-minPt)/xPixels * 2.0 - 1.0;
                                //float y = p.y * 2.0 - 1.0;
                                float y = p.y/2;
                                glVertex3f(t, y, 0.0f);
                        }
                }
                glEnd();
                
                glBegin (GL_LINE_STRIP);
                {
                        int i;
                        
                        glColor4f(0.0, 0.0, 1.0, 1.0); // blue
                        for (i = minPt; i < maxPt; i++){
                                Coord p;
                                [[dataZ objectAtIndex:i] getValue:&p];
                                
                                //float t = p.t/rect.size.width * 2.0 - 1.0;
                                float t = (p.t-minPt)/xPixels * 2.0 - 1.0;
                                //float y = p.y * 2.0 - 1.0;
                                float y = p.y/2;
                                glVertex3f(t, y, 0.0f);
                        }
                }
                glEnd();
        }
	
	glFinish();
        
	[[self openGLContext] flushBuffer];
	
}

- (void) resizeView : (NSRect) rect {
	glViewport( (GLint) rect.origin.x  , (GLint) rect.origin.y,
                   (GLint) rect.size.width, (GLint) rect.size.height );
        
}

@end
