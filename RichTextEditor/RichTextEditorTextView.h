//
//  RichTextEditorTextView.h
//  RichTextEditor
//
//  Created by Karthi A on 14/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RichTextEditorToolbar.h"

@class RichTextEditorTextView;

@protocol RichTextEditorDataSource <NSObject>
@optional
- (NSArray *)fontSizeSelectionForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (NSArray *)fontFamilySelectionForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (RichTextEditorToolbarPresentationStyle)presentationStyleForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (UIModalPresentationStyle)modalPresentationStyleForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (UIModalTransitionStyle)modalTransitionStyleForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (RichTextEditorFeature)featuresEnabledForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (BOOL)shouldDisplayToolbarForRichTextEditor:(RichTextEditorTextView *)richTextEditor;
- (BOOL)shouldDisplayRichTextOptionsInMenuControllerForRichTextEditor:(RichTextEditorTextView *)richTextEdiotor;
@end

@protocol RIchTextViewDelegate <NSObject>
-(void)handlePeopleView:(NSString *)keyword;
-(void)removePeopleView;
-(void)startMentioningUser;
-(void)cancelMentioningUser;
-(void)tappedPhotosBtn;
-(void)handleLink:(NSString *)Link;
-(void)setFrameForViews;
-(void)saveInDraft;
-(void)tappedEmbededImageBtn;
-(void)textViewTextEmpty:(BOOL)isEmpty;
-(void)getLinkInputWithEditOptionWithPrevLink:(NSString *)prevLink;
-(void)adjustInsectIsManualDragging:(BOOL)isManualdrag;
-(void)statusViewControllerIsSelected;
-(void)showTitleButton:(BOOL)showTitle;
-(void)handlePlaceHolder;
@end


@interface RichTextEditorTextView : UITextView<UITextViewDelegate,RichTextEditorToolbarDelegate,RichTextEditorToolbarDataSource>
{
    NSMutableAttributedString *bulletStyleString;
    UIFont *bulletFont;
    UIFont *normalFont;
      NSRange prevRange;
     BOOL isAutoCorrection;
    BOOL isTyping;
    NSDictionary *localTypingDict;
}
@property (nonatomic, weak) IBOutlet id <RichTextEditorDataSource> dataSource;
@property (nonatomic, strong) RichTextEditorToolbar *toolBar;
@property (nonatomic, assign) NSRange mentioningRange;
@property (nonatomic, assign) BOOL isMentioningMember;
@property (nonatomic, assign) BOOL canMentionMember;
@property (nonatomic, strong) UITextField*  placeHolderTextField;
@property (nonatomic, assign) RichTextEditorFeature toolBarFeatures;
@property (nonatomic, assign) CGFloat prevContentHt;
@property (nonatomic, assign) CGFloat contentHt;
@property (nonatomic, strong)UITextView *titleTextView;
@property (nonatomic, strong)UILabel * placeHolderTitleTextField;
@property(nonatomic,assign)NSInteger bottomInset;
@property(nonatomic,weak) id<RIchTextViewDelegate>richTextDelegate;
@property (nonatomic, assign) BOOL typingAttributesInProgress;
- (void)setBorderColor:(UIColor*)borderColor;
- (void)setBorderWidth:(CGFloat)borderWidth;
- (NSString *)htmlString;
-(void)renderQuoteForEdit;
-(void)renderQuoteForDrafts;
-(void)applyParagraphAttributeForListingForRange:(NSRange )range;
- (NSDictionary *)dictionaryAtIndex:(NSInteger)index;
-(void)updateLayerWithsNewAddedQuote:(BOOL)isNewQuote andStartRange:(NSRange) startRange;
-(void)handleLink:(NSString *)linkString;
-(void)deleteLink;
-(void)changePlaceholderHiddenStatus;
-(void)createTitleTextViewWithFrame:(CGRect)frame;
-(void)changeInsetOfTextViewWithTitle:(BOOL)isWithTitle withAttachement:(BOOL) isWIthAttachement;
-(void)setPlaceHolderForContent;
- (void)updateFrames;
@end
