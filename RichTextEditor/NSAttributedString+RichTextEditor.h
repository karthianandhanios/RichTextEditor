//
//  NSAttributedString+RichTextEditor.h
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (RichTextEditor)
- (NSRange)firstParagraphRangeFromTextRange:(NSRange)range;
-(NSRange)firstParagraphRangeFromTextRange:(NSRange)range withNewline:(BOOL)isWithNewLine;
- (NSArray *)rangeOfParagraphsFromTextRange:(NSRange)textRange;
-(NSRange)getMentionedRangeAtIndex:(NSInteger)index;
- (NSString *)htmlString;
- (NSArray *)rangeOfParagraphsFromTextRangeForQuote:(NSRange)textRange;
-(NSRange)getAttributeRangeAtIndex:(NSInteger)index andAttribute:(NSString *)atrtibute;
-(NSRange)previousParagraphForRange:(NSRange)range;

@end
