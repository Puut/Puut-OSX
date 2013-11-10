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

#import "NSData+Base64.h"

#import <MASShortcutView.h>
#import <MASShortcutView+UserDefaults.h>
#import <MASShortcut+UserDefaults.h>
#import <MASShortcut+Monitoring.h>

#import <AFNetworking.h>

#import <FXKeychain.h>

@implementation PTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self->keychain = [[FXKeychain alloc] initWithService:[[NSBundle mainBundle] bundleIdentifier] accessGroup:@"" accessibility:FXKeychainAccessibleAfterFirstUnlock];

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
    if ([[notification name] isEqualToString:MakeScreenshotNotification]) {
        NSLog (@"Notification is successfully received!");
        NSString *screenshotPath = [self makeAreaScreenshot];
        [self uploadScreenshotWithFilePath:screenshotPath];
    }
}

- (void) uploadScreenshotWithFilePath:(NSString*)path {
    NSURL *fileURL = [NSURL URLWithString:path];
    
    NSDictionary *settingsDictionary = nil;
    settingsDictionary = [keychain objectForKey: KeychainDictionaryKey];
    
    NSString *host = settingsDictionary[KeychainDictionaryURLKey];
    NSString *username = settingsDictionary[KeychainDictionaryUsernameKey];
    NSString *password = settingsDictionary[KeychainDictionaryPasswordKey];
    
    NSString *hostWithPath = [host stringByAppendingString:@"upload"];
    
    [self uploadFileWithFileURL:fileURL hostUrl:[NSURL URLWithString:hostWithPath] username:username password:password finished:^(NSString *imageId) {
        NSString *imageUrl = [[host stringByAppendingString:imageId] stringByAppendingString:@".png"];
        NSLog(@"URL: %@", imageUrl);
        [self showUploadedNotificationWithUrl: imageUrl];
        [self setPasteboardWithString: imageUrl];
    }];
}

- (void) showUploadedNotificationWithUrl:(NSString*) url {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Your Screenshot was uploaded!";
    notification.informativeText = [@"The URL is " stringByAppendingString:url];
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void) setPasteboardWithString:(NSString*) contents {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard clearContents];
    [pasteboard setString:contents forType:NSStringPboardType];
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

- (void) uploadFileWithFileURL: (NSURL*)filePath hostUrl:(NSURL*)url username:(NSString*)username password:(NSString*)password finished:( void ( ^ )( NSString* ) )finished{

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:[url absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:[NSData dataWithContentsOfFile:[filePath absoluteString]] name:@"image" fileName:@"image.png" mimeType:@"image/png"];
    }];
    
    if(username != nil && ![username isEqualToString:@""]) {
        NSString *loginString = [@"" stringByAppendingFormat:@"%@:%@", username, password];
        NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", [[loginString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString]];
        [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    AFHTTPRequestOperation *op = [manager HTTPRequestOperationWithRequest:request success: ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
        finished(JSON[@"id"]);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    [[NSOperationQueue mainQueue] addOperation:op];
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
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setImage:[NSImage imageNamed: @"status_bar_icon.png"]];
    [statusItem setHighlightMode:YES];
    
}

@end
