//
//  _LNIPCExportedObject.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LNIPCConnection;
@class LNIPCInterface;

NS_ASSUME_NONNULL_BEGIN

@interface _LNIPCExportedObject : NSObject

+ (instancetype)_exportedObjectWithObject:(id)object connection:(LNIPCConnection*)connection serializedInvocation:(NSDictionary*)serializedInvocation;

- (oneway void)invoke;

@end

NS_ASSUME_NONNULL_END
