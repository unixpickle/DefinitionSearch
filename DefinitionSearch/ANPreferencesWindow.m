//
//  ANPreferencesWindow.m
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import "ANPreferencesWindow.h"
#import "ANAppDelegate.h"

@implementation ANPreferencesWindow

- (id)init {
    NSScreen * mainScreen = [NSScreen mainScreen];
    NSRect windowFrame = NSMakeRect((mainScreen.frame.size.width - 500) / 2,
                                    (mainScreen.frame.size.height - 152) / 2,
                                    500, 152);
    if ((self = [super initWithContentRect:windowFrame
                                 styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                   backing:NSBackingStoreBuffered defer:NO])) {
        self.title = @"Preferences";
        lastIndexDate = [[NSTextField alloc] initWithFrame:NSMakeRect(10, windowFrame.size.height - 34, windowFrame.size.width - 20, 24)];
        lastPartialIndexDate = [[NSTextField alloc] initWithFrame:NSMakeRect(10, windowFrame.size.height - 68, windowFrame.size.width - 20, 24)];
        startStopButton = [[NSButton alloc] initWithFrame:NSMakeRect(5, windowFrame.size.height - 100, 130, 32)];
        cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(135, windowFrame.size.height - 100, 130, 32)];
        progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(10, windowFrame.size.height - 142, windowFrame.size.width - 20, 32)];
        
        [lastIndexDate setBackgroundColor:[NSColor clearColor]];
        [lastPartialIndexDate setBackgroundColor:[NSColor clearColor]];
        [lastIndexDate setSelectable:NO];
        [lastPartialIndexDate setSelectable:NO];
        [lastIndexDate setBordered:NO];
        [lastPartialIndexDate setBordered:NO];
        
        [progressIndicator setMinValue:0];
        [progressIndicator setMaxValue:1];
        [progressIndicator setStyle:NSProgressIndicatorBarStyle];
        [progressIndicator setIndeterminate:NO];
        [progressIndicator setDoubleValue:0];
        
        [startStopButton setBezelStyle:NSRoundedBezelStyle];
        [cancelButton setBezelStyle:NSRoundedBezelStyle];
        [startStopButton setFont:[NSFont systemFontOfSize:13]];
        [cancelButton setFont:[NSFont systemFontOfSize:13]];
        [startStopButton setTarget:self];
        [cancelButton setTarget:self];
        [startStopButton setAction:@selector(startPressed:)];
        [cancelButton setAction:@selector(cancelPressed:)];
        
        [self.contentView addSubview:lastIndexDate];
        [self.contentView addSubview:lastPartialIndexDate];
        [self.contentView addSubview:startStopButton];
        [self.contentView addSubview:cancelButton];
        [self.contentView addSubview:progressIndicator];
        
        indexManager = [ANDictionaryIndexManager sharedIndexManager];
        indexManager.delegate = self;
        [self updateStatistics];
    }
    return self;
}

- (void)updateStatistics {
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    ANDictionaryIndex * index = [(ANAppDelegate *)[NSApplication sharedApplication].delegate dictionaryIndex];
    NSString * lastIndexString = [NSString stringWithFormat:@"Last indexed on %@", [dateFormatter stringFromDate:[index creationDate]]];
    [lastIndexDate setStringValue:lastIndexString];
    if ([indexManager isIndexing]) {
        [lastPartialIndexDate setStringValue:@"Indexing ..."];
        [startStopButton setTitle:@"Pause Index"];
        [cancelButton setTitle:@"Cancel Index"];
        [cancelButton setHidden:NO];
        [progressIndicator setHidden:NO];
        [progressIndicator setDoubleValue:indexManager.indexProgress];
    } else if ([indexManager cachedIndexExists]) {
        NSString * partialStr = [NSString stringWithFormat:@"Partial index started on %@", [dateFormatter stringFromDate:[indexManager indexStart]]];
        [lastPartialIndexDate setStringValue:partialStr];
        [startStopButton setTitle:@"Resume Index"];
        [cancelButton setTitle:@"Restart Index"];
        [cancelButton setHidden:NO];
        [progressIndicator setHidden:YES];
    } else {
        [lastPartialIndexDate setStringValue:@"Not currently indexing"];
        [startStopButton setTitle:@"Start Index"];
        [cancelButton setHidden:YES];
        [progressIndicator setHidden:YES];
    }
}

- (void)startPressed:(id)sender {
    if ([indexManager isIndexing]) {
        [indexManager pauseIndexing];
    } else {
        [indexManager startIndexing];
        [progressIndicator startAnimation:self];
    }
    [self updateStatistics];
}

- (void)cancelPressed:(id)sender {
    if ([indexManager isIndexing]) {
        [indexManager terminateIndexing];
        [progressIndicator stopAnimation:self];
    } else if ([indexManager cachedIndexExists]) {
        [indexManager terminateIndexing];
        [indexManager startIndexing];
        [progressIndicator startAnimation:self];
    }
    [self updateStatistics];
}

#pragma mark - Index Manager -

- (void)indexManager:(ANDictionaryIndexManager *)manager indexedToPath:(NSString *)tempPath {
    ANAppDelegate * delegate = (ANAppDelegate *)[[NSApplication sharedApplication] delegate];
    ANDictionaryIndex * index = delegate.dictionaryIndex;
    delegate.dictionaryIndex = nil;
    [index close];
    [[NSFileManager defaultManager] removeItemAtPath:[delegate indexSavePath]
                                               error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:tempPath
                                            toPath:[delegate indexSavePath]
                                             error:nil];
    delegate.dictionaryIndex = [[ANDictionaryIndex alloc] initWithFile:[delegate indexSavePath]];
    delegate.dictionaryIndex.delegate = delegate;
    [delegate searchPressed:nil];
    [manager terminateIndexing];
    [self updateStatistics];
}

- (void)indexManagerProgressUpdate:(ANDictionaryIndexManager *)manager {
    [self updateStatistics];
}

@end
