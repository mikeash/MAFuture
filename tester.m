// gcc -framework Foundation -W -Wall -Wno-unused-parameter --std=c99 -g *.m
#import <Foundation/Foundation.h>

#import "MAFuture.h"

int main(int argc, char **argv)
{
    [NSAutoreleasePool new];
    
    @try
    {
        
        NSLog(@"start");
        NSString *future = MAFuture(^{
            fprintf(stderr, "Computing future\n");
            usleep(100000);
            return @"future result";
        });
        NSLog(@"future created");
        NSString *lazyFuture = MALazyFuture(^{
            fprintf(stderr, "Computing lazy future\n");
            usleep(100000);
            return @"lazy future result";
        });
        NSLog(@"lazy future created");
        NSString *compoundFuture = MACompoundFuture(^{
            fprintf(stderr, "Computing compound future\n");
            usleep(100000);
            return @"compound future result";
        });
        NSLog(@"compound future created");
        NSString *compoundLazyFuture = MACompoundLazyFuture(^{
            fprintf(stderr, "Computing compound lazy future\n");
            usleep(100000);
            return @"compound future result";
        });
        NSLog(@"compound lazy future created");
        
        NSLog(@"future: %@", future);
        NSLog(@"lazy future: %@", lazyFuture);
        NSLog(@"compound future: %@", [compoundFuture stringByAppendingString: @" suffix"]);
        NSLog(@"compound lazy future: %@", [compoundLazyFuture stringByAppendingString: @" suffix"]);
    }
    @catch(id exception)
    {
        fprintf(stderr, "Exception: %s\n", [[exception description] UTF8String]);
    }
}

