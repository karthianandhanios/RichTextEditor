//
//  RichTextEditorToolbar.m
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//
#if !__has_feature(objc_arc)
#error RichTextEditorToolbar is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "RichTextEditorToolbar.h"
#import <CoreText/CoreText.h>
//#import "RichTextEditorPopover.h"
//#import "RichTextEditorColorPickerViewController.h"
#import "RichTextEditorToggleButton.h"
#import "UIFont+RichTextEditor.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define ITEM_SEPARATOR_SPACE 4
#define ITEM_TOP_AND_BOTTOM_BORDER 10
#define ITEM_WITH 48

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "RichTextEditorToolbar.h"
@interface RichTextEditorToolbar() 
//@property (nonatomic, strong) id <RichTextEditorPopover> popover;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBold;
@property (nonatomic, strong) RichTextEditorToggleButton *btnItalic;
@property (nonatomic, strong) RichTextEditorToggleButton *btnUnderline;
@property (nonatomic, strong) RichTextEditorToggleButton *btnStrikeThrough;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBackgroundColor;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBulletPoint;
@property (nonatomic, strong) RichTextEditorToggleButton *btnNumberPoint;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBlockQuotes;
@property (nonatomic, strong) RichTextEditorToggleButton *btnLink;
@property (nonatomic, strong) RichTextEditorToggleButton *photosBtn;
@property (nonatomic, strong) RichTextEditorToggleButton *embededImageBtn;
@property (nonatomic, strong) RichTextEditorToggleButton *atMentionBtn;
@property (nonatomic, strong) RichTextEditorToggleButton *trandingTagButton;
@end


@implementation RichTextEditorToolbar
@synthesize customView,toolBarDelegate;
#pragma mark - Initialization -

- (id)initWithFrame:(CGRect)frame delegate:(id <RichTextEditorToolbarDelegate>)delegate dataSource:(id <RichTextEditorToolbarDataSource>)dataSource
{
    if (self = [super initWithFrame:frame])
    {
        self.toolBarDelegate = delegate;
        self.dataSource = dataSource;
        
        self.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = UIColorFromRGB(0xE8e8E8).CGColor;
        [self setShowsHorizontalScrollIndicator:NO];
        [self initializeButtons];
    }
    
    return self;
}

#pragma mark - Public Methods -

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)redraw
{
    [self populateToolbar];
}

-(void)changeEnableStatusOfAllButtons:(BOOL)enable
{
    CGFloat alpha = 1.0;
    if (!enable) {
        alpha = .3;
    }
    [self changeAlpha:alpha];
    
    {
        //    self.customView.userInteractionEnabled = enable;
        //    self.photosBtn.enabled =enable;
        self.btnItalic.enabled =enable;
        self.btnBold.enabled =enable;
        self.btnLink.enabled =enable;
        self.btnUnderline.enabled =enable;
        self.btnNumberPoint.enabled =enable;
        self.btnStrikeThrough.enabled =enable;
        self.btnBulletPoint.enabled =enable;
        self.embededImageBtn.enabled =enable;
        self.btnBlockQuotes.enabled =enable;
        self.btnBackgroundColor.enabled =enable;
    }
    
}
-(void)changeAlpha:(CGFloat)alpha
{
    //    self.customView.alpha = alpha;
    //     self.photosBtn.alpha = alpha;
    self.btnItalic.alpha = alpha;
    self.btnBold.alpha = alpha;
    self.btnLink.alpha = alpha;
    self.btnUnderline.alpha = alpha;
    self.btnNumberPoint.alpha = alpha;
    self.btnStrikeThrough.alpha = alpha;
    self.btnBulletPoint.alpha = alpha;
    self.embededImageBtn.alpha = alpha;
    self.btnBlockQuotes.alpha = alpha;
    self.btnBackgroundColor.alpha = alpha;
}

