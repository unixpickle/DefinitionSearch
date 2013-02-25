//
//  ANPreferencesWindow.h
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ANDictionaryIndex.h"
#import "ANDictionaryIndexManager.h"

@interface ANPreferencesWindow : NSWindow <ANDictionaryIndexManagerDelegate> {
    ANDictionaryIndexManager * indexManager;
    NSTextField * lastIndexDate;
    NSTextField * lastPartialIndexDate;
    NSButton * startStopButton;
    NSButton * cancelButton;
    NSProgressIndicator * progressIndicator;
}

- (void)updateStatistics;

- (void)startPressed:(id)sender;
- (void)cancelPressed:(id)sender;

@end
