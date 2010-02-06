#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>

#import "MABaseFuture.h"
#import "MAFuture.h"


#define ENABLE_LOGGING 1

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif

@interface _MABlockFuture : MABaseFuture
{
    id (^_block)(void);
    BOOL _lazy;
}
- (id)initWithBlock: (id (^)(void))block lazy: (BOOL)lazy;
@end

@implementation _MABlockFuture

- (id)initWithBlock: (id (^)(void))block lazy: (BOOL)lazy
{
    if((self = [self init]))
    {
        _block = [block copy];
        _lazy = lazy;
        
        if(!lazy)
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self setFutureValue: block()];
            });
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
    if(!_lazy)
    {
        return [self waitForFutureResolution];
    }
    else
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

#undef MAFuture
id MAFuture(id (^block)(void))
{
    return [[[_MABlockFuture alloc] initWithBlock: block lazy: NO] autorelease];
}

#undef MALazyFuture
id MALazyFuture(id (^block)(void))
{
    return [[[_MABlockFuture alloc] initWithBlock: block lazy: YES] autorelease];
}
