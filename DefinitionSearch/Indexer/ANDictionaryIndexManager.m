//
//  ANDictionaryIndexManager.m
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import "ANDictionaryIndexManager.h"

@interface ANDictionaryIndexManager (Private)

- (NSString *)cachedIndexPath;
- (void)backgroundThread;
- (void)awaitBackgroundDeath;
- (void)updateCompleted:(int)completed inDatabase:(ANSQLite3Manager *)manager;
- (void)notifyDelegateProgressUpdate;
- (void)notifyDelegateComplete;

@end

@implementation ANDictionaryIndexManager

@synthesize delegate;

+ (ANDictionaryIndexManager *)sharedIndexManager {
    static ANDictionaryIndexManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ANDictionaryIndexManager alloc] init];
    });
    return manager;
}

- (id)init {
    if ((self = [super init])) {
        statLock = [[NSLock alloc] init];
        NSString * path = [self cachedIndexPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            ANSQLite3Manager * manager = [[ANSQLite3Manager alloc] initWithDatabaseFile:path];
            NSArray * stats = [manager executeQuery:@"select date, dictIndex, dictTotal from stats;"];
            NSAssert([stats count] == 1, @"There must be one stats row in the index.");
            NSDictionary * statInfo = [stats lastObject];
            NSTimeInterval epoch = [[statInfo objectForKey:@"date"] doubleValue];
            indexStart = [NSDate dateWithTimeIntervalSince1970:epoch];
            indexDictionaryIndex = [[statInfo objectForKey:@"dictIndex"] intValue];
            indexDictionaryTotal = [[statInfo objectForKey:@"dictTotal"] intValue];
            cachedIndexExists = YES;
            [manager closeDatabase];
        }
    }
    return self;
}

- (BOOL)isIndexing {
    return (indexThread != nil);
}

- (float)indexProgress {
    if (indexDictionaryTotal == 0) return 0;
    [statLock lock];
    float value = (float)indexDictionaryIndex / (float)indexDictionaryTotal;
    [statLock unlock];
    return value;
}

- (BOOL)cachedIndexExists {
    BOOL flag;
    [statLock lock];
    flag = cachedIndexExists;
    [statLock unlock];
    return flag;
}

- (NSDate *)indexStart {
    NSDate * d;
    [statLock lock];
    d = indexStart;
    [statLock unlock];
    return d;
}

#pragma mark - Control -

- (void)startIndexing {
    if (indexThread) return;
    backgroundRunning = YES;
    indexThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(backgroundThread)
                                            object:nil];
    [indexThread start];
}

- (void)terminateIndexing {
    if (indexThread) {
        [indexThread cancel];
        indexThread = nil;
        [self awaitBackgroundDeath];
    }
    [[NSFileManager defaultManager] removeItemAtPath:[self cachedIndexPath]
                                               error:nil];
    [statLock lock];
    indexDictionaryIndex = 0;
    indexDictionaryTotal = 0;
    cachedIndexExists = NO;
    [statLock unlock];
}

- (void)pauseIndexing {
    [indexThread cancel];
    indexThread = nil;
    [self awaitBackgroundDeath];
}

#pragma mark - Private -

- (NSString *)cachedIndexPath {
    NSString * appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString * appPath = [NSString stringWithFormat:@"%@/index_cache.db", appName];
    return [appSupport stringByAppendingPathComponent:appPath];
}

#pragma mark Background Thread

- (void)backgroundThread {
    @autoreleasepool {
        ANSQLite3Manager * manager = [[ANSQLite3Manager alloc] initWithDatabaseFile:[self cachedIndexPath]];
        NSString * dictPath = [[NSBundle mainBundle] pathForResource:@"dictionary" ofType:@"txt"];
        NSArray * wordList = [[NSString stringWithContentsOfFile:dictPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil] componentsSeparatedByString:@"\n"];
        int startIndex = 0;
        [statLock lock];
        if (cachedIndexExists) {
            startIndex = indexDictionaryIndex;
        } else {
            // create the database tables
            NSDate * now = [NSDate date];
            [manager executeQuery:@"create table if not exists definitions (id INTEGER NOT NULL, term VARCHAR(32), definition TEXT, PRIMARY KEY (id), UNIQUE (id))"];
            [manager executeQuery:@"create table if not exists stats (id INTEGER NOT NULL, date REAL NOT NULL, dictIndex INTEGER NOT NULL, dictTotal INTEGER NOT NULL, PRIMARY KEY (id), UNIQUE (id))"];
            NSArray * statInfo = @[[NSNumber numberWithDouble:[now timeIntervalSince1970]],
                                   [NSNumber numberWithInt:(int)[wordList count]]];
            [manager executeQuery:@"INSERT INTO stats (date, dictIndex, dictTotal) VALUES (?, 0, ?)"
                   withParameters:statInfo];
            indexStart = now;
        }
        indexDictionaryTotal = (int)[wordList count];
        [statLock unlock];
        
        for (int i = startIndex; i < indexDictionaryTotal; i++) {
            NSString * word = [wordList objectAtIndex:i];
            CFStringRef str = DCSCopyTextDefinition(NULL, (__bridge CFStringRef)word, CFRangeMake(0, [word length]));
            NSString * string = (__bridge_transfer NSString *)str;
            if ([string length] == 0 || !string) {
                continue;
            }
            [manager executeQuery:@"INSERT INTO definitions (term, definition) VALUES (?, ?)"
                   withParameters:[NSArray arrayWithObjects:word, string, nil]];
            if (i % 50 == 0) {
                if ([[NSThread currentThread] isCancelled]) {
                    [self updateCompleted:i inDatabase:manager];
                    [manager closeDatabase];
                    [statLock lock];
                    backgroundRunning = NO;
                    cachedIndexExists = YES;
                    [statLock unlock];
                    return;
                }
                if (i % 1000 == 0) {
                    [self updateCompleted:i inDatabase:manager];
                    [self performSelectorOnMainThread:@selector(notifyDelegateProgressUpdate) withObject:nil waitUntilDone:NO];
                }
            }
        }
        
        [self updateCompleted:indexDictionaryTotal inDatabase:manager];
        [manager closeDatabase];
        [statLock lock];
        backgroundRunning = NO;
        cachedIndexExists = YES;
        [statLock unlock];
        
        if (![[NSThread currentThread] isCancelled]) {
            [self performSelectorOnMainThread:@selector(notifyDelegateComplete) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)awaitBackgroundDeath {
    while (true) {
        [statLock lock];
        BOOL flag = backgroundRunning;
        [statLock unlock];
        if (!flag) break;
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void)updateCompleted:(int)completed inDatabase:(ANSQLite3Manager *)manager {
    [manager executeQuery:@"UPDATE stats SET dictIndex=? WHERE 1"
           withParameters:@[[NSNumber numberWithInt:indexDictionaryIndex]]];
    [statLock lock];
    indexDictionaryIndex = completed;
    [statLock unlock];
}

- (void)notifyDelegateProgressUpdate {
    if ([delegate respondsToSelector:@selector(indexManagerProgressUpdate:)]) {
        [delegate indexManagerProgressUpdate:self];
    }
}

- (void)notifyDelegateComplete {
    if ([delegate respondsToSelector:@selector(indexManager:indexedToPath:)]) {
        [delegate indexManager:self indexedToPath:[self cachedIndexPath]];
    }
}

@end
