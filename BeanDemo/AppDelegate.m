//
//  AppDelegate.m
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

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize beanManager,bean,beans;
@synthesize updateTimer,connectionProgress,connectedLabel;
@synthesize graph,xAcc,yAcc,zAcc;
@synthesize timeStep;
@synthesize scanTable,scratchTable;
@synthesize scratchValues;
@synthesize LEDstate,LEDColorWell,onOffLED;

- (void)awakeFromNib {
        [scratchTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
        // LED state
        LEDstate = false;
        
        // create the bean and assign ourselves as the delegate
        threadLock = [[NSLock alloc] init]; // lock for the bean

        self.beans = [NSMutableArray array];
        self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
        
        // set up the scratch mutable array
        scratchValues = [[NSMutableArray alloc] init];
        for (int i=0;i<5;i++) {
                [scratchValues addObject:@""];
        }
        
        self.bean = nil;
        self.updateTimer = nil;
        timeStep = 0;
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setMaximumFractionDigits:3];
        
        [xAcc setFormatter:formatter];
        [xAcc setTextColor:[NSColor redColor]];
        
        [yAcc setTextColor:[NSColor greenColor]];
        [yAcc setFormatter:formatter];
        
        [zAcc setTextColor:[NSColor blueColor]];
        [zAcc setFormatter:formatter];
}

/*
 Disconnect peripheral when application terminate
 */
- (void) applicationWillTerminate:(NSNotification *)notification
{
        if(self.bean)
        {
                [beanManager disconnectBean:bean error:nil];
                //NSLog(@"Sent message to cancel bean.");
                //[NSThread sleepForTimeInterval:1];
        }
}

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)newConnectionMenu:(id)sender
{
        if (bean.state != BeanState_ConnectedAndValidated) {
                NSLog(@"Finding New Beans");
                
                [threadLock lock]; // NSMutableArray isn't thread-safe
                if ([beans count]) [self.beans removeAllObjects];
                [scanTable reloadData];
                [threadLock unlock];


                if(self.beanManager.state == BeanManagerState_PoweredOn){
                        // if we're on, scan for advertisting beans
                        [self openScanSheet];
                }
                else if (self.beanManager.state == BeanManagerState_PoweredOff) {
                        // probably should have an error message here
                }
        }
}

// check to make sure we're on
- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{

}
// bean discovered
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)aBean error:(NSError*)error{
        if (error) {
                PTDLog(@"%@", [error localizedDescription]);
                return;
        }
        if( ![self.beans containsObject:aBean] ){
                NSLog(@"Name: '%@',%ld",[aBean name],[self.beans count]);

                [self.beans addObject:aBean];
        }
        [self.scanTable reloadData];
        NSLog(@"Updated Bean in Scan Window: %@",[((PTDBean *)self.beans[0]) name]);
        //[self.beanManager connectToBean:bean error:nil];
}
// bean connected
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
        if (error) {
                PTDLog(@"%@", [error localizedDescription]);
                return;
        }
        // do stuff with your bean
        NSLog(@"Bean connected!");
        [connectionProgress stopAnimation:self];
        [connectedLabel setStringValue:connectedCheck];
        
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error {
        NSLog(@"Bean disconnected.");
        [connectedLabel setStringValue:disconnectedX];
}

/*
 Open scan sheet to discover Bean peripheral if it is LE capable hardware
 */
- (void) openScanSheet
{

        [NSApp beginSheet:self.scanSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self.beanManager startScanningForBeans_error:nil];
}

/*
 Close scan sheet once device is selected
 */
