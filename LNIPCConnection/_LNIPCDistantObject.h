//
//  _LNIPCDistantObject.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/24/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LNIPCConnection;
@class _LNIPCExportedObject;

NS_ASSUME_NONNULL_BEGIN

@interface _LNIPCDistantObject : NSObject

+ (instancetype)_distantObjectWithConnection:(LNIPCConnection*)connection synchronous:(BOOL)synchronous errorBlock:(void(^ __nullable)(NSError*))errorBlock;
- (void)_enterReplyBlock;
- (void)_leavelReplyBlock;
- (BOOL)_enqueueSynchronousExportedObjectInvocation:(_LNIPCExportedObject*)object;

@property (nonatomic, readonly, getter=isSynchronous) BOOL synchronous;

@end

NS_ASSUME_NONNULL_END
