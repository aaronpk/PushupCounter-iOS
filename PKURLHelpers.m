//
//  PKURLHelpers.m
//  Pulled from https://github.com/samsoffes/sstoolkit/blob/c893cb4e7db579a0458e18f955b2e7865f6dd80a/SSToolkit/NSString%2BSSToolkitAdditions.m
//

#import "PKURLHelpers.h"

@implementation NSDictionary (PKURLHelpers)

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString {
    if (!encodedString) {
        return nil;
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *pairs = [encodedString componentsSeparatedByString:@"&"];
    
    for (NSString *kvp in pairs) {
        if ([kvp length] == 0) {
            continue;
        }
        
        NSRange pos = [kvp rangeOfString:@"="];
        NSString *key;
        NSString *val;
        
        if (pos.location == NSNotFound) {
            key = [kvp stringByUnescapingFromURLQuery];
            val = @"";
        } else {
            key = [[kvp substringToIndex:pos.location] stringByUnescapingFromURLQuery];
            val = [[kvp substringFromIndex:pos.location + pos.length] stringByUnescapingFromURLQuery];
        }
        
        if (!key || !val) {
            continue; // I'm sure this will bite my arse one day
        }
        
        [result setObject:val forKey:key];
    }
    return result;
}

@end

@implementation NSString (PKURLHelpers)

- (NSString *)stringByEscapingForURLQuery {
    NSString *result = self;
    
    static CFStringRef leaveAlone = CFSTR(" ");
    static CFStringRef toEscape = CFSTR("\n\r:/=,!$&'()*+;[]@#?%");
    
    CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, leaveAlone,
                                                                     toEscape, kCFStringEncodingUTF8);
    
    if (escapedStr) {
        NSMutableString *mutable = [NSMutableString stringWithString:(__bridge NSString *)escapedStr];
        CFRelease(escapedStr);
        
        [mutable replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutable length])];
        result = mutable;
    }
    return result;
}


- (NSString *)stringByUnescapingFromURLQuery {
    NSString *deplussed = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [deplussed stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
