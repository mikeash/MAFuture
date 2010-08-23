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

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_3_2

/*
 Subclassing Notes:
 
 Template for resolveFuture method:
 [_lock lock];
 if(![self futureHasResolved])
 {
    
    // ---> Insert your code here <---
    // Somewhere in your code you should place [self setFutureValueUnlocked: _block()];
 
    if (!isManuallyStopped) {
        [self setIsObservingUnlocked:YES];
    }
 }
 [_lock unlock];
 return _value;
 */
@interface _IKMemoryAwareFuture : _MALazyBlockFuture {
    BOOL isObserving;
    BOOL isManuallyStopped;
}

@property BOOL isObserving;

- (void)processMemoryWarning;

- (void)processMemoryWarningUnlocked;

/*
 @abstract Called whenever isObserver variable is changed.
 @discussion You should not call this function directly from your code. Instead, you should use isObserving property 
 to start/stop observing memory warnings notifications.
 */
- (void)setIsObservingUnlocked:(BOOL)newIsObserving;

@end

NSString* IKMemoryAwareFuturesDirectory();

NSString* IKMemoryAwareFuturePath(id future);

@interface _IKAutoArchivingMemoryAwareFuture : _IKMemoryAwareFuture

/*
  @abstract Encode value while holding the lock
*/
- (BOOL)encodeValue;
/*
  @abstract Encode value without holding the lock
*/
- (BOOL)encodeValueUnlocked;
/*
  @abstract Decode value while holding the lock
*/
- (BOOL)decodeValue;
/*
  @abstract Decode value without holding the lock
*/
- (BOOL)decodeValueUnlocked;

@end

#endif // __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_3_2
#endif // __IPHONE_OS_VERSION_MIN_REQUIRED
