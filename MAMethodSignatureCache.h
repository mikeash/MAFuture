#import <Foundation/Foundation.h>


@interface MAMethodSignatureCache : NSObject
{
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    CFMutableDictionaryRef _cache;
#else
    NSMapTable *_cache;
#endif
    NSRecursiveLock *_lock;
}

+ (MAMethodSignatureCache *)sharedCache;
- (NSMethodSignature *)cachedMethodSignatureForSelector: (SEL)sel;

@end
