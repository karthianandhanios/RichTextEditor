//
//  RichTextEditorToggleButton.m
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import "RichTextEditorToggleButton.h"

#if !__has_feature(objc_arc)
#error RichTextEditorToggleButton is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation RichTextEditorToggleButton
@synthesize onImageName,offImageName;
- (id)init
{
    if (self = [super init])
    {
        self.on = NO;
    }
    
    return self;
}

-(id)initWithImage:(NSString *) imageName
{
    if (self = [super init])
    {
        self.on = NO;
        [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [self changeBgColor:NO];
        _changeIcon =  false;
    }
    
    return self;
}

- (void)setOn:(BOOL)on
{
    _on = on;
    if (_changeIcon) {
        [self setImage:[self imageForState] forState:UIControlStateNormal];
    }
    else
    {
        [self changeBgColor:on];
    }
}
-(void)changeBgColor:(BOOL)on
{
    if (on) {
        self.backgroundColor = UIColorFromRGB(0xf2f3f7);
    }
    else
    {
        self.backgroundColor = UIColorFromRGB(0xffffff);
    }
}

- (UIImage *)imageForState
{
    return (self.on) ? [UIImage imageNamed:onImageName] : [UIImage imageNamed:offImageName];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
