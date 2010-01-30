
id MAFuture(id (^block)(void));
id MALazyFuture(id (^block)(void));
id MACompoundFuture(id (^block)(void));
id MACompoundLazyFuture(id (^block)(void));

#define MAFuture(...) ((__typeof((__VA_ARGS__)()))MAFuture((id (^)(void))(__VA_ARGS__)))
#define MALazyFuture(...) ((__typeof((__VA_ARGS__)()))MALazyFuture((id (^)(void))(__VA_ARGS__)))
#define MACompoundFuture(...) ((__typeof((__VA_ARGS__)()))MACompoundFuture((id (^)(void))(__VA_ARGS__)))
#define MACompoundLazyFuture(...) ((__typeof((__VA_ARGS__)()))MACompoundLazyFuture((id (^)(void))(__VA_ARGS__)))
