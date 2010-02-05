#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "MAFuture.h"


#define ENABLE_LOGGING 0

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif

@interface _MABlockFuture : NSProxy
{
    id (^_block)(void);
    BOOL _lazy;
    BOOL _resolved;
    id _value;
    NSConditionLock *_lock;
}
- (id)initWithBlock: (id (^)(void))block lazy: (BOOL)lazy;
- (id)_resolveFuture;
@end

@implementation _MABlockFuture

+ (void)initialize
{
    // de-override -description
    Method m = class_getInstanceMethod(self, @selector(description));
    IMP forwarder = class_getMethodImplementation(self, @selector(thisMethodDoesNotExist));
    class_replaceMethod(self, @selector(description), forwarder, method_getTypeEncoding(m));
}

- (id)initWithBlock: (id (^)(void))block lazy: (BOOL)lazy
{
    _block = [block copy];
    _lazy = lazy;
    _lock = [[NSConditionLock alloc] init];
    
    if(!lazy)
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            id obj = block();
            [_lock lock];
            _value = [obj retain];
            [_block release];
            _block = nil;
            _resolved = YES;
            [_lock unlockWithCondition: 1];
        });
    
    return self;
}

- (void)dealloc
{
    [_block release];
    [_value release];
    [_lock release];
    [super dealloc];
}

- (id)_resolveFuture
{
    if(_lazy)
        [_lock lock];
    else
        [_lock lockWhenCondition: 1];
    
    if(_lazy && !_resolved)
    {
        _value = [_block() retain];
        [_block release];
        _block = nil;
        _resolved = YES;
    }
    [_lock unlock];
    return _value;
}

- (id)forwardingTargetForSelector: (SEL)sel
{
    return [self _resolveFuture];
}

- (BOOL)respondsToSelector: (SEL)sel
{
    return [[self _resolveFuture] respondsToSelector: sel];
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
