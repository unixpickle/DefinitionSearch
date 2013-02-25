//
//  ANAppDelegate.h
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ANDictionaryIndex.h"
#import "ANPreferencesWindow.h"

@interface ANAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, ANDictionaryIndexDelegate> {
    ANDictionaryIndex * dictionaryIndex;
    ANPreferencesWindow * preferencesWindow;
    
    IBOutlet NSSearchField * searchField;
    IBOutlet NSTableView * tableView;
    
    NSArray * results;
}

@property (assign) IBOutlet NSWindow * window;
@property (nonatomic, retain) ANDictionaryIndex * dictionaryIndex;

- (NSString *)indexSavePath;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)searchPressed:(id)sender;

@end
