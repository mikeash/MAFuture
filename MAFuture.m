#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "MAMethodSignatureCache.h"

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

@interface _MACompoundFuture : NSProxy
{
    id _parentFuture;
    NSInvocation *_derivationInvocation;
    id _value;
    NSConditionLock *_lock;
}
- (id)initWithParent: (id)parent derivationInvocation: (NSInvocation *)invocation;
- (id)_resolveFuture;
@end

@implementation _MACompoundFuture

+ (void)initialize
{
    // de-override -description
    Method m = class_getInstanceMethod(self, @selector(description));
    IMP forwarder = class_getMethodImplementation(self, @selector(thisMethodDoesNotExist));
    class_replaceMethod(self, @selector(description), forwarder, method_getTypeEncoding(m));
}

- (id)initWithParent: (id)parent derivationInvocation: (NSInvocation *)invocation
{
    NSParameterAssert(!invocation || [[invocation methodSignature] methodReturnType][0] == @encode(id)[0]);
    
    _parentFuture = [parent retain];
    _derivationInvocation = [invocation retain];
    [invocation retainArguments];
    
    _lock = [[NSConditionLock alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_parentFuture release];
    [_derivationInvocation release];
    [_value release];
    [_lock release];
    [super dealloc];
}

- (id)_resolveFuture
{
    [_lock lock];
    if([_lock condition] != 1)
    {
        LOG(@"%p resolving against %@ with %@", self, NSStringFromClass(object_getClass(_parentFuture)), NSStringFromSelector([_derivationInvocation selector]));
        
        if(_derivationInvocation)
        {
            [_derivationInvocation invokeWithTarget: [_parentFuture _resolveFuture]];
            [_derivationInvocation getReturnValue: &_value];
        }
        else
        {
            // no _derivationInvocation is a special case meaning to just get
            // the value directly from the parent future
            _value = [_parentFuture _resolveFuture];
        }
        [_value retain];
        
        [_parentFuture release];
        _parentFuture = nil;
        [_derivationInvocation release];
        _derivationInvocation = nil;
    }
    [_lock unlockWithCondition: 1];
    
    return _value;
}

- (BOOL)_canFutureSelector: (SEL)sel
{
    NSMethodSignature *sig = [[MAMethodSignatureCache sharedCache] cachedMethodSignatureForSelector: sel];
    if(!sig) return NO;
    else     return [sig methodReturnType][0] == @encode(id)[0];
}

- (id)forwardingTargetForSelector: (SEL)sel
{
    LOG(@"forwardingTargetForSelector: %p %@", self, NSStringFromSelector(sel));
    
    id val;
    [_lock lock];
    val = _value;
    [_lock unlock];
    
    if(val) return val;
    
    if([self _canFutureSelector: sel])
        return nil;
    else
        return [self _resolveFuture];
}

- (BOOL)respondsToSelector: (SEL)sel
{
    LOG(@"respondsToSelector: %p %@", self, NSStringFromSelector(sel));
    
    return [[self _resolveFuture] respondsToSelector: sel];
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel
{
    LOG(@"methodSignatureForSelector: %p %@", self, NSStringFromSelector(sel));
    
    NSMethodSignature *sig = nil;
    [_lock lock];
    sig = [_value methodSignatureForSelector: sel];
    [_lock unlock];
    
    if(!sig)
        sig = [[MAMethodSignatureCache sharedCache] cachedMethodSignatureForSelector: sel];
    
    if(!sig)
        sig = [[self _resolveFuture] methodSignatureForSelector: sel];
    
    return sig;
}

- (void)forwardInvocation: (NSInvocation *)invocation
{
    LOG(@"forwardInvocation: %p %@", self, NSStringFromSelector([invocation selector]));
    
    NSParameterAssert([self _canFutureSelector: [invocation selector]]);
    
    id val;
    [_lock lock];
    val = _value;
    [_lock unlock];
    
    if(val)
    {
        LOG(@"forwardInvocation: %p forwarding to %p", invocation, val);
        [invocation invokeWithTarget: val];
    }
    else
    {
        _MACompoundFuture *future = [[_MACompoundFuture alloc] initWithParent: self derivationInvocation: invocation];
        LOG(@"forwardInvocation: %p creating new compound future %p", invocation, future);
        [invocation setReturnValue: &future];
        [future release];
    }
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

#undef MACompoundFuture
id MACompoundFuture(id (^block)(void))
{
    _MABlockFuture *blockFuture = [[_MABlockFuture alloc] initWithBlock: block lazy: NO];
    
    _MACompoundFuture *compoundFuture = [[_MACompoundFuture alloc] initWithParent: blockFuture derivationInvocation: nil];
    
    [blockFuture release];
    
    return [compoundFuture autorelease];
}

#undef MACompoundLazyFuture
id MACompoundLazyFuture(id (^block)(void))
{
    _MABlockFuture *blockFuture = [[_MABlockFuture alloc] initWithBlock: block lazy: YES];
    
    _MACompoundFuture *compoundFuture = [[_MACompoundFuture alloc] initWithParent: blockFuture derivationInvocation: nil];
    
    [blockFuture release];
    
    return [compoundFuture autorelease];
}
