//
//  LNIPCConnection.m
//  LNIPCConnection
//
//  Created by Leo Natan on 9/24/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import "LNIPCConnection-Private.h"
#import "NSConnection.h"
#import "NSPortNameServer.h"
#import "ObjCRuntime.h"
#import "_LNIPCDistantObject.h"
#import "_LNIPCExportedObject.h"
#import "_LNIPCRemoteBlockRegistry.h"
@import ObjectiveC;

NSErrorDomain const LNIPCErrorDomain = @"LNIPCErrorDomain";

@interface LNIPCInterface ()

@property (nonatomic, readwrite) Protocol* protocol;
@property (nonatomic, strong) NSDictionary<NSString*, NSMethodSignature*>* selectoToSignature;
@property (nonatomic, strong, readwrite) NSArray<NSMethodSignature*>* methodSignatures;

@end

@implementation LNIPCInterface
{
	struct objc_method_description* _methodList;
	unsigned int _methodListCount;
}

static void _LNAddSignatures(Protocol* protocol, NSMutableArray* signatures, NSMutableDictionary* map)
{
	unsigned int count = 0;
	{
		objc_property_t* unsupported = protocol_copyPropertyList2(protocol, &count, YES, YES);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Properties are not suppoerted."];
		}
	}
	{
		objc_property_t* unsupported = protocol_copyPropertyList2(protocol, &count, NO, YES);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Properties are not suppoerted."];
		}
	}
	{
		objc_property_t* unsupported = protocol_copyPropertyList2(protocol, &count, YES, NO);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Properties are not suppoerted."];
		}
	}
	{
		objc_property_t* unsupported = protocol_copyPropertyList2(protocol, &count, NO, NO);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Properties are not suppoerted."];
		}
	}
	
	{
		struct objc_method_description * unsupported = protocol_copyMethodDescriptionList(protocol, YES, NO, &count);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Class methods are not supported."];
		}
	}
	
	{
		struct objc_method_description * unsupported = protocol_copyMethodDescriptionList(protocol, NO, NO, &count);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Class methods are not supported."];
		}
	}
	{
		struct objc_method_description * unsupported = protocol_copyMethodDescriptionList(protocol, NO, YES, &count);
		ln_defer {
			free_if_needed(unsupported);
		};
		if(count > 0)
		{
			[NSException raise:NSInvalidArgumentException format:@"Optional methods are not supported."];
		}
	}
	{
		struct objc_method_description * supported = protocol_copyMethodDescriptionList(protocol, YES, YES, &count);
		ln_defer {
			free_if_needed(supported);
		};
		
		for(unsigned int idx = 0; idx < count; idx++)
		{
			const char* types = _protocol_getMethodTypeEncoding(protocol, supported[idx].name, YES, YES);
			
			NSMethodSignature* methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
			
			if(strncmp(methodSignature.methodReturnType, "v", 2))
			{
				[NSException raise:NSInvalidArgumentException format:@"Methods must have 'void' return type."];
			}
			
			map[NSStringFromSelector(supported[idx].name)] = methodSignature;
			[signatures addObject:methodSignature];
		}
	}
}

static void _LNIterateProtocols(Protocol* protocol, NSMutableArray* signatures, NSMutableDictionary* map)
{
	if(protocol_isEqual(protocol, @protocol(NSObject)))
	{
		return;
	}
	
	unsigned int adoptedCount = 0;
	Protocol* __unsafe_unretained * adoptedProtocols = protocol_copyProtocolList(protocol, &adoptedCount);
	ln_defer {
		free_if_needed(adoptedProtocols);
	};
	
	for(unsigned int idx = 0; idx < adoptedCount; idx++)
	{
		_LNIterateProtocols(adoptedProtocols[idx], signatures, map);
	}
	
	_LNAddSignatures(protocol, signatures, map);
}

+ (instancetype)interfaceWithProtocol:(Protocol *)protocol
{
	LNIPCInterface* rv = [LNIPCInterface new];
	rv.protocol = protocol;

	NSMutableArray<NSMethodSignature*>* signatures = [NSMutableArray new];
	NSMutableDictionary<NSString*, NSMethodSignature*>* map = [NSMutableDictionary new];
	
	_LNIterateProtocols(rv.protocol, signatures, map);
	
	rv.selectoToSignature = map;
	rv.methodSignatures = signatures;

	return rv;
}

- (NSUInteger)numberOfMethods
{
	return _methodListCount;
}

- (NSMethodSignature *)protocolMethodSignatureForSelector:(SEL)aSelector
{
	return _selectoToSignature[NSStringFromSelector(aSelector)];
}

@end

static dispatch_queue_t _connectionQueue;

@implementation LNIPCConnection
{
	dispatch_queue_t _dispatchQueue;
	NSRunLoop* _runLoop;
	NSString* _actualServiceName;
	
	BOOL _resumed;
}

- (void)_runQueue
{
	_runLoop = NSRunLoop.currentRunLoop;
	
	[_connection run];
	
	_resumed = YES;
}