- (void)updateStateWithAttributes:(NSDictionary *)attributes isTypingAttribute:(BOOL)isTyping
{
    BOOL isQuoted = false;
    
    NSString * listingstyle = [attributes objectForKey:@"ListStyle"];
    
    if (isTyping) {
        UIFont *font = [attributes objectForKey:NSFontAttributeName];
        self.btnBold.on = [font isBold] ? true : false;
        self.btnItalic.on = [font isItalic] ? true : false;
        
    }
    else
    {
        self.btnBold.on = [attributes objectForKey:@"bold"] ? true : false;
        self.btnItalic.on = [attributes objectForKey:@"italic"] ? true : false;
    }
    
    isQuoted = [attributes objectForKey:@"QuoteStyle"] ? true : false;
    self.btnBlockQuotes.on=isQuoted;
    
    self.btnBulletPoint.on = [listingstyle isEqualToString:@"BulletList"] ? true : false;
    self.btnNumberPoint.on = [listingstyle isEqualToString:@"NumberList"] ? true : false;
    
    self.btnBackgroundColor.on = [attributes objectForKey:NSBackgroundColorAttributeName] ? true : false;
    self.btnLink.on = [attributes objectForKey:NSLinkAttributeName] ? true : false;
    self.btnUnderline.on = [attributes objectForKey:NSUnderlineStyleAttributeName] ? true : false;
    
    NSNumber *Strikethrough = [attributes objectForKey:NSStrikethroughStyleAttributeName];
    
    if ((Strikethrough && Strikethrough.intValue != 0))
        self.btnStrikeThrough.on = true;
    else
        self.btnStrikeThrough.on = false;
    
    NSNumber *underline = [attributes objectForKey:NSUnderlineStyleAttributeName];
    
    if (underline && underline.intValue != 0) {
        self.btnUnderline.on = true;
    }
    else
        self.btnUnderline.on = false;
    
    BOOL isListingStyle = [listingstyle isKindOfClass:[NSString class]] ? true : false;
    
    [self quoteIsEnabled:isQuoted andListingEnabled:isListingStyle];
}


-(void)quoteIsEnabled:(BOOL)isQuote andListingEnabled:(BOOL)isListing
{
    self.btnBulletPoint.enabled = !isQuote ;
    self.btnNumberPoint.enabled = !isQuote ;
    self.btnBackgroundColor.enabled = !isQuote;
    self.btnLink.enabled = !isQuote;
    if (isQuote || isListing) {
        self.embededImageBtn.enabled = false;
    }
    else
    {
        self.embededImageBtn.enabled = true;
    }
    self.btnBlockQuotes.enabled = !isListing;
}

#pragma mark - IBActions -

-(void)selectPhotos:(UIButton *)sender
{
    ALAuthorizationStatus status=[ALAssetsLibrary authorizationStatus];
    if (status!=ALAuthorizationStatusAuthorized && status!=ALAuthorizationStatusNotDetermined)
    {
        UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"" message:@"Please change your settings to access photos" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    //    self.photosBtn.on = YES;    // no status change in this button
    [self.toolBarDelegate richTextEditorToolbarDidSelectPhoto];
}

- (void)boldSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectBold];
}

- (void)italicSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectItalic];
}

- (void)underLineSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectUnderline];
}

- (void)strikeThroughSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectStrikeThrough];
}

- (void)bulletPointSelected:(UIButton *)sender
{
    
    [self.toolBarDelegate richTextEditorToolbarDidSelectBulletPoint];
}

- (void)numberPointSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectNumberPoint];
}

-(void)LinkSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectLink:nil];
}

-(void)blockQuotesSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectblockQuotes];
}

- (void)textBackgroundColorSelected:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectTextBackgroundColor];
}

-(void)embededImageSelected:(UIButton*)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectEmbededImage];
}

-(void)atMentionBtnClicked:(UIButton *)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectAtMention];
}

-(void)trendingTagBtnClicked:(UIButton*)sender
{
    [self.toolBarDelegate richTextEditorToolbarDidSelectTrendingTag];
}

#pragma mark - Private Methods -

