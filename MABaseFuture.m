#import "MABaseFuture.h"

#import <objc/runtime.h>


@implementation MABaseFuture

+ (void)initialize
{
    // NSProxy implements -description for some boneheaded reason
    // this effectively removes that implementation by re-pointing
    // our IMP to point to the implementation of a non-existent method
    Method m = class_getInstanceMethod(self, @selector(description));
    IMP forwarder = class_getMethodImplementation(self, @selector(thisMethodDoesNotExist));
    class_replaceMethod(self, @selector(description), forwarder, method_getTypeEncoding(m));
}

- (id)init
{
    _lock = [[NSCondition alloc] init];
    return self;
}

- (void)dealloc
{
    [_value release];
    [_lock release];
    
    [super dealloc];
}

- (BOOL)respondsToSelector: (SEL)sel
{
    return [[self resolveFuture] respondsToSelector: sel];
}

- (void)setFutureValue: (id)value
{
    [_lock lock];
    [self setFutureValueUnlocked: value];
    [_lock unlock];
}

- (id)futureValue
{
    // skip the usual retain/autorelease dance here
    // because the setter is never called more than
    // once, thus value lifetime is same as future
    // lifetime
    [_lock lock];
    id value = _value;
    [_lock unlock];
    return value;
}

- (void)setFutureValueUnlocked: (id)value
{
    [value retain];
    [_value release];
    _value = value;
    _resolved = YES;
    [_lock broadcast];
}

- (BOOL)futureHasResolved
{
    return _resolved;
}

- (id)waitForFutureResolution
{
    [_lock lock];
    while(!_resolved)
        [_lock wait];
    [_lock unlock];
    return _value;
}

- (id)resolveFuture
{
    NSLog(@"-[MABaseFuture resolveFuture] called, this should never happen! Did you forget to implement -[%@ resolveFuture]?", isa);
    NSParameterAssert(0);
    return nil;
}

@end
