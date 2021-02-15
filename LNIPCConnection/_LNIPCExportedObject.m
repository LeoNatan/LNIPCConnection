//
//  _LNIPCExportedObject.m
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import "_LNIPCExportedObject.h"
#import "NSInvocation+LNRemoteSerialization.h"

@implementation _LNIPCExportedObject
{
	id _target;
	LNIPCConnection* _connection;
	NSInvocation* _invocation;
}

+ (instancetype)_exportedObjectWithObject:(id)object connection:(LNIPCConnection*)connection serializedInvocation:(NSDictionary*)serializedInvocation
{
	_LNIPCExportedObject* local = [_LNIPCExportedObject new];
	if(self)
	{
		local->_connection = connection;
		local->_target = object;
		local->_invocation = [NSInvocation _ln_invocationWithSerializedDictionary:serializedInvocation remoteConnection:local->_connection];
		[local->_invocation retainArguments];
		if([local->_invocation isKindOfClass:NSClassFromString(@"NSBlockInvocation")] == NO)
		{
			local->_invocation.target = local->_target;
		}
	}
	return local;
}

- (oneway void)invoke
{
	[_invocation invoke];
}

@end