- (void)populateToolbar
{
    // Remove any existing subviews.
    for (UIView *subView in self.subviews)
    {
        [subView removeFromSuperview];
    }
    
    // Populate the toolbar with the given features.
    RichTextEditorFeature features = [self.dataSource featuresEnabledForRichTextEditorToolbar];
    UIView *lastAddedView = nil;
    
    self.hidden = (features == RichTextEditorFeatureNone);
    
    if (self.hidden)
        return;
    
    if(self.customView)
    {
        [self addView:self.customView afterView:lastAddedView withSpacing:NO];
        lastAddedView = self.customView;
    }
    /*
    // photosBtn
    
    if (features & RichTextEditorFeaturePhoto || features & RichTextEditorFeatureAll) {
        [self addView:self.photosBtn afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.photosBtn;
    } */
    // Bold
    if (features & RichTextEditorFeatureBold || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnBold afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnBold;
    }
    
    // Italic
    if (features & RichTextEditorFeatureItalic || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnItalic afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnItalic;
    }
    
    // Underline
    if (features & RichTextEditorFeatureUnderline || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnUnderline afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnUnderline;
    }
    
    // Strikethrough
    if (features & RichTextEditorFeatureStrikeThrough || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnStrikeThrough afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnStrikeThrough;
    }
    
    
    //UnorderList
    
    if (features & RichTextEditorFeatureUnorderList || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnBulletPoint afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnBulletPoint;
    }
    
    //Numbered List
    if (features & RichTextEditorFeatureOrderList || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnNumberPoint afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnNumberPoint;
    }
    
    // Background color
    if (features & RichTextEditorFeatureTextBackgroundColor || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnBackgroundColor afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnBackgroundColor;
    }

    // inline image
    if (features & RichTextEditorFeatureEmbededImage || features & RichTextEditorFeatureAll) {
        [self addView:self.embededImageBtn afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.embededImageBtn;
    }
    //LINK
/*    if (features & RichTextEditorFeatureLink || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnLink afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnLink;
    }
    */
      /*
    //block Quotes
    if (features & RichTextEditorFeatureblockQuotes || features & RichTextEditorFeatureAll)
    {
        [self addView:self.btnBlockQuotes afterView:lastAddedView withSpacing:YES];
        lastAddedView = self.btnBlockQuotes;
    }
    
     if (features & RichTextEditorFeatureAtMention || features & RichTextEditorFeatureAll) {
     [self addView:self.atMentionBtn afterView:lastAddedView withSpacing:YES];
     lastAddedView = self.atMentionBtn;
     }
     if (features & RichTextEditorFeatureTrendingTag || features & RichTextEditorFeatureAll) {
     [self addView:self.trandingTagButton afterView:lastAddedView withSpacing:YES];
     lastAddedView = self.trandingTagButton;
     }*/
}

- (void)initializeButtons
{
    
    self.btnBold = [self buttonWithImageNamed:@"bold.png"
                                  andSelector:@selector(boldSelected:)];
    
    self.btnBold.onImageName = @"bold-sel.png" ;
    self.btnBold.offImageName = @"bold.png" ;
    
    self.btnItalic = [self buttonWithImageNamed:@"italic.png"
                                    andSelector:@selector(italicSelected:)];
    
    self.btnItalic.onImageName = @"italic-sel.png";
    self.btnItalic.offImageName =@"italic.png";
    
    self.btnUnderline = [self buttonWithImageNamed:@"underline.png"
                                       andSelector:@selector(underLineSelected:)];
    
    self.btnUnderline.onImageName = @"underline-sel.png";
    self.btnUnderline.offImageName = @"underline.png";
    
    
    self.btnStrikeThrough = [self buttonWithImageNamed:@"strike.png"
                                           andSelector:@selector(strikeThroughSelected:)];
    
    self.btnStrikeThrough.onImageName = @"strike-sel.png";
    self.btnStrikeThrough.offImageName = @"strike.png";
    
    self.btnBackgroundColor = [self buttonWithImageNamed:@"highlight.png"
                                             andSelector:@selector(textBackgroundColorSelected:)];
    
    self.btnBackgroundColor.onImageName = @"highlight-sel.png";
    self.btnBackgroundColor.offImageName = @"highlight.png";
    
    self.btnBulletPoint = [self buttonWithImageNamed:@"bullet.png"
                                         andSelector:@selector(bulletPointSelected:)];
    self.btnBulletPoint.onImageName = @"bullet-sel.png";
    self.btnBulletPoint.offImageName = @"bullet.png";
    
    self.btnNumberPoint = [self buttonWithImageNamed:@"numbered.png"
                                         andSelector:@selector(numberPointSelected:)];
    
    self.btnNumberPoint.onImageName = @"numbered-sel.png";
    self.btnNumberPoint.offImageName = @"numbered.png";
    
    self.btnBlockQuotes = [self buttonWithImageNamed:@"quote.png"
                                         andSelector:@selector(blockQuotesSelected:)];
    self.btnBlockQuotes.onImageName = @"quote-sel.png";
    self.btnBlockQuotes.offImageName = @"quote.png";
    
    self.btnLink = [self buttonWithImageNamed:@"link.png"
                                  andSelector:@selector(LinkSelected:)];
    self.btnLink.onImageName = @"link-sel.png";
    self.btnLink.offImageName = @"link.png";
    
    self.photosBtn =[self buttonWithImageNamed:@"attachment"
                                   andSelector:@selector(selectPhotos:)];
    self.photosBtn.onImageName = @"attachment.png";
    self.photosBtn.offImageName = @"attachment.png";
    
    self.embededImageBtn = [self buttonWithImageNamed:@"embedImage.png" andSelector:@selector(embededImageSelected:)];
    
    self.embededImageBtn.onImageName = @"embedImage.png";
    self.embededImageBtn.offImageName = @"embedImage.png";
    
    self.atMentionBtn = [self buttonWithImageNamed:@"bullet.png" andSelector:@selector(atMentionBtnClicked:)];
    
    self.atMentionBtn.onImageName = @"bullet.png";
    self.atMentionBtn.offImageName = @"bullet.png";
    
    self.trandingTagButton = [self buttonWithImageNamed:@"numbered.png" andSelector:@selector(trendingTagBtnClicked:)];
    
    self.trandingTagButton.onImageName = @"numbered.png";
    self.trandingTagButton.offImageName = @"numbered.png";
    
    
    
}

- (RichTextEditorToggleButton *)buttonWithImageNamed:(NSString *)image width:(NSInteger)width andSelector:(SEL)selector
{
    RichTextEditorToggleButton *button = [[RichTextEditorToggleButton alloc] init];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, width, 0)];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
    [button.titleLabel setTextColor:[UIColor blackColor]];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    button.layer.cornerRadius = 2.0;
    button.layer.borderWidth = 1.0;
    return button;
}

