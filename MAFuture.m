#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>

#import "MABaseFuture.h"
#import "MAFuture.h"
#import "MAFutureInternal.h"
#import "MAMethodSignatureCache.h"


#define ENABLE_LOGGING 0

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif

@implementation _MASimpleFuture

- (id)forwardingTargetForSelector: (SEL)sel
{
    LOG(@"%p forwardingTargetForSelector: %@, resolving future", self, NSStringFromSelector(sel));
    return [self resolveFuture];
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel
{
    return [[MAMethodSignatureCache sharedCache] cachedMethodSignatureForSelector: sel];
}

- (void)forwardInvocation: (NSInvocation *)inv
{
    // this gets hit if the future resolves to nil
    // zero-fill the return value
    char returnValue[[[inv methodSignature] methodReturnLength]];
    bzero(returnValue, sizeof(returnValue));
    [inv setReturnValue: returnValue];
}

@end


@interface _MABackgroundBlockFuture : _MASimpleFuture
{
}
@end

@implementation _MABackgroundBlockFuture

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [self init]))
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self setFutureValue: block()];
        });
    }
    return self;
}

- (id)resolveFuture
{
    return [self waitForFutureResolution];
}

@end


@implementation _MALazyBlockFuture

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [self init]))
    {
        _block = [block copy];
    }
    return self;
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (id)resolveFuture
{
    [_lock lock];
    if(![self futureHasResolved])
    {
        [self setFutureValueUnlocked: _block()];
        [_block release];
        _block = nil;
    }
    [_lock unlock];
    return _value;
}

@end

#undef MABackgroundFuture
id MABackgroundFuture(id (^block)(void))
{
    return [[[_MABackgroundBlockFuture alloc] initWithBlock: block] autorelease];
}

#undef MALazyFuture
id MALazyFuture(id (^block)(void))
{
    return [[[_MALazyBlockFuture alloc] initWithBlock: block] autorelease];
}

#ifdef __IPHONE_4_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0

@implementation _IKMemoryAwareFuture

- (void)dealloc
{
    if (_memoryWarningsObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:_memoryWarningsObserver];
        [_memoryWarningsObserver release];
    }
    [super dealloc];
}


- (id)resolveFuture
{
    [_lock lock];
    if(![self futureHasResolved])
    {
        [self setFutureValueUnlocked: _block()];
        _memoryWarningsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                                                    object:nil
                                                                                     queue:nil
                                                                                usingBlock:^(NSNotification *notification) {
	    [_lock lock];
	    [[NSNotificationCenter defaultCenter] removeObserver:_memoryWarningsObserver name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	    [_memoryWarningsObserver release], _memoryWarningsObserver = nil;
	    [_value release], _value = nil;
	    _resolved = NO;
	    [_lock unlock];
	  }];
	[_memoryWarningsObserver retain];
    }
    [_lock unlock];
    return _value;
}

@end

#undef IKMemoryAwareFutureCreate
id IKMemoryAwareFutureCreate(id (^block)(void)) {
    return [[_IKMemoryAwareFuture alloc] initWithBlock:block];
}

#undef IKMemoryAwareFuture
id IKMemoryAwareFuture(id (^block)(void)) {
    return [IKMemoryAwareFutureCreate(block) autorelease];
}

#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
#endif // __IPHONE_4_0
