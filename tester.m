// gcc -framework Foundation -W -Wall -Wno-unused-parameter --std=c99 -g *.m
#import <Foundation/Foundation.h>

#import "MAFuture.h"

int main(int argc, char **argv)
{
    [NSAutoreleasePool new];
    
    @try
    {
        NSLog(@"one");
        NSString *s = MACompoundFuture(^{ sleep(1); return @"three"; });
        NSLog(@"two: %p", s);
        NSString *s2 = [s substringFromIndex: 1];
        NSLog(@"%lld", (long long)[s2 length]);
        NSLog(@"%lld", (long long)[s length]);
        NSString *ps = [NSString stringWithFormat: @"%@", s];
        NSLog(@"%@", ps);
    }
    @catch(id exception)
    {
        fprintf(stderr, "Exception: %s\n", [[exception description] UTF8String]);
    }
}

