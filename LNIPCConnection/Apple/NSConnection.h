//
//  NSConnection.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/24/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

NS_AUTOMATED_REFCOUNT_WEAK_UNAVAILABLE
NS_ASSUME_NONNULL_BEGIN

@interface NSConnection : NSObject

- (void)run;

@property (nullable, retain) id rootObject;
@property (readonly, getter=isValid) BOOL valid;

@property (readonly, retain) id rootProxy;

- (void)invalidate;

+ (nullable instancetype)connectionWithRegisteredName:(NSString *)name host:(nullable NSString *)hostName;
+ (nullable instancetype)connectionWithReceivePort:(nullable NSPort *)receivePort sendPort:(nullable NSPort *)sendPort;

- (BOOL)registerName:(nullable NSString *) name;

- (void)addRunLoop:(NSRunLoop *)runloop;
- (void)removeRunLoop:(NSRunLoop *)runloop;
- (void)runInNewThread;

@end

FOUNDATION_EXPORT NSString * const NSConnectionDidDieNotification;

NS_ASSUME_NONNULL_END