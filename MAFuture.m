#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>

#import "MABaseFuture.h"
#import "MAFuture.h"


#define ENABLE_LOGGING 0

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif

@interface _MABlockFuture : MABaseFuture
{
}
- (id)initWithBlock: (id (^)(void))block;
@end

@implementation _MABlockFuture

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [self init]))
    {
    }
    return self;
}

- (id)forwardingTargetForSelector: (SEL)sel
{
    LOG(@"%p forwardingTargetForSelector: %@, resolving future", self, NSStringFromSelector(sel));
    return [self resolveFuture];
}

- (BOOL)respondsToSelector: (SEL)sel
{
    return [[self resolveFuture] respondsToSelector: sel];
}

@end


@interface _MABackgroundBlockFuture : _MABlockFuture
{
}
@end

@implementation _MABackgroundBlockFuture

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [super initWithBlock: block]))
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


@interface _MALazyBlockFuture : _MABlockFuture
{
    id (^_block)(void);
}
@end

@implementation _MALazyBlockFuture

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [super initWithBlock: block]))
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

#undef MAFuture
id MAFuture(id (^block)(void))
{
    return [[[_MABackgroundBlockFuture alloc] initWithBlock: block] autorelease];
}

#undef MALazyFuture
id MALazyFuture(id (^block)(void))
{
    return [[[_MALazyBlockFuture alloc] initWithBlock: block] autorelease];
}
