//
//  PTPreferencesViewController.m
//  puut
//
//  Created by Jan-Henrik Bruhn on 09.11.13.
//  Copyright (c) 2013 Jan-Henrik Bruhn. All rights reserved.
//

#import "PTPreferencesWindowController.h"

#import "NSData+Base64.h"

#import <MASShortcutView.h>
#import <MASShortcutView+UserDefaults.h>
#import <MASShortcut+UserDefaults.h>
#import <MASShortcut+Monitoring.h>

#import <FXKeychain.h>

#import <AFNetworking.h>

#import "Constants.h"

@interface PTPreferencesWindowController ()

@end

@implementation PTPreferencesWindowController

@synthesize serverUrlTextField;
@synthesize serverUsernameTextField;
@synthesize serverPasswordTextField;
@synthesize serverAuthEnabledCheckbox;
@synthesize progressIndicator;

- (id)init {
    if(self = [super initWithWindowNibName:@"PreferencesWindow"]) {
        self->keychain = [[FXKeychain alloc] initWithService:[[NSBundle mainBundle] bundleIdentifier] accessGroup:@"" accessibility:FXKeychainAccessibleAfterFirstUnlock];
    }
    return self;
}

-(void)windowDidLoad {
    [super windowDidLoad];
    
    self.shortcutView.associatedUserDefaultsKey = ShortcutCapture;
    
    NSDictionary *settingsDictionary = [keychain objectForKey: KeychainDictionaryKey];
    
    if(!settingsDictionary)
        settingsDictionary = [[NSDictionary alloc] init];

    [serverUrlTextField setStringValue:
     [settingsDictionary objectForKey:KeychainDictionaryURLKey]];
    
    [serverUsernameTextField setStringValue:
     [settingsDictionary objectForKey:KeychainDictionaryUsernameKey]];
    
    [serverPasswordTextField setStringValue:
     [settingsDictionary objectForKey:KeychainDictionaryPasswordKey]];
    
    BOOL authEnabled = [[settingsDictionary objectForKey:KeychainDictionaryAuthEnabledKey]
                        isEqual: @"YES"];

    if(authEnabled) {
        [serverAuthEnabledCheckbox setState:NSOnState];
    } else {
        [serverAuthEnabledCheckbox setState:NSOffState];
    }
    
    [self updateAuthFieldState];
 }

-(IBAction)applyButtonClicked:(id)selector {
    NSString *urlString = [serverUrlTextField stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *username = [serverUsernameTextField stringValue];
    NSString *password = [serverPasswordTextField stringValue];
    
    [progressIndicator startAnimation:self];
    
    bool invalid = url == nil || ![[[NSArray alloc] initWithObjects:@"http", @"https", nil ] containsObject:[url scheme]];
    if(invalid) {
        [self showErrorInvalidURL];
    } else {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[urlString stringByAppendingString: @"/info"] parameters:nil];
        
        if(username != nil && ![username isEqualToString:@""]) {
            NSString *loginString = [@"" stringByAppendingFormat:@"%@:%@", username, password];
            NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", [[loginString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString]];
            [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
        }
        
        AFHTTPRequestOperation *op = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [progressIndicator stopAnimation:self];

            [self close];

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            [progressIndicator stopAnimation:self];

            [self showErrorInvalidURL];
        }];
        op.responseSerializer = [AFHTTPResponseSerializer serializer];
        [[NSOperationQueue mainQueue] addOperation:op];
    }
}

- (void) saveSettings {
    NSDictionary *settingsDictionary = @{
                                         KeychainDictionaryURLKey: [serverUrlTextField stringValue],
                                         KeychainDictionaryUsernameKey: [serverUsernameTextField stringValue],
                                         KeychainDictionaryPasswordKey: [serverPasswordTextField stringValue],
                                         KeychainDictionaryAuthEnabledKey: [serverAuthEnabledCheckbox state] == NSOnState ? @"YES" : @"NO"
                                        };
        
    [keychain setObject:settingsDictionary forKey:KeychainDictionaryKey];
}

- (void) showErrorInvalidURL {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setMessageText:@"The URL is malformed."];
    [alert setInformativeText:@"Please check the URL and Login-Data you inputted."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];

}

- (void) alertDidEnd:(NSAlert *)a returnCode:(NSInteger)rc contextInfo:(void *)ci {
}

-(IBAction)serverAuthEnabledButtonClicked:(id)selector {
    [self updateAuthFieldState];
}

-(void)updateAuthFieldState {
    if([serverAuthEnabledCheckbox state] == NSOnState) {
        [serverUsernameTextField setEnabled:true];
        [serverPasswordTextField setEnabled:true];
    } else {
        [serverUsernameTextField setEnabled:false];
        [serverPasswordTextField setEnabled:false];
    }
}

@end
