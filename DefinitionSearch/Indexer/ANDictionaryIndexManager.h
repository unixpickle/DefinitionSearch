//
//  ANDictionaryIndexManager.h
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "ANSQLite3Manager.h"

@class ANDictionaryIndexManager;

@protocol ANDictionaryIndexManagerDelegate <NSObject>

@optional
- (void)indexManager:(ANDictionaryIndexManager *)manager indexedToPath:(NSString *)tempPath;
- (void)indexManagerProgressUpdate:(ANDictionaryIndexManager *)manager;

@end

@interface ANDictionaryIndexManager : NSObject {
    NSLock * statLock;
    NSDate * indexStart;
    int indexDictionaryIndex;
    int indexDictionaryTotal;
    BOOL cachedIndexExists;
    
    NSThread * indexThread;
    BOOL backgroundRunning;
    
    __weak id<ANDictionaryIndexManagerDelegate> delegate;
}

@property (nonatomic, weak) id<ANDictionaryIndexManagerDelegate> delegate;

+ (ANDictionaryIndexManager *)sharedIndexManager;

- (BOOL)isIndexing;
- (float)indexProgress;

- (BOOL)cachedIndexExists;
- (NSDate *)indexStart;

- (void)startIndexing;
- (void)terminateIndexing;
- (void)pauseIndexing;

@end
