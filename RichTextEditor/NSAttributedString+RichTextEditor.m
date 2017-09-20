//
//  NSAttributedString+RichTextEditor.m
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import "NSAttributedString+RichTextEditor.h"

@implementation NSAttributedString (RichTextEditor)

-(NSRange)firstParagraphRangeFromTextRange:(NSRange)range withNewline:(BOOL)isWithNewLine
{
    NSRange firstRange = NSMakeRange(0,range.location);
    NSString *newLineStr = @"\n";
    NSRange firstHalfEndRange = NSMakeRange(NSNotFound, NSNotFound);
    firstHalfEndRange = [self.string rangeOfString:newLineStr options:NSBackwardsSearch range:firstRange];
    int extStart = 1;
    if (firstHalfEndRange.location == NSNotFound) {
        firstHalfEndRange.location = 0 ;
        extStart = 0;
    }
    else
    {
        firstHalfEndRange.location ++;
    }
    
    NSInteger len = self.length - firstHalfEndRange.location;
    
    NSRange lastRange = NSMakeRange(firstHalfEndRange.location, len);
    
    NSRange lastHalfInitRange = NSMakeRange(NSNotFound, NSNotFound);
    lastHalfInitRange = [self.string rangeOfString:newLineStr options:NSCaseInsensitiveSearch range:lastRange];
    
    if (lastHalfInitRange.location == NSNotFound) {
        lastHalfInitRange.location = self.length;
    }
    else if(isWithNewLine)
    {
        lastHalfInitRange.location++;
    }
    
    NSInteger totalLen = lastHalfInitRange.location - firstHalfEndRange.location;
    
    return NSMakeRange(firstHalfEndRange.location,totalLen);
}


-(NSRange)firstParagraphRangeFromTextRange:(NSRange)range
{
    return  [self firstParagraphRangeFromTextRange:range withNewline:NO];
}

-(NSRange)previousParagraphForRange:(NSRange)range
{
    NSRange currentParaRange = [self firstParagraphRangeFromTextRange:range];
    NSRange prevParaRange = NSMakeRange(NSNotFound, NSNotFound);
    if (currentParaRange.location != NSNotFound && currentParaRange.location > 0) {
        prevParaRange = [self firstParagraphRangeFromTextRange:NSMakeRange(currentParaRange.location - 1, 0)];
    }
    return  prevParaRange;
}

-(NSRange)getAttributeRangeAtIndex:(NSInteger)index andAttribute:(NSString *)atrtibute
{
    NSRange __block attribRange = NSMakeRange(NSNotFound, NSNotFound);
    [self enumerateAttribute:atrtibute inRange:NSMakeRange(0, self.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nonnull value, NSRange range, BOOL * _Nonnull stop) {
        if (value && index>= range.location && index < range.location + range.length) {
            attribRange = range;
        }
    }];
    return attribRange;
}


- (NSArray *)rangeOfParagraphsFromTextRange:(NSRange)textRange WithNewLineChar:(BOOL)isWithNewLine
{
    NSMutableArray *paragraphRanges = [NSMutableArray array];
    NSInteger rangeStartIndex = textRange.location;
    NSInteger selectedTextLen = textRange.location + textRange.length;
    
    while (rangeStartIndex <= selectedTextLen)
    {
        NSRange range ;
        NSInteger exInx = 1;
        if (isWithNewLine) {
            exInx = 0;
            range = [self firstParagraphRangeFromTextRange:NSMakeRange(rangeStartIndex, 0) withNewline:YES];
        }
        else
        {
            range = [self firstParagraphRangeFromTextRange:NSMakeRange(rangeStartIndex, 0)];
        }
        rangeStartIndex = range.location + range.length + exInx;
        [paragraphRanges addObject:[NSValue valueWithRange:range]];
        if (isWithNewLine && rangeStartIndex == selectedTextLen) {
            return  paragraphRanges;
        }
    }
    return paragraphRanges;
}


- (NSArray *)rangeOfParagraphsFromTextRange:(NSRange)textRange
{
    return  [self rangeOfParagraphsFromTextRange:textRange WithNewLineChar:NO];
}

- (NSArray *)rangeOfParagraphsFromTextRangeForQuote:(NSRange)textRange
{
    return [self rangeOfParagraphsFromTextRange:textRange WithNewLineChar:YES];
}

@end
