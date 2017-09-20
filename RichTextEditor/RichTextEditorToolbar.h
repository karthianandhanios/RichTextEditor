//
//  RichTextEditorToolbar.h
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RichTextEditorToolbar;
typedef enum{
    RichTextEditorToolbarPresentationStyleModal,
    RichTextEditorToolbarPresentationStylePopover
}RichTextEditorToolbarPresentationStyle;

typedef enum{
    RichTextEditorFeatureNone							= 0,
    RichTextEditorFeatureBold							= 1 << 1,
    RichTextEditorFeatureItalic							= 1 << 2,
    RichTextEditorFeatureUnderline						= 1 << 3,
    RichTextEditorFeatureStrikeThrough					= 1 << 4,
    RichTextEditorFeatureTextBackgroundColor			= 1 << 5,
    RichTextEditorFeatureUnorderList                    = 1 << 6,
    RichTextEditorFeatureOrderList                      = 1 << 7,
    RichTextEditorFeatureblockQuotes                    = 1 << 8,
    RichTextEditorFeatureLink                           = 1 << 9,
    RichTextEditorFeaturePhoto                          = 1 << 10,
    RichTextEditorFeatureEmbededImage                   = 1 << 11,
    RichTextEditorFeatureAtMention                   = 1 << 12,
    RichTextEditorFeatureTrendingTag                   = 1 << 13,
    RichTextEditorFeatureAll							= 1 << 14
}RichTextEditorFeature;

@protocol RichTextEditorToolbarDelegate <UIScrollViewDelegate>
@required
- (void)richTextEditorToolbarDidSelectBold;
- (void)richTextEditorToolbarDidSelectItalic;
- (void)richTextEditorToolbarDidSelectUnderline;
- (void)richTextEditorToolbarDidSelectStrikeThrough;
- (void)richTextEditorToolbarDidSelectBulletPoint;
- (void)richTextEditorToolbarDidSelectNumberPoint;
- (void)richTextEditorToolbarDidSelectLink:(NSString *)linkString;
- (void)richTextEditorToolbarDidSelectblockQuotes;
- (void)richTextEditorToolbarDidSelectTextBackgroundColor;
- (void)richTextEditorToolbarDidSelectPhoto;
- (void)richTextEditorToolbarDidSelectEmbededImage;
- (void)richTextEditorToolbarDidSelectAtMention;
- (void)richTextEditorToolbarDidSelectTrendingTag;
@end
@protocol RichTextEditorToolbarDataSource <NSObject>
- (RichTextEditorToolbarPresentationStyle)presentationStyleForRichTextEditorToolbar;
- (UIModalPresentationStyle)modalPresentationStyleForRichTextEditorToolbar;
- (UIModalTransitionStyle)modalTransitionStyleForRichTextEditorToolbar;
- (UIViewController *)firsAvailableViewControllerForRichTextEditorToolbar;
- (RichTextEditorFeature)featuresEnabledForRichTextEditorToolbar;
@end


@interface RichTextEditorToolbar : UIScrollView<UIAlertViewDelegate>

@property (nonatomic, weak) id <RichTextEditorToolbarDelegate> toolBarDelegate;
@property (nonatomic, weak) id <RichTextEditorToolbarDataSource> dataSource;
@property (nonatomic, strong) UIView *customView;
- (id)initWithFrame:(CGRect)frame delegate:(id <RichTextEditorToolbarDelegate>)delegate dataSource:(id <RichTextEditorToolbarDataSource>)dataSource;
- (instancetype)initWithFrame:(CGRect)frame delegate:(id <RichTextEditorToolbarDelegate>)delegate dataSource:(id <RichTextEditorToolbarDataSource>)dataSource
                andCustomView:(UIView *)customizedView;
- (void)updateStateWithAttributes:(NSDictionary *)attributes isTypingAttribute:(BOOL)isTyping;
- (void)redraw;
-(void)changeEnableStatusOfAllButtons:(BOOL)enable;


@end
