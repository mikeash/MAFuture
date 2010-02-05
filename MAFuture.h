
id MAFuture(id (^block)(void));
id MALazyFuture(id (^block)(void));

#define MAFuture(...) ((__typeof((__VA_ARGS__)()))MAFuture((id (^)(void))(__VA_ARGS__)))
#define MALazyFuture(...) ((__typeof((__VA_ARGS__)()))MALazyFuture((id (^)(void))(__VA_ARGS__)))
