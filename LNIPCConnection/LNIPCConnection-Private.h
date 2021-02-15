//
//  LNIPCConnection-Private.h
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import "LNIPCConnection.h"

@protocol _LNIPCImpl <NSObject>

- (oneway void)_slaveDidConnectWithName:(NSString*)slaveServiceName;
- (oneway void)_invokeFromRemote:(NSDictionary*)serializedInvocation;
- (oneway void)_invokeRemoteBlock:(NSDictionary*)serializedBlock;
- (oneway void)_cleanupRemoteBlock:(NSString*)identifier;
- (BOOL)_ping;

@end

@interface LNIPCConnection ()

@property (readonly, getter=isValid) BOOL valid;

@property (nonatomic, getter=isSlave) BOOL slave;

@property (nonatomic, strong) NSConnection* connection;
@property (nonatomic, strong) NSConnection* otherConnection;

@end
