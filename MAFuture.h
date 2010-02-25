
id MABackgroundFuture(id (^block)(void));
id MALazyFuture(id (^block)(void));

#define MABackgroundFuture(...) ((__typeof((__VA_ARGS__)()))MABackgroundFuture((id (^)(void))(__VA_ARGS__)))
#define MALazyFuture(...) ((__typeof((__VA_ARGS__)()))MALazyFuture((id (^)(void))(__VA_ARGS__)))
