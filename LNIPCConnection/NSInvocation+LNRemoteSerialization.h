//
//  NSInvocation+LNRemoteSerialization.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LNIPCConnection;
@class _LNIPCDistantObject;

NS_ASSUME_NONNULL_BEGIN

extern void* _LNRemoteBlockIdentifierKey;

@interface NSInvocation (LNRemoteSerialization)

- (NSDictionary*)_ln_serializedDictionaryForDistantObject:(nullable _LNIPCDistantObject*)distantObject;

+ (instancetype)_ln_invocationWithSerializedDictionary:(NSDictionary*)serialized remoteConnection:(LNIPCConnection*)connection;

@end

NS_ASSUME_NONNULL_END
