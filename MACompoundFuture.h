
id MACompoundFuture(id (^block)(void));
id MACompoundLazyFuture(id (^block)(void));

#define MACompoundFuture(...) ((__typeof((__VA_ARGS__)()))MACompoundFuture((id (^)(void))(__VA_ARGS__)))
#define MACompoundLazyFuture(...) ((__typeof((__VA_ARGS__)()))MACompoundLazyFuture((id (^)(void))(__VA_ARGS__)))
