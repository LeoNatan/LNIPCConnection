//
//  _LNIPCRemoteBlockRegistry.m
//  LNIPCConnection
//
//  Created by Leo Natan on 9/25/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

/***
*    ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗
*    ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝
*    ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
*    ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║
*    ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
*     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
*
*
* WARNING: This file compiles with ARC disabled! Take extra care when modifying or adding functionality.
*/

#import "_LNIPCRemoteBlockRegistry.h"
#import "_LNIPCDistantObject.h"
@import ObjectiveC;
@import Darwin;

@interface _LNRemoteBlockRegistryEntry : NSObject
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) id block;
@property (nonatomic) NSInteger blockRetainCount;
@property (nonatomic, strong) _LNIPCDistantObject* distantObject;
@end
@implementation _LNRemoteBlockRegistryEntry @end

pthread_mutex_t _registryMutex;

static NSMutableDictionary* _registry;

@implementation _LNIPCRemoteBlockRegistry

+ (void)load
{
	@autoreleasepool
	{
		_registry = [NSMutableDictionary new];
		pthread_mutex_init(&_registryMutex, NULL);
	}
}

+ (NSString*)registerRemoteBlock:(id)block distantObject:(_LNIPCDistantObject*)distantObject
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	NSString* identifier = [NSUUID UUID].UUIDString;
	
	@autoreleasepool
	{
		id copied = _Block_copy(block);
		
		_LNRemoteBlockRegistryEntry* entry = [_LNRemoteBlockRegistryEntry new];
		entry.identifier = identifier;
		entry.block = [copied autorelease];
		entry.blockRetainCount = 1;
		entry.distantObject = distantObject;
		[entry.distantObject _enterReplyBlock];
		
		_registry[identifier] = entry;
	}
	
	return identifier;
}

+ (id)remoteBlockForIdentifier:(NSString*)identifier distantObject:(_LNIPCDistantObject* __nullable * __nullable)distantObject;
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	_LNRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
	if(distantObject != NULL)
	{
		*distantObject = entry.distantObject;
	}
	return entry.block;
}

+ (oneway void)retainRemoteBlock:(NSString*)identifier
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	_LNRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
	entry.blockRetainCount += 1;
}

+ (oneway void)releaseRemoteBlock:(NSString*)identifier
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	@autoreleasepool
	{
		_LNRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
		entry.blockRetainCount -= 1;
		
		if(entry.blockRetainCount == 0)
		{
			[entry.distantObject _leavelReplyBlock];
			
			[_registry removeObjectForKey:identifier];
		}
	}
}

@end
