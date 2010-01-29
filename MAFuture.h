
id MAFuture(id (^block)(void));

#define MAFuture(...) ((__typeof((__VA_ARGS__)()))MAFuture((id (^)(void))(__VA_ARGS__)))

id MACompoundFuture(id (^block)(void));

#define MACompoundFuture(...) ((__typeof((__VA_ARGS__)()))MACompoundFuture((id (^)(void))(__VA_ARGS__)))
