//
//  PKURLHelpers.h
//  PushupCounter
//
//  Created by Aaron Parecki on 12/27/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

@interface NSString (PKURLHelpers)
- (NSString *)stringByUnescapingFromURLQuery;
- (NSString *)stringByEscapingForURLQuery;
@end

@interface NSDictionary (PKURLHelpers)
+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString;
@end
