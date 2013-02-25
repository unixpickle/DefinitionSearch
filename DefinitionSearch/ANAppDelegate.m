//
//  ANAppDelegate.m
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import "ANAppDelegate.h"

@implementation ANAppDelegate

@synthesize dictionaryIndex;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString * appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString * appDir = [appSupport stringByAppendingPathComponent:appName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:appDir
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSRect frame = [[NSScreen mainScreen] frame];
    NSRect windowFrame = self.window.frame;
    windowFrame.origin.x = (frame.size.width - windowFrame.size.width) / 2;
    windowFrame.origin.y = (frame.size.height - windowFrame.size.height) / 2;
    [self.window setFrame:windowFrame display:YES];
    
    // load the index
    NSString * path = [self indexSavePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        dictionaryIndex = [[ANDictionaryIndex alloc] initWithFile:path];
    } else {
        NSString * resourceIndex = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"db"];
        [[NSFileManager defaultManager] copyItemAtPath:resourceIndex
                                                toPath:path
                                                 error:nil];
        dictionaryIndex = [[ANDictionaryIndex alloc] initWithFile:path];
    }
    
    preferencesWindow = [[ANPreferencesWindow alloc] init];
    [preferencesWindow setReleasedWhenClosed:NO];
    dictionaryIndex.delegate = self;
}

- (NSString *)indexSavePath {
    NSString * appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString * appPath = [NSString stringWithFormat:@"%@/index.db", appName];
    return [appSupport stringByAppendingPathComponent:appPath];
}

- (IBAction)showPreferencesWindow:(id)sender {
    [preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)searchPressed:(id)sender {
    [dictionaryIndex searchTermDefinition:[searchField stringValue]];
}

#pragma mark - Index Delegate -

- (void)dictionaryIndex:(ANDictionaryIndex *)index foundWords:(NSArray *)theResults {
    results = theResults;
    [tableView reloadData];
}

#pragma mark - Table View -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [results count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [results objectAtIndex:row];
}

@end
