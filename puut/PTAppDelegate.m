//
//  PTAppDelegate.m
//  puut
//
//  Created by Jan-Henrik Bruhn on 09.11.13.
//  Copyright (c) 2013 Jan-Henrik Bruhn. All rights reserved.
//

#import "PTAppDelegate.h"
#import "PTPreferencesWindowController.h"
#import "Constants.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"

@implementation PTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:ShortcutCapture handler:^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MakeScreenshotNotification
                          object:self];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(makeScreenshotNotificationReceived:)
                                                 name:MakeScreenshotNotification
                                               object:nil];
}

-(IBAction)onMakeScreenshotClick:(id)sender {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MakeScreenshotNotification
                      object:self];
}

- (void) makeScreenshotNotificationReceived:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:MakeScreenshotNotification])
        NSLog (@"Notification is successfully received!");
}

- (void) awakeFromNib
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"puut"];
    [statusItem setHighlightMode:YES];
    
}

@end