- (RichTextEditorToggleButton *)buttonWithImageNamed:(NSString *)image andSelector:(SEL)selector
{
    return [self buttonWithImageNamed:image width:ITEM_WITH andSelector:selector];
}

//- (UIView *)separatorView
//{
//	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, self.frame.size.height)];
//	view.backgroundColor = [UIColor lightGrayColor];
//
//	return view;
//}

- (void)addView:(UIView *)view afterView:(UIView *)otherView withSpacing:(BOOL)space
{
    CGRect otherViewRect = (otherView) ? otherView.frame : CGRectZero;
    CGRect rect = view.frame;
    rect.origin.x = otherViewRect.size.width + otherViewRect.origin.x;
    if (space)
        rect.origin.x += ITEM_SEPARATOR_SPACE;
    
    rect.origin.y = ITEM_TOP_AND_BOTTOM_BORDER;
    rect.size.height = self.frame.size.height - (2*ITEM_TOP_AND_BOTTOM_BORDER) -1 ;
    view.frame = rect;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:view];
    [self updateContentSize];
}

- (void)updateContentSize
{
    NSInteger maxViewlocation = 0;
    
    for (UIView *view in self.subviews)
    {
        NSInteger endLocation = view.frame.size.width + view.frame.origin.x;
        
        if (endLocation > maxViewlocation)
            maxViewlocation = endLocation;
    }
    
    self.contentSize = CGSizeMake(maxViewlocation+ITEM_SEPARATOR_SPACE, self.frame.size.height);
}

@end
