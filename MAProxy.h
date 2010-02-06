@interface MAProxy
{
    Class isa;
    int32_t _refcountMinusOne;
}

+ (id)alloc;

- (void)dealloc;
- (BOOL)isProxy;
- (id)retain;
- (void)release;
- (id)autorelease;
- (NSUInteger)retainCount;

@end

