#import "MABaseFuture.h"


@interface _MASimpleFuture : MABaseFuture
{
}
@end

@interface _MALazyBlockFuture : _MASimpleFuture
{
    id (^_block)(void);
}

- (id)initWithBlock: (id (^)(void))block;

@end

#ifdef __IPHONE_4_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0

@interface _IKMemoryAwareFuture : _MALazyBlockFuture {
@private
  id _memoryWarningsObserver;
}

@end

#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
#endif // __IPHONE_4_0
