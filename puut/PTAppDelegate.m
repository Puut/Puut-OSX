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

#import <MASShortcutView.h>
#import <MASShortcutView+UserDefaults.h>
#import <MASShortcut+UserDefaults.h>
#import <MASShortcut+Monitoring.h>

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
        NSLog (@"Notification is successfully received!, %@", [self makeAreaScreenshot]);
}

- (void) runProcessWithProcessName: (NSString*)processName processArguments:(NSArray*) arguments {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: processName];

    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

- (NSString*) makeAreaScreenshot {
    NSString *tempFileName = [self getTemporaryFilename];

    [self runProcessWithProcessName: @"/usr/sbin/screencapture" processArguments:[NSArray arrayWithObjects: @"-i", tempFileName, nil]];
    
    return tempFileName;
}

- (NSString*) getTemporaryFilename {
    NSString *tempFileTemplate =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"upload.XXXXXX"];
    
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
   
    char *tempFileNameCString = (char *) malloc(strlen(tempFileTemplateCString) + 1);
    
    strcpy(tempFileNameCString, tempFileTemplateCString);
    
    int fileDescriptor = mkstemp(tempFileNameCString);
    
    if (fileDescriptor == -1)
    {
        return @"";
    }
    
    NSString *tempFileName =
    [[NSFileManager defaultManager]
        stringWithFileSystemRepresentation:tempFileNameCString
                                    length:strlen(tempFileNameCString)];
    
    free(tempFileNameCString);
    
    return tempFileName;
}

- (void) awakeFromNib
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"puut"];
    [statusItem setHighlightMode:YES];
    
}

@end
