//
//  IODProfanityFilter.m
//  IODProfanityFilter
//
//  Created by John Arnold on 2013-02-27.
//  Copyright (c) 2013 Island of Doom Software Inc. All rights reserved.
//

#import "IODProfanityFilter.h"

@implementation IODProfanityFilter

static NSMutableSet *IODProfanityFilterWordSet;

+ (NSMutableSet*)wordSet
{
    // Load up our word list and keep it around
    if (!IODProfanityFilterWordSet)
    {
        NSStringEncoding encoding;
        NSError *error;
        NSString *fileName = [[NSBundle bundleForClass:self.class] pathForResource:@"IODProfanityWords" ofType:@"txt"];
        NSString *wordStr = [NSString stringWithContentsOfFile:fileName usedEncoding:&encoding error:&error];
        NSArray *wordArray = [wordStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        IODProfanityFilterWordSet = [NSMutableSet setWithArray:wordArray];
    }
    
    return IODProfanityFilterWordSet;
}

+ (NSArray*)rangesOfFilteredWordsInString:(NSString*)string
{
    NSMutableArray *result = [NSMutableArray array];
    
    NSSet *wordSet = [self wordSet];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    
    NSCharacterSet *wordCharacters = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *nonWordCharacters = [wordCharacters invertedSet];
    
    while (![scanner isAtEnd])
    {
        // Look for words
        NSString *scanned;
        if ([scanner scanCharactersFromSet:wordCharacters intoString:&scanned]) {
            
            // Found a word, look it up in the word set
            if ([wordSet containsObject:[scanned lowercaseString]])
            {
                // The scan location is now at the end of the word
                NSRange range = NSMakeRange(scanner.scanLocation - scanned.length, scanned.length);
                [result addObject:[NSValue valueWithRange:range]];
            }
        }
        else
        {
            // Skip over non-word characters
            [scanner scanCharactersFromSet:nonWordCharacters intoString:&scanned];
        }
    }
    
    if (result.count == 0)
    {
        if ([wordSet containsObject:[string lowercaseString]])
        {
            NSRange range = NSMakeRange(0, string.length);
            [result addObject:[NSValue valueWithRange:range]];
        }
    }
    
    return result;
}

+ (NSString *)stringByFilteringString:(NSString *)string
{
    return [self stringByFilteringString:string withReplacementString:@"∗"];
}

+ (NSString*)stringByFilteringString:(NSString *)string withReplacementString:(NSString *)replacementString
{
    NSMutableString *result = [string mutableCopy];
    
    NSArray *rangesToFilter = [self rangesOfFilteredWordsInString:string];
    for (NSValue *rangeValue in rangesToFilter) {
        NSRange range = [rangeValue rangeValue];
        NSRange replacementRange = NSMakeRange(0, MIN(replacementString.length,range.length));
        replacementRange = [replacementString rangeOfComposedCharacterSequencesForRange:replacementRange];
        [result replaceCharactersInRange:range withString:[replacementString substringWithRange:replacementRange]];
    }
    
    return result;
}

+ (NSString*)stringByFilteringStringWithPartialReplacement:(NSString*)string {
    NSString *replacementString = @"";
    
    NSMutableString *result = [string mutableCopy];
    
    NSArray *rangesToFilter = [self rangesOfFilteredWordsInString:string];
    for (NSValue *rangeValue in rangesToFilter) {
        NSRange range = [rangeValue rangeValue];
        
        if (range.length > 2) {
            range.location += 1;
            range.length -= 2;
        }
        
        for (int i = 0; i < range.length; i++) {
            replacementString = [replacementString stringByAppendingString:@"*"];
        }
        
        NSString *replacement = [@"" stringByPaddingToLength:range.length withString:replacementString startingAtIndex:0];
        [result replaceCharactersInRange:range withString:replacement];
    }
    
    return result;
}

@end
