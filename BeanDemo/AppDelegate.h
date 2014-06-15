//
//  AppDelegate.h
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
#import "PTDBean.h"
#import "PTDBeanManager.h"
#import "PTDBeanRadioConfig.h"
#import "BEAN_Globals.h"
#import "GraphView.h"

#define connectedCheck @"✅"
#define disconnectedX @"❌"

@interface AppDelegate : NSObject <NSApplicationDelegate, PTDBeanManagerDelegate, PTDBeanDelegate, NSTableViewDataSource> {
        NSLock *threadLock;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;
@property (retain) PTDBeanManager *beanManager;
@property (assign) IBOutlet NSTableView *scanTable;
@property (assign) IBOutlet NSTableView *scratchTable;
@property (retain) NSMutableArray *beans; // the BLE devices we find
@property (retain) PTDBean *bean;
@property (retain) IBOutlet NSTextField *tempReading;
@property (retain) NSMutableArray *scratchValues;
@property (weak) NSTimer *updateTimer;
@property (retain) IBOutlet GraphView *graph;
@property (retain) IBOutlet NSTextField *xAcc,*yAcc,*zAcc;
@property (retain) IBOutlet NSButton *onOffLED;
@property (assign) BOOL LEDstate;
@property (retain) IBOutlet NSColorWell *LEDColorWell;
@property (retain) IBOutlet NSProgressIndicator *connectionProgress;
@property (retain) IBOutlet NSTextField *connectedLabel;
@property int timeStep;

- (void) openScanSheet;
- (IBAction) closeScanSheet:(id)sender;
- (IBAction) cancelScanSheet:(id)sender;
- (IBAction) newConnectionMenu:(id)sender;
- (IBAction) checkScratch:(id)sender;
- (IBAction) toggleLED:(id)sender;
- (IBAction) changeLEDColor:(id)sender;
- (IBAction) disconnect:(id)sender;
- (void)updateAll;

@end
