//
//  _LNIPCRemoteBlockRegistry.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class _LNIPCDistantObject;

NS_ASSUME_NONNULL_BEGIN

@interface _LNIPCRemoteBlockRegistry : NSObject

+ (NSString*)registerRemoteBlock:(id)block distantObject:(nullable _LNIPCDistantObject*)distantObject;
+ (id)remoteBlockForIdentifier:(NSString*)identifier distantObject:(out _LNIPCDistantObject* __nullable * __nullable)distantObject;
+ (oneway void)retainRemoteBlock:(NSString*)identifier;
+ (oneway void)releaseRemoteBlock:(NSString*)identifier;

@end

NS_ASSUME_NONNULL_END
