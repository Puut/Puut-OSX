//
//  PTPreferencesViewController.h
//  puut
//
//  Created by Jan-Henrik Bruhn on 09.11.13.
//  Copyright (c) 2013 Jan-Henrik Bruhn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASShortcutView.h"

@interface PTPreferencesWindowController : NSWindowController {
}

@property (nonatomic, weak) IBOutlet MASShortcutView *shortcutView;
@property (nonatomic, weak) IBOutlet NSTextField *serverUrlTextField;
@property (nonatomic, weak) IBOutlet NSTextField *serverUsernameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *serverPasswordTextField;
@property (nonatomic, weak) IBOutlet NSButton *serverAuthEnabledButton;
@property (nonatomic, weak) IBOutlet NSButton *applyButton;

-(IBAction) applyButtonClicked:(id)selector;
-(IBAction) serverAuthEnabledButtonClicked:(id)selector;

@end
