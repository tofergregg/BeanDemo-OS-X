//
//  GraphView.h
//  BeanDemo
//
//  Created by Chris Gregg on 6/13/14.
//  Copyright (c) 2014 Chris Gregg. All rights reserved.
//
//  The LightBlue Bean can be found here:
//  http://punchthrough.com/bean/
//
//  The libBean SDK can be found here:
//  https://github.com/PunchThrough/Bean-iOS-OSX-SDK

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct _Coord {
        CGFloat t;
        CGFloat y;
} Coord;

@interface GraphView : NSOpenGLView
{
}

@property (retain) NSMutableArray *dataX,*dataY,*dataZ;

@end
