//
//  UIFont+RichTextEditor.h
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface UIFont (RichTextEditor)
+ (NSString *)postscriptNameFromFullName:(NSString *)fullName;
+ (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic;
- (UIFont *)fontWithBoldTrait:(BOOL)bold italicTrait:(BOOL)italic andSize:(CGFloat)size;
- (UIFont *)fontWithBoldTrait:(BOOL)bold andItalicTrait:(BOOL)italic;
- (BOOL)isBold;
- (BOOL)isItalic;

@end
