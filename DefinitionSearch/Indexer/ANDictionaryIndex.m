//
//  ANDictionaryIndex.m
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import "ANDictionaryIndex.h"

@interface ANDictionaryIndex (Private)

- (void)backgroundSearchMethod:(NSString *)def;
- (void)notifyDelegateResults:(NSArray *)results;

@end

@implementation ANDictionaryIndex

@synthesize delegate;
@synthesize creationDate;

- (id)initWithFile:(NSString *)filePath {
    if ((self = [super init])) {
        database = [[ANSQLite3Manager alloc] initWithDatabaseFile:filePath];
        managerLock = [[NSLock alloc] init];
        NSArray * results = [database executeQuery:@"select date from stats;"];
        if ([results count] == 1) {
            NSDictionary * stat = [results objectAtIndex:0];
            NSTimeInterval interval = [[stat objectForKey:@"date"] doubleValue];
            creationDate = [NSDate dateWithTimeIntervalSince1970:interval];
        }
    }
    return self;
}

- (void)searchTermDefinition:(NSString *)definition {
    [backgroundThread cancel];
    backgroundThread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(backgroundSearchMethod:)
                                                 object:definition];
    [backgroundThread start];
}

- (void)close {
    if (backgroundThread) {
        [backgroundThread cancel];
        backgroundThread = nil;
    }
    [managerLock lock];
    [database closeDatabase];
    database = nil;
    [managerLock unlock];
}

#pragma mark - Private -

- (void)backgroundSearchMethod:(NSString *)def {
    @autoreleasepool {
        if ([def length] == 0) {
            [self performSelectorOnMainThread:@selector(notifyDelegateResults:)
                                   withObject:@[]
                                waitUntilDone:NO];
            return;
        }
        [managerLock lock];
        NSString * query = [NSString stringWithFormat:@"%%%@%%", def];
        NSArray * results = [database executeQuery:@"select term from definitions where (definition like ?);"
                                    withParameters:@[query]];
        [managerLock unlock];
        if ([[NSThread currentThread] isCancelled]) return;
        NSMutableArray * termArray = [NSMutableArray array];
        for (NSDictionary * termInfo in results) {
            [termArray addObject:[termInfo objectForKey:@"term"]];
            if ([termArray count] > 1000) break;
        }
        [self performSelectorOnMainThread:@selector(notifyDelegateResults:)
                               withObject:termArray
                            waitUntilDone:NO];
    }
}

- (void)notifyDelegateResults:(NSArray *)results {
    [delegate dictionaryIndex:self foundWords:results];
    backgroundThread = nil;
}

@end
