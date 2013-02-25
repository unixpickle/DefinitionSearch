//
//  ANSQLite3Manager.h
//  ANSQLite
//
//  Created by Alex Nichol on 11/19/10.
//  Copyright 2010 Jitsik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface ANSQLite3Manager : NSObject {
	sqlite3 * database;
}

@property (readonly) sqlite3 * database;

- (id)initWithDatabaseFile:(NSString *)filename;
- (BOOL)openDatabaseFile:(NSString *)filename;
- (NSArray *)executeQuery:(NSString *)query;
- (NSArray *)executeQuery:(NSString *)query withParameters:(NSArray *)params;
- (UInt64)lastInsertRowID;
- (void)closeDatabase;

@end
