//
//  PTPreferencesViewController.m
//  puut
//
//  Created by Jan-Henrik Bruhn on 09.11.13.
//  Copyright (c) 2013 Jan-Henrik Bruhn. All rights reserved.
//

#import "PTPreferencesWindowController.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"
#import "Constants.h"

@interface PTPreferencesWindowController ()

@end

@implementation PTPreferencesWindowController

- (id)init {
    if(self = [super initWithWindowNibName:@"PreferencesWindow"]) {
    }
    return self;
}

-(void)windowDidLoad {
    [super windowDidLoad];
    self.shortcutView.associatedUserDefaultsKey = ShortcutCapture;
}

-(IBAction)applyButtonClicked:(id)selector {
    [self close];
}

-(IBAction)serverAuthEnabledButtonClicked:(id)selector {
    
}

@end
