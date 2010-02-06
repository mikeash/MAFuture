#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "MABaseFuture.h"
#import "MAFuture.h"
#import "MAMethodSignatureCache.h"


#define ENABLE_LOGGING 0

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif


@interface _MACompoundFuture : MABaseFuture
{
    MABaseFuture *_parentFuture;
    NSInvocation *_derivationInvocation;
}
- (id)initWithParent: (id)parent derivationInvocation: (NSInvocation *)invocation;
@end

@implementation _MACompoundFuture

- (id)initWithParent: (MABaseFuture *)parent derivationInvocation: (NSInvocation *)invocation
{
    NSParameterAssert(!invocation || [[invocation methodSignature] methodReturnType][0] == @encode(id)[0]);
    
    if((self = [self init]))
    {
        _parentFuture = [parent retain];
        _derivationInvocation = [invocation retain];
        [invocation retainArguments];
    }
    return self;
}

- (void)dealloc
{
    [_parentFuture release];
    [_derivationInvocation release];
    [super dealloc];
}

- (id)resolveFuture
{
    [_lock lock];
    if(![self futureHasResolved])
    {
        LOG(@"%p resolving against %@ with %@", self, NSStringFromClass(object_getClass(_parentFuture)), NSStringFromSelector([_derivationInvocation selector]));
        
        id value = nil;
        if(_derivationInvocation)
        {
            [_derivationInvocation invokeWithTarget: [_parentFuture resolveFuture]];
            [_derivationInvocation getReturnValue: &value];
        }
        else
        {
            // no _derivationInvocation is a special case meaning to just get
            // the value directly from the parent future
            value = [_parentFuture resolveFuture];
        }
        [self setFutureValueUnlocked: value];
        
        [_parentFuture release];
        _parentFuture = nil;
        [_derivationInvocation release];
        _derivationInvocation = nil;
    }
    [_lock unlock];
    
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
    
    id value = [self futureValue];
    if(value)
        return value;
    else if([self _canFutureSelector: sel])
        return nil;
    else
        return [self resolveFuture];
}

- (BOOL)respondsToSelector: (SEL)sel
{
    LOG(@"respondsToSelector: %p %@", self, NSStringFromSelector(sel));
    
    return [[self resolveFuture] respondsToSelector: sel];
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel
{
    LOG(@"methodSignatureForSelector: %p %@", self, NSStringFromSelector(sel));
    
    NSMethodSignature *sig = [[self futureValue] methodSignatureForSelector: sel];
    
    if(!sig)
        sig = [[MAMethodSignatureCache sharedCache] cachedMethodSignatureForSelector: sel];
    
    if(!sig)
        sig = [[self resolveFuture] methodSignatureForSelector: sel];
    
    return sig;
}

- (void)forwardInvocation: (NSInvocation *)invocation
{
    LOG(@"forwardInvocation: %p %@", self, NSStringFromSelector([invocation selector]));
    
    NSParameterAssert([self _canFutureSelector: [invocation selector]]);
    
    id value = [self futureValue];
    
    if(value)
    {
        LOG(@"forwardInvocation: %p forwarding to %p", invocation, value);
        [invocation invokeWithTarget: value];
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

#undef MACompoundFuture
id MACompoundFuture(id (^block)(void))
{
    id blockFuture = MAFuture(block);
    
    _MACompoundFuture *compoundFuture = [[_MACompoundFuture alloc] initWithParent: blockFuture derivationInvocation: nil];
    
    return [compoundFuture autorelease];
}

#undef MACompoundLazyFuture
id MACompoundLazyFuture(id (^block)(void))
{
    id blockFuture = MALazyFuture(block);
    
    _MACompoundFuture *compoundFuture = [[_MACompoundFuture alloc] initWithParent: blockFuture derivationInvocation: nil];
    
    return [compoundFuture autorelease];
}

