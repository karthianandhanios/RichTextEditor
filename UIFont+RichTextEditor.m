//
//  UIFont+RichTextEditor.m
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//
#if !__has_feature(objc_arc)
#error UIFont+RichTextEditor is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


#import "UIFont+RichTextEditor.h"


@implementation UIFont (RichTextEditor)

+ (NSString *)postscriptNameFromFullName:(NSString *)fullName
{
    UIFont *font = [UIFont fontWithName:fullName size:1];
    return (__bridge NSString *)(CTFontCopyPostScriptName((__bridge CTFontRef)(font)));
}

+ (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic
{
    NSString *postScriptName = [UIFont postscriptNameFromFullName:name];
    
    CTFontSymbolicTraits traits = 0;
    CTFontRef newFontRef;
    CTFontRef fontWithoutTrait = CTFontCreateWithName((__bridge CFStringRef)(postScriptName), size, NULL);
    
    if (isItalic)
        traits |= kCTFontItalicTrait;
    
    if (isBold)
        traits |= kCTFontBoldTrait;
    
    if (traits == 0)
    {
        newFontRef= CTFontCreateCopyWithAttributes(fontWithoutTrait, 0.0, NULL, NULL);
    }
    else
    {
        newFontRef = CTFontCreateCopyWithSymbolicTraits(fontWithoutTrait, 0.0, NULL, traits, traits);
    }
    
    if (newFontRef)
    {
        NSString *fontNameKey = (__bridge NSString *)(CTFontCopyName(newFontRef, kCTFontPostScriptNameKey));
        return [UIFont fontWithName:fontNameKey size:CTFontGetSize(newFontRef)];
    }
    
    return nil;
}

- (UIFont *)fontWithBoldTrait:(BOOL)bold italicTrait:(BOOL)italic andSize:(CGFloat)size
{
    CTFontRef fontRef = (__bridge CTFontRef)self;
    NSString *familyName = (__bridge NSString *)(CTFontCopyName(fontRef, kCTFontFamilyNameKey));
    NSString *postScriptName = [UIFont postscriptNameFromFullName:familyName];
    return [[self class] fontWithName:postScriptName size:size boldTrait:bold italicTrait:italic];
}

- (UIFont *)fontWithBoldTrait:(BOOL)bold andItalicTrait:(BOOL)italic
{
    return [self fontWithBoldTrait:bold italicTrait:italic andSize:self.pointSize];
}

- (BOOL)isBold
{
    CTFontSymbolicTraits trait = CTFontGetSymbolicTraits((__bridge CTFontRef)self);
    
    if ((trait & kCTFontTraitBold) == kCTFontTraitBold)
        return YES;
    
    return NO;
}

- (BOOL)isItalic
{
    CTFontSymbolicTraits trait = CTFontGetSymbolicTraits((__bridge CTFontRef)self);
    
    if ((trait & kCTFontTraitItalic) == kCTFontTraitItalic)
        return YES;
    
    return NO;
}

@end
