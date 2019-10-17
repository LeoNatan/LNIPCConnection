//
//  _DTXIPCExportedObject.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/25/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXIPCConnection;
@class DTXIPCInterface;

NS_ASSUME_NONNULL_BEGIN

@interface _DTXIPCExportedObject : NSObject

+ (instancetype)_exportedObjectWithObject:(id)object connection:(DTXIPCConnection*)connection serializedInvocation:(NSDictionary*)serializedInvocation;

- (oneway void)invoke;

@end

NS_ASSUME_NONNULL_END
