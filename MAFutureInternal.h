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

@interface _IKMemoryAwareFuture : _MALazyBlockFuture {
    BOOL isObserving;
    BOOL isManuallyStopped;
}
/*
  @abstract Use this property to control observing of memory warning notifications.
 */
@property BOOL isObserving;

/*
  @abstract Called in response to UIApplicationDidReceiveMemoryWarningNotification.
  @discussion Starts processMemoryWarningUnlocked on background thread.
 */
- (void)processMemoryWarning;

/*
  @abstract Releases future and sets _resolved to NO.
 */
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
  @abstract Archives value to the disk.
  @result YES if value is archived without errors. Otherwise NO.
*/
- (BOOL)archiveValueUnlocked;

/*
  @abstract Unarchives value from the disk.
  @result YES if value is unarchived without errors. If either archive for future doesn't exist or error is occured, returns NO. 
*/
- (BOOL)unarchiveValueUnlocked;

@end

#endif // __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_3_2
#endif // __IPHONE_OS_VERSION_MIN_REQUIRED
