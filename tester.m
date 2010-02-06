// gcc -framework Foundation -W -Wall -Wno-unused-parameter --std=c99 -g *.m
#import <Foundation/Foundation.h>

#import <objc/runtime.h>
#import "MACompoundFuture.h"
#import "MAFuture.h"

// make NSLog properly reentrant
#define NSLog(...) NSLog(@"%@", [NSString stringWithFormat: __VA_ARGS__])

int main(int argc, char **argv)
{
    [NSAutoreleasePool new];
    
    @try
    {
        
        NSLog(@"start");
        NSString *future = MAFuture(^{
            NSLog(@"Computing future\n");
            usleep(100000);
            return @"future result";
        });
        NSLog(@"future created");
        NSString *lazyFuture = MALazyFuture(^{
            NSLog(@"Computing lazy future\n");
            usleep(100000);
            return @"lazy future result";
        });
        NSLog(@"lazy future created");
        NSString *compoundFuture = MACompoundFuture(^{
            NSLog(@"Computing compound future\n");
            usleep(100000);
            return @"compound future result";
        });
        NSLog(@"compound future created");
        NSString *compoundLazyFuture = MACompoundLazyFuture(^{
            NSLog(@"Computing compound lazy future\n");
            usleep(100000);
            return @"compound future result";
        });
        NSLog(@"compound lazy future created");
        
        NSLog(@"future: %@", future);
        NSLog(@"lazy future: %@", lazyFuture);
        NSLog(@"compound future: %@", [compoundFuture stringByAppendingString: @" suffix"]);
        NSLog(@"compound lazy future: %@", [compoundLazyFuture stringByAppendingString: @" suffix"]);
        
        NSString *future1 = MAFuture(^{
            NSLog(@"Computing future\n");
            usleep(100000);
            return @"future result";
        });
        NSString *future2 = MAFuture(^{
            NSLog(@"Computing future\n");
            usleep(100000);
            return @"future result";
        });
        NSLog(@"%p == %p? %llx %llx %s", future1, future2, (long long)[future1 hash], (long long)[future2 hash], [future1 isEqual: future2] ? "YES" : "NO");
    }
    @catch(id exception)
    {
        fprintf(stderr, "Exception: %s\n", [[exception description] UTF8String]);
    }
    
//    unsigned int count;
//    Method *list = class_copyMethodList([NSProxy class], &count);
//    for(unsigned i = 0; i < count; i++)
//        NSLog(@"%@", NSStringFromSelector(method_getName(list[i])));
}

