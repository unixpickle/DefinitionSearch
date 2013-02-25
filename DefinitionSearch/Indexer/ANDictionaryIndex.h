//
//  ANDictionaryIndex.h
//  DefinitionSearch
//
//  Created by Alex Nichol on 2/24/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANSQLite3Manager.h"

@class ANDictionaryIndex;

@protocol ANDictionaryIndexDelegate <NSObject>

- (void)dictionaryIndex:(ANDictionaryIndex *)index foundWords:(NSArray *)results;

@end

@interface ANDictionaryIndex : NSObject {
    ANSQLite3Manager * database;
    NSLock * managerLock;
    NSThread * backgroundThread;
    
    __weak id<ANDictionaryIndexDelegate> delegate;
    NSDate * creationDate;
}

@property (nonatomic, weak) id<ANDictionaryIndexDelegate> delegate;
@property (readonly) NSDate * creationDate;

- (id)initWithFile:(NSString *)filePath;
- (void)searchTermDefinition:(NSString *)definition;
- (void)close;

@end
