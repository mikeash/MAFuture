#import <Foundation/Foundation.h>

#if TARGET_OS_MAC && !TARGET_IPHONE_SIMULATOR

@interface MAMethodSignatureCache : NSObject
{
    NSMapTable *_cache;
    NSRecursiveLock *_lock;
}

+ (MAMethodSignatureCache *)sharedCache;
- (NSMethodSignature *)cachedMethodSignatureForSelector: (SEL)sel;

@end

#endif