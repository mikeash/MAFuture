#import <objc/runtime.h>

#import "MAMethodSignatureCache.h"


@interface NSRecursiveLock (BlockAdditions)

- (void)ma_do: (dispatch_block_t)block;

@end

@implementation NSRecursiveLock (BlockAdditions)

- (void)ma_do: (dispatch_block_t)block
{
    [self lock];
    block();
    [self unlock];
}

@end


@implementation MAMethodSignatureCache

+ (MAMethodSignatureCache *)sharedCache
{
    static MAMethodSignatureCache *cache;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{ cache = [[self alloc] init]; });
    return cache;
}

- (id)init
{
    if((self = [super init]))
    {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        _cache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
#else
        _cache = [[NSMapTable alloc]
                  initWithKeyOptions: NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality
                  valueOptions: NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                  capacity: 0];
#endif
        _lock = [[NSRecursiveLock alloc] init];
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector( _clearCache )
         name: NSBundleDidLoadNotification
         object: nil];
    }
    return self;
}

- (void)_clearCache
{
    [_lock ma_do: ^{
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        CFDictionaryRemoveAllValues(_cache);
#else
        [_cache removeAllObjects]; 
#endif
    }];
}

- (NSMethodSignature *)_searchAllClassesForSignature: (SEL)sel
{
    int count = objc_getClassList(NULL, 0);
    Class *classes = malloc(sizeof(*classes) * count);
    objc_getClassList(classes, count);
    
    NSMethodSignature *sig = nil;
    for(int i = 0; i < count; i++)
    {
        Class c = classes[i];
        if(class_getClassMethod(c, @selector(methodSignatureForSelector:)) && class_getClassMethod(c, @selector(instanceMethodSignatureForSelector:)))
        {
            NSMethodSignature *thisSig = [c methodSignatureForSelector: sel];
            if(!sig)
                sig = thisSig;
            else if(sig && thisSig && ![sig isEqual: thisSig])
            {
                sig = nil;
                break;
            }
            
            thisSig = [c instanceMethodSignatureForSelector: sel];
            if(!sig)
                sig = thisSig;
            else if(sig && thisSig && ![sig isEqual: thisSig])
            {
                sig = nil;
                break;
            }
        }
    }
    
    free(classes);
    
    return sig;
}

- (NSMethodSignature *)cachedMethodSignatureForSelector: (SEL)sel
{
    __block NSMethodSignature *sig = nil;
    [_lock ma_do: ^{
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        sig = CFDictionaryGetValue(_cache, sel);
#else
        sig = [_cache objectForKey: (id)sel];
#endif
        if(!sig)
        {
            sig = [self _searchAllClassesForSignature: sel];
            if(!sig)
                sig = (id)[NSNull null];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
            CFDictionarySetValue(_cache, sel, sig);
#else
            [_cache setObject: sig forKey: (id)sel];
#endif
        }
    }];
    if(sig == (id)[NSNull null])
        sig = nil;
    return sig;
}

@end