- (BOOL)_commonInit
{
	NSPort* port = NSPort.port;
	if([NSPortNameServer.systemDefaultPortNameServer registerPort:port name:_actualServiceName] == NO)
	{
		return NO;
	}
	
	_connection = [NSConnection connectionWithReceivePort:port sendPort:nil];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_mainConnectionDidDie:) name:NSConnectionDidDieNotification object:_connection];
	_connection.rootObject = self;
	
	return YES;
}

- (instancetype)initWithServiceName:(NSString *)serviceName
{
	self = [super init];
	if(self)
	{
		_serviceName = [serviceName copy];
		_actualServiceName = _serviceName;
		_slave = NO;
		
		_dispatchQueue = dispatch_queue_create([NSString stringWithFormat:@"com.LeoNatan.LNIPCConnection:%@", _serviceName].UTF8String, dispatch_queue_attr_make_with_autorelease_frequency(NULL, DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM));
		
		//Attempt becoming a master
		if([self _commonInit] == NO)
		{
			_actualServiceName = [NSString stringWithFormat:@"%@.slave", _serviceName];
			_slave = YES;
			
			//Attempt becoming the slave
			NSAssert([self _commonInit] == YES, @"The service “%@” already has two endpoints connected.", _serviceName);
			
			_otherConnection = [NSConnection connectionWithRegisteredName:_serviceName host:nil];
			[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_otherConnectionDidDie:) name:NSConnectionDidDieNotification object:_otherConnection];
			[(id)_otherConnection.rootProxy _slaveDidConnectWithName:_actualServiceName];
		}
	}
	return self;
}

- (instancetype)initWithRegisteredServiceName:(NSString *)serviceName
{
	return [self initWithServiceName:serviceName];
}

- (void)_mainConnectionDidDie:(NSNotification*)note
{
	[_otherConnection invalidate];
	
	dispatch_block_t block = _invalidationHandler;
	_invalidationHandler = nil;
	
	[_runLoop performBlock:^{
		if(block)
		{
			block();
		}
		
		CFRunLoopStop(CFRunLoopGetCurrent());
	}];
}

- (void)_otherConnectionDidDie:(NSNotification*)note
{
	if(_connection.isValid)
	{
		[_connection invalidate];
	}
}

- (void)resume
{
	if(_resumed)
	{
		return;
	}
	
	NSAssert(_exportedObject != nil || _remoteObjectInterface != nil, @"An exported object or a remote object interface must be set before resuming the connection.");
	
	dispatch_async(_dispatchQueue, ^{
		[self _runQueue];
	});
}

- (void)invalidate
{
	[_connection invalidate];
	[_otherConnection invalidate];
}

- (BOOL)isValid
{
	return _connection.isValid && _otherConnection.isValid;
}

- (id)remoteObjectProxy
{
	return [_LNIPCDistantObject _distantObjectWithConnection:self synchronous:NO errorBlock:nil];
}

- (id)remoteObjectProxyWithErrorHandler:(void (^)(NSError * _Nonnull))handler
{
	return [_LNIPCDistantObject _distantObjectWithConnection:self synchronous:NO errorBlock:handler];
}

- (id)synchronousRemoteObjectProxyWithErrorHandler:(void (^)(NSError * _Nonnull))handler
{
	return [_LNIPCDistantObject _distantObjectWithConnection:self synchronous:YES errorBlock:handler];
}

- (void)setExportedObject:(id)exportedObject
{
	NSAssert(self.exportedInterface != nil, @"Exported interface must be set before setting an exported object.");
	NSAssert([exportedObject conformsToProtocol:self.exportedInterface.protocol], @"Exported object must confrom to the exported interface protocol.");
	_exportedObject = exportedObject;
}

#pragma mark _LNIPCImpl

- (oneway void)_slaveDidConnectWithName:(NSString*)slaveServiceName
{
	_otherConnection = [NSConnection connectionWithRegisteredName:slaveServiceName host:nil];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_otherConnectionDidDie:) name:NSConnectionDidDieNotification object:_otherConnection];
}

- (oneway void)_invokeFromRemote:(NSDictionary*)serializedInvocation
{
	_LNIPCExportedObject* exportedObj = [_LNIPCExportedObject _exportedObjectWithObject:self.exportedObject connection:self serializedInvocation:serializedInvocation];
	[exportedObj invoke];
}

- (oneway void)_invokeRemoteBlock:(NSDictionary*)serializedBlock
{
	_LNIPCDistantObject* distantObject;
	id localBlock = [_LNIPCRemoteBlockRegistry remoteBlockForIdentifier:serializedBlock[@"remoteBlockIdentifier"] distantObject:&distantObject];
	_LNIPCExportedObject* exportedObj = [_LNIPCExportedObject _exportedObjectWithObject:localBlock connection:self serializedInvocation:serializedBlock];
	if([distantObject _enqueueSynchronousExportedObjectInvocation:exportedObj] == NO)
	{
		[exportedObj invoke];
	}
}

- (oneway void)_cleanupRemoteBlock:(NSString*)identifier
{
	[_LNIPCRemoteBlockRegistry releaseRemoteBlock:identifier];
}

- (BOOL)_ping
{
	return YES;
}

@end