- (IBAction)closeScanSheet:(id)sender
{
        [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
        [self.scanSheet orderOut:self];
}

/*
 This method is called when Scan sheet is closed. Initiate connection to selected heart rate peripheral
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
        [self.beanManager stopScanningForBeans_error:nil];
        if( returnCode == NSAlertDefaultReturn )
        {
                NSInteger selectedRow = [self.scanTable selectedRow];
                if (selectedRow != -1)
                {
                        self.bean = [self.beans objectAtIndex:selectedRow];
                        self.bean.delegate = self;
                        [connectedLabel setStringValue:@""];
                        [connectionProgress startAnimation:self];
                        [self.beanManager connectToBean:bean error:nil];
                        [self.updateTimer invalidate];
                        
                        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                                          target:self selector:@selector(updateAll)
                                                                        userInfo:nil repeats:YES];
                        self.updateTimer = timer;
                }
        }
}

/*
 Close scan sheet without choosing any device
 */
- (IBAction)cancelScanSheet:(id)sender
{
        [self.beanManager stopScanningForBeans_error:nil];
        [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
        [self.scanSheet orderOut:self];
}

#pragma mark tableview methods
// must handle both tables in the interface
// ScratchTable, ScanTable

- (id) tableView:(NSTableView *) aTableView
        objectValueForTableColumn:(NSTableColumn *) aTableColumn
                              row:(NSInteger) rowIndex
{
        if ([aTableView isEqualTo:scanTable]) {
                return [[self.beans objectAtIndex:rowIndex] name];
        }
        else { // scratchTable
                if ([aTableColumn.identifier isEqual: @"Number"]){
                        return [NSString stringWithFormat:@"%lu",rowIndex+1];
                }
                else {
                        if (scratchValues &&
                            ![scratchValues[rowIndex] isEqual:@"\0"] &&
                            ![scratchValues[rowIndex] isEqual:@""]) {
                                return scratchValues[rowIndex];
                        }
                        else {
                                return @"(none)";
                        }
                }
        }
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
        if ([aTableView isEqualTo:scanTable]) {
                return [self.beans count];
        }
        else { // scratchTable
                return 5; // five scratch registers
        }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
        if ([[notification object] isEqualTo:scratchTable]) {
                // send message to bean updating value
                if (bean.state == BeanState_ConnectedAndValidated) {
                        long row = scratchTable.editedRow;
                        NSString *str = [NSString stringWithString:[[scratchTable currentEditor] string]];
                        
                        [scratchValues replaceObjectAtIndex:row withObject:str];
                        
                        // put a null on the end so the value returned is null terminated
                        // and also because we need to send some bytes, or the scratch
                        // value doesn't get changed
                        NSMutableData *data = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
                        unsigned char null = '\0';
                        [data appendBytes:&null length:1];
                        
                        //[bean setScratchNumber:row+1 withValue:[str dataUsingEncoding:NSUTF8StringEncoding]];
                        [bean setScratchNumber:row+1 withValue:data];
                }
                
                
        }
}

// oddly, we seem to have to do the text coloring twice...
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
        if ([tableView isEqualTo:scratchTable]) {
                if ([[cell stringValue] isEqual:@"(none)"]) {
                        [cell setTextColor: [NSColor redColor]];
                } else {
                        [cell setTextColor: [NSColor blackColor]];
                }
        }
}
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
        NSTextFieldCell *cell = [tableColumn dataCell];

        if ([tableView isEqualTo:scratchTable]) {
                if ([[cell stringValue] isEqual:@"(none)"]) {
                        [cell setTextColor: [NSColor redColor]];
                } else {
                        [cell setTextColor: [NSColor blackColor]];
                }
        }
        return cell;
}

-(void)bean:(PTDBean*)bean didUpdateTemperature:(NSNumber*)degrees_celsius {
        [self.tempReading setStringValue:[NSString stringWithFormat:@"%@ºC",degrees_celsius]];
        //NSLog(@"temp: %@ºC",degrees_celsius);
}

-(void)bean:(PTDBean *)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {
        
        //NSLog(@"acc:%f,%f,%f",acceleration.x,acceleration.y,acceleration.z);
        
        Coord coord;
        coord.t = timeStep;
        
        coord.y = acceleration.x;
        [graph.dataX addObject:[NSValue value:&coord withObjCType:@encode(Coord)]];
        [xAcc setFloatValue:acceleration.x];
        
        coord.y = acceleration.y;
        [graph.dataY addObject:[NSValue value:&coord withObjCType:@encode(Coord)]];
        [yAcc setFloatValue:acceleration.y];
        
        coord.y = acceleration.z;
        [graph.dataZ addObject:[NSValue value:&coord withObjCType:@encode(Coord)]];
        [zAcc setFloatValue:acceleration.z];
        
        timeStep++;
        [graph display];

}

-(void)bean:(PTDBean *)bean didUpdateScratchNumber:(NSNumber *)number withValue:(NSData *)data {
        // assume a NULL termiated string
        
        //NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *str = [NSString stringWithUTF8String:[data bytes]];
        NSString *msg = [NSString stringWithFormat:@"received scratch number:%@ scratch:%@", number, str];
        PTDLog(@"%@", msg);
        if (str) {
                [scratchValues replaceObjectAtIndex:number.intValue-1 withObject:str];
        }

        [scratchTable display];
}

- (IBAction) checkScratch:(id)sender {
                for (int i=1;i<=5;i++) {
                        [bean readScratchBank:i];
                        NSLog(@"Read scratch %d\n",i);
                }
}

- (void)updateAll {
        static unsigned long counter = 0;
        
        // wait for bean to connect
        if (bean.state == BeanState_ConnectedAndValidated) {
                [bean readAccelerationAxis];
                if (counter % 10 == 0) { // only check once a second
                        [bean readTemperature];
                }
                if (counter == 0) { // check scratch values on first iteration
                                    // also turn on LED if it is set to ON
                        [self checkScratch:self];
                        if (LEDstate) {
                                [self changeLEDColor:self];
                        }
                }
                counter++;
        }
}

- (IBAction) toggleLED:(id)sender {
        if (LEDstate) { // on now, we want to turn off
                LEDstate = false;
                [onOffLED setTitle:@"Turn On"];
                if (bean.state == BeanState_ConnectedAndValidated) {
                        [bean setLedColor:nil];
                }
        }
        else { // off now, we want to turn on
                [self changeLEDColor:self];
        }
}

- (IBAction) changeLEDColor:(id)sender {
        //NSLog(@"Changing color");
        if (bean.state == BeanState_ConnectedAndValidated) {
                [bean setLedColor:LEDColorWell.color];
        }
        LEDstate = true;
        [onOffLED setTitle:@"Turn Off"];
}

- (IBAction)disconnect:(id)sender {
        
        [threadLock lock]; // Must invalidate timer in a lock?
        [self.updateTimer invalidate];
        [threadLock unlock];

        [beanManager disconnectBean:bean error:nil];
}

@end
