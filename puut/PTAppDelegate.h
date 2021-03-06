//
//  PTAppDelegate.h
//  puut
//
//  Created by Jan-Henrik Bruhn on 09.11.13.
//  Copyright (c) 2013 Jan-Henrik Bruhn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MASShortcutView.h>

#import <FXKeychain.h>

@interface PTAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    FXKeychain *keychain;
}

- (IBAction)onMakeScreenshotClick:(id)sender;

@end
