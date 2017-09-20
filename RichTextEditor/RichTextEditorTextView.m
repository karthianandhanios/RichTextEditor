//
//  RichTextEditorTextView.m
//  RichTextEditor
//
//  Created by Karthi A on 14/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import "RichTextEditorTextView.h"
#import "UIFont+RichTextEditor.h"
#import "NSAttributedString+RichTextEditor.h"

#define RICHTEXTEDITOR_TOOLBAR_HEIGHT 55

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define quoteStyleString @"QuoteStyle"
#define listingStyleString @"ListStyle"
#define numberListKeyValue @"NumberList"
#define bulletListkeyValue @"BulletList"
#define stylePrependString @"ListPrepend"
#define mentionMember @"memberLink"
#define styleWt 4

@interface RichTextEditorToolbar ()
- (void)removeAttributeForRange:(NSRange)range forKey:(NSString *)key;
- (void)removeAttributeForRange:(NSRange)range;
@end
CGFloat totalHt;
@implementation RichTextEditorTextView

-(instancetype)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
    if (self) {
          [self commonInitialization];
    }
    return self;
}
-(instancetype)init
{
    self = [super init];
    if (self) {
         [self commonInitialization];
    }
    return  self;
}

-(instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
  self =  [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self commonInitialization];
    }
    return  self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
         [self commonInitialization];
    }
    return self;
}

-(void)commonInitialization
{
    self.delegate =  self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.toolBar = [[RichTextEditorToolbar alloc] initWithFrame:CGRectMake(0 ,0, [self currentScreenBoundsDependOnOrientation].size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)
                                                       delegate:self
                                                     dataSource:self];
    
    _toolBarFeatures = RichTextEditorFeatureNone;

    bulletFont = [UIFont fontWithName:@"ArialRoundedMTBold" size:26];
    normalFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    
     NSString *plainBulletString = @"  . ";
    
    bulletStyleString=[[NSMutableAttributedString alloc]initWithString:plainBulletString];
    
    [bulletStyleString beginEditing];
    [bulletStyleString addAttribute:NSFontAttributeName value:bulletFont range:NSMakeRange(0,styleWt-1)];
    [bulletStyleString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:3.5] range:NSMakeRange(0, styleWt - 1)];
    [bulletStyleString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(styleWt - 1 , 1)];
    [bulletStyleString addAttribute:stylePrependString value:@"bulletDot" range:NSMakeRange(0, bulletStyleString.length)];
    [bulletStyleString endEditing];
    isAutoCorrection= false;
    self.font = normalFont;
    localTypingDict = [[NSDictionary alloc]init];
}


- (CGRect)currentScreenBoundsDependOnOrientation
{
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        screenBounds.size = CGSizeMake(width, height);
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
        screenBounds.size = CGSizeMake(height, width);
    }
    
    return screenBounds ;
}


-(void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

-(void)changePlaceholderHiddenStatus
{
    
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    
    CGFloat cursorHt = 20;
    CGRect originalRect = [super caretRectForPosition:position];
    CGFloat prevHt = originalRect.size.height;
    CGFloat yposition = (prevHt - cursorHt);
    originalRect.origin.y += yposition;
    originalRect.size.height = cursorHt;
    return originalRect;
}


#pragma -mark  Keyboard Notification

-(void)keyboardFrameChanged:(NSNotification *)notification
{
    NSValue *keyboardEndFrameValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect baseRect=[keyboardEndFrameValue CGRectValue];
    CGRect converted=[self convertRect:baseRect fromView:nil];
    if (converted.origin.y >= converted.size.height) {
        [self setHeight:self.contentHt-converted.size.height];
    }
}

#pragma -mark  scroll delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    

}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}

-(BOOL)canBecomeFirstResponder
{
    return true;
}

-(BOOL)canResignFirstResponder
{
    return true;
}
#pragma -mark  Text delegate

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [_richTextDelegate handlePlaceHolder];
}

-(void)textViewDidChangeSelection:(UITextView *)textView
{
    if (isTyping) {
        [self setTypingAttributes:localTypingDict];
    }
    
    if (localTypingDict.count <= 0) {
        localTypingDict = self.typingAttributes ;
    }
    
    if (self.selectedRange.length == 0 && !isTyping && [self.attributedText length] >0 ) {  //handle the case of typing in listing dot and number with size of styleWt
        
        NSRange currentParagraphRange = [self.attributedText
                                         firstParagraphRangeFromTextRange:self.selectedRange];
        NSDictionary *dictionary = [self dictionaryAtIndex:currentParagraphRange.location];
        
        if ([dictionary objectForKey:listingStyleString]) {
            
            if (currentParagraphRange.location<=self.selectedRange.location && self.selectedRange.location <currentParagraphRange.location+styleWt && currentParagraphRange.length > 0 && prevRange.length != 1)  // to use this logic to prevent to selection in bullet or number
            {
                prevRange.location = 0;
                self.selectedRange = NSMakeRange(currentParagraphRange.location+styleWt, 0);
            }
        }
    }
    isTyping = NO;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length > 0) {
           [_richTextDelegate handlePlaceHolder];
    }
     //autocorrection
    if (!isAutoCorrection && ([text length] >1 || range.length >1)) {
        isAutoCorrection = true;
        NSRange pSelectedRange = self.selectedRange;
        
        NSDictionary *selRangeDict = [self dictionaryAtIndex:range.location];
        NSAttributedString *str = [[NSAttributedString alloc]initWithString:text attributes:selRangeDict];
        NSInteger textLength = self.text.length;
        NSMutableAttributedString * textViewString = self.textStorage;
        [textViewString beginEditing];
        [textViewString replaceCharactersInRange:range withAttributedString:str];
        
    
        NSInteger location = range.location+range.length-1;
        NSRange changedRange = NSMakeRange(range.location, [text length]);
        NSInteger endloc = changedRange.location +changedRange.length;
        
        
        if (text.length >0 && range.location >0 && range.location  < self.text.length) {
            NSRange listingParaRange = [self.attributedText firstParagraphRangeFromTextRange:range];
            NSDictionary *listingDict = [self dictionaryAtIndex:listingParaRange.location];
            NSString *listingStyleKey = [listingDict objectForKey: listingStyleString];
            
            if ([listingStyleKey isEqualToString:bulletListkeyValue] && endloc < self.text.length ) {
                [textViewString addAttribute:listingStyleString value:bulletListkeyValue range:changedRange];
            }
            else if ([listingStyleKey isEqualToString:numberListKeyValue] && endloc < self.text.length)
            {
                [textViewString addAttribute:listingStyleString value:numberListKeyValue range:changedRange];
            }
        }
        
        [textViewString endEditing];
        
        NSInteger diff = text.length - range.length;
        pSelectedRange.location +=diff;
        self.selectedRange = pSelectedRange;
        

//        [self.textViewCustomDelegate saveInDraft];
        
        if ([text isEqualToString:@""]) {
            self.selectedRange = NSMakeRange(range.location, 0);
        }
        else
        {
            self.selectedRange = NSMakeRange(range.location + text.length, 0);
        }
        
        [self scrollRangeToVisible:self.selectedRange];
//        [self.textViewCustomDelegate setFrameForViews];
        
    
        isAutoCorrection = false;
        [self changePlaceholderHiddenStatus];
        return NO;
        
    }
    if (isAutoCorrection) {
        isAutoCorrection = false;
        return NO;
    }
    // autocorrection end
    
    isAutoCorrection = false;
    isTyping = YES;
    prevRange=range;
    
    if (text.length > 0 && [text isEqualToString:@"\n"]) {
        NSMutableDictionary *typingAttrib = [self.typingAttributes mutableCopy];
        
        UIColor *bgColor = [typingAttrib objectForKey:NSBackgroundColorAttributeName];
        if (bgColor) {
            [typingAttrib removeObjectForKey:NSBackgroundColorAttributeName];
            [typingAttrib removeObjectForKey:listingStyleString];
            [self setTypingAttributes:typingAttrib];
        }
    }
    else if (range.length==0 && text.length > 0 && range.location >0)
    {
        NSString *prevChar = [self.text substringWithRange:NSMakeRange(range.location - 1, 1)];
        NSInteger lastParaLastChatloc  = range.location - 2;
        if ([prevChar isEqualToString:@"\n"] && lastParaLastChatloc >=0) {
            NSDictionary *dictForPrevBgcolor = [self dictionaryAtIndex:lastParaLastChatloc];
            UIColor *color =  [dictForPrevBgcolor objectForKey:NSBackgroundColorAttributeName];
            if (color) {
                [self applyAttributeToTypingAttribute:color forKey:NSBackgroundColorAttributeName];
            }
        }
    }
    
    if(range.length == 1)
    {
        NSString *deletedString = [[self.attributedText attributedSubstringFromRange:range]string];
        
        NSRange prevParagraphRange = [self.attributedText
                                      firstParagraphRangeFromTextRange:range];
        NSDictionary *dictionary = [self dictionaryAtIndex:range.location];
        NSString *listStyle=[dictionary objectForKey:listingStyleString];
        
        if ([listStyle isEqualToString:bulletListkeyValue]) {
            NSString *bulletStyleText=nil;
            
            if (range.location >= (styleWt-1) && self.text.length >=styleWt) {
                bulletStyleText=[textView.text substringWithRange:NSMakeRange(range.location-(styleWt-1)
                                                                              , styleWt)];
            }
            
            if ([bulletStyleText isEqualToString:bulletStyleString.string]) {
                
                NSMutableAttributedString *attribString=self.textStorage;
                [attribString beginEditing];
                NSInteger delLoc ;
                if (prevParagraphRange.location >0) {
                    delLoc =1;
                }
                else
                {
                    delLoc =0;
                }
                NSRange currentParaRange = [self.attributedText firstParagraphRangeFromTextRange:range];
                [attribString removeAttribute:listingStyleString range:currentParaRange];
                NSInteger temPdelLoc = prevParagraphRange.location-delLoc;
                if (temPdelLoc >= 0 && (temPdelLoc + delLoc+ styleWt) <= attribString.length) {
                    [attribString replaceCharactersInRange:NSMakeRange(prevParagraphRange.location-delLoc,styleWt+delLoc) withString:@""];
                }
                [attribString endEditing];
                NSInteger selLoc = range.location - styleWt;
                if (selLoc<0) {
                    selLoc = 0;
                }
                self.selectedRange=NSMakeRange(selLoc,0);
                [self changeListingStyleOfBelowParagraph];
                localTypingDict = self.typingAttributes;
                [self changePlaceholderHiddenStatus];
                return false;
            }
        }
        else if ([listStyle isEqualToString:numberListKeyValue])
        {
            NSString *numberStyleText=nil;
            
            if (range.location >= (styleWt-1) && self.text.length >=styleWt) {
                numberStyleText=[textView.text substringWithRange:NSMakeRange(range.location-(styleWt-1)
                                                                              , styleWt)];
            }
            if ( [self isEmptyLineInText:numberStyleText isNumberList:YES]) {
                NSMutableAttributedString *attribString = self.textStorage;
                [attribString beginEditing];
                NSInteger number=[self getParagrapNumberInRange:prevParagraphRange];
                NSInteger delLoc;
                if (prevParagraphRange.location >0) {
                    delLoc =1;
                }
                else
                {
                    delLoc =0;
                }
                
                NSRange currentParaRange = [self.attributedText firstParagraphRangeFromTextRange:range];
                [attribString removeAttribute:listingStyleString range:currentParaRange];
                NSInteger temPdelLoc = prevParagraphRange.location-delLoc;
                if (temPdelLoc >= 0 && (temPdelLoc + delLoc+ styleWt) <= attribString.length) {
                    [attribString replaceCharactersInRange:NSMakeRange(prevParagraphRange.location-delLoc,styleWt+delLoc) withString:@""];
                }
                [attribString endEditing];
                self.selectedRange=NSMakeRange(range.location-styleWt,0);
                NSInteger length=self.attributedText.length - (self.selectedRange.location+prevParagraphRange.length);
                if (length >0) {
                    [self changeNumberOfParagraph:NSMakeRange(self.selectedRange.location+prevParagraphRange.length, length) withIsInc:NO previousNumber:number-1];
                }
                self.selectedRange=NSMakeRange(range.location-styleWt,0);
                localTypingDict = self.typingAttributes;
                [self changePlaceholderHiddenStatus];
                return false;
            }
        }
        NSInteger inx = range.location;
        NSDictionary *dictForMem = [self dictionaryAtIndex:inx];
        
        if([dictForMem objectForKey:mentionMember])
        {
            NSRange  menitionRange = [self.attributedText getAttributeRangeAtIndex:inx andAttribute:mentionMember];
            NSMutableAttributedString *attribString = self.textStorage;
            [attribString beginEditing];
            NSInteger tempMention = menitionRange.location + menitionRange.length;
            if (tempMention <= attribString.length) {
                [attribString replaceCharactersInRange:menitionRange withString:@""];
            }
            [attribString endEditing];
            self.selectedRange = NSMakeRange(menitionRange.location, 0);
            localTypingDict = self.typingAttributes;
            [self changePlaceholderHiddenStatus];
            return NO;
        }
    }
     localTypingDict = self.typingAttributes;
    return true;
}

-(void)textViewDidChange:(UITextView *)textView
{
    [_richTextDelegate handlePlaceHolder];
    NSInteger currentLocation = textView.selectedRange.location;
    if (prevRange.length==0 && textView.selectedRange.location >prevRange.location ) {
        
        BOOL isFrameChanged = false ;
        // applying basic attribute
        NSURL * linkAttribute = [self.typingAttributes objectForKey:NSLinkAttributeName];
        if (linkAttribute) {
            [self applyAttribute:NSLinkAttributeName];
        }
        NSInteger lenth=textView.selectedRange.location-prevRange.location;
        
        NSString *newText=[textView.text substringWithRange:NSMakeRange(prevRange.location, lenth)];
        
        NSInteger selLocation = self.selectedRange.location ;
        NSRange currentParagraphRange = NSMakeRange(NSNotFound, NSNotFound);
        if (selLocation >0) {
            currentParagraphRange = [self.attributedText
                                     firstParagraphRangeFromTextRange:NSMakeRange(self.selectedRange.location-1, 1)];
        }
        
        NSDictionary *dictionary;
        if (currentParagraphRange.location != NSNotFound) {
            dictionary  = [self dictionaryAtIndex:currentParagraphRange.location];
        }
        NSString *listStyle=[dictionary objectForKey:listingStyleString];
        
        if (selLocation >0 ) {
            
            NSRange prevParagraphRange = [self.attributedText
                                          firstParagraphRangeFromTextRange:NSMakeRange(selLocation-1,1)];
            NSDictionary *newDict = [self dictionaryAtIndex:prevParagraphRange.location];
            
        }  //quote
        
        if ([newText isEqualToString:@"\n"] && [listStyle isEqualToString:bulletListkeyValue]) {
            NSDictionary *typingAttrib = self.typingAttributes;
            [self applybulletStyleToSelectedRangeForNewLine:YES];  // apply bullet here
            [self setTypingAttributes:typingAttrib];
        }
        else if ([newText isEqualToString:@"\n"] && [listStyle isEqualToString:numberListKeyValue])
        {
            NSDictionary *typingAttrib = self.typingAttributes;
            [self applyNumberStyleToSelectedRangeForNewLine:YES];
            [self setTypingAttributes:typingAttrib];
        }
        else
        {
            NSRange ParagraphRange = [self.attributedText
                                      firstParagraphRangeFromTextRange:self.selectedRange];
            NSInteger currStart =ParagraphRange.location;
            if (ParagraphRange.length >0) {
                currStart = ParagraphRange.location + 1;
            }
            NSDictionary *dictionary = [self dictionaryAtIndex:currStart];
            
            NSString *lStyle=[dictionary objectForKey:listingStyleString];
            
            if ([lStyle isEqualToString:bulletListkeyValue] && self.selectedRange.location > ParagraphRange.location+ styleWt)
            {
                NSDictionary *typingAttrib = [self dictionaryAtIndex:self.selectedRange.location];
                [self applyAttributes:bulletListkeyValue forKey:listingStyleString atRange:ParagraphRange];
                [self setTypingAttributes:typingAttrib];
            }
            
            else if ([lStyle isEqualToString:numberListKeyValue] && self.selectedRange.location > ParagraphRange.location+ styleWt)
            {
                NSDictionary *typingAttrib = self.typingAttributes;
                [self applyAttributes:numberListKeyValue forKey:listingStyleString atRange:ParagraphRange];
                [self setTypingAttributes:typingAttrib];
            }
            
            NSDictionary *tDict;
            if (prevRange.location > 0) {
                tDict = [self dictionaryAtIndex:prevRange.location-1];
            }
            else
            {
                tDict = [self dictionaryAtIndex:self.selectedRange.location];
            }
            
            //end
            
            self.selectedRange = NSMakeRange(currentLocation, 0);
        }
        
    }
    
    [self updateToolbarState];
    [self scrollRangeToVisible:self.selectedRange];
    prevRange = self.selectedRange;
    

}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    
}
#pragma mark - RichTextEditorToolbarDataSource Methods -

- (NSArray *)fontFamilySelectionForRichTextEditorToolbar
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(fontFamilySelectionForRichTextEditor:)])
    {
        return [self.dataSource fontFamilySelectionForRichTextEditor:self];
    }
    return nil;
}


- (RichTextEditorToolbarPresentationStyle)presentationStyleForRichTextEditorToolbar
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(presentationStyleForRichTextEditor:)])
    {
        return [self.dataSource presentationStyleForRichTextEditor:self];
    }
    
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    ? RichTextEditorToolbarPresentationStylePopover
    : RichTextEditorToolbarPresentationStyleModal;
}

- (UIModalPresentationStyle)modalPresentationStyleForRichTextEditorToolbar
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(modalPresentationStyleForRichTextEditor:)])
    {
        return [self.dataSource modalPresentationStyleForRichTextEditor:self];
    }
    
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    ? UIModalPresentationFormSheet
    : UIModalPresentationFullScreen;
}

- (UIModalTransitionStyle)modalTransitionStyleForRichTextEditorToolbar
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(modalTransitionStyleForRichTextEditor:)])
    {
        return [self.dataSource modalTransitionStyleForRichTextEditor:self];
    }
    
    return UIModalTransitionStyleCoverVertical;
}

- (RichTextEditorFeature)featuresEnabledForRichTextEditorToolbar
{
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(featuresEnabledForRichTextEditor:)])
    {
        return [self.dataSource featuresEnabledForRichTextEditor:self];
    }
    return _toolBarFeatures;
}

#pragma mark - RichTextEditorToolbarDelegate Methods 

- (void)richTextEditorToolbarDidSelectBold  //reviewed
{
     UIFont *font;
    if(self.selectedRange.length > 0)
    {
        NSRange preSelectedRange = self.selectedRange;
        [self applyStyleForSelectedRange:@"Bold"];
        self.selectedRange =   preSelectedRange;
    }
    else
    {
        font = [self.typingAttributes objectForKey:NSFontAttributeName];
        [self applyFontAttributesToSelectedRangeWithBoldTrait:[NSNumber numberWithBool:![font isBold]] italicTrait:nil fontName:nil fontSize:nil];
    }
    
    [self updateToolbarState];
    //    [self.textViewCustomDelegate saveInDraft];
}

- (void)richTextEditorToolbarDidSelectItalic //reviewed
{
    if(self.selectedRange.length > 0)
    {
        NSRange preSelectedRange = self.selectedRange;
        [self applyStyleForSelectedRange:@"Italic"];
        self.selectedRange =   preSelectedRange;
    }
    else
    {
        UIFont *font;
        font = [self.typingAttributes objectForKey:NSFontAttributeName];
        [self applyFontAttributesToSelectedRangeWithBoldTrait:nil italicTrait:[NSNumber numberWithBool:![font isItalic]] fontName:nil fontSize:nil];
    }
    [self updateToolbarState];
    //    [self.textViewCustomDelegate saveInDraft];
}

- (void)richTextEditorToolbarDidSelectUnderline // reviewed
{
    NSRange range = self.selectedRange;
    if (self.selectedRange.length == 0) {
        NSDictionary *dict = [self typingAttributes];
        NSNumber *existingUnderlineStyle = [dict objectForKey:NSUnderlineStyleAttributeName];
        if (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone)
            existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
        else
            existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleNone];
        
        [self applyAttributeToTypingAttribute:existingUnderlineStyle forKey:NSUnderlineStyleAttributeName];
        self.typingAttributesInProgress = true;
    }
    else
    {
        [self applyStyleForSelectedRange:NSUnderlineStyleAttributeName];
    }
    
    [self setSelectedRange:range];
    [self updateToolbarState];
//    [self.textViewCustomDelegate saveInDraft];
}

- (void)richTextEditorToolbarDidSelectStrikeThrough // reviewed
{
    NSRange range = self.selectedRange;
    if (self.selectedRange.length == 0) {
        NSDictionary *dict = [self typingAttributes];
        NSNumber *existingUnderlineStyle = [dict objectForKey:NSStrikethroughStyleAttributeName];
        if (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone)
            existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
        else
            existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleNone];
        
        [self applyAttributeToTypingAttribute:existingUnderlineStyle forKey:NSStrikethroughStyleAttributeName];
        self.typingAttributesInProgress = true;
    }
    else
    {
        [self applyStyleForSelectedRange:NSStrikethroughStyleAttributeName];
    }
    
    [self setSelectedRange:range];
    [self updateToolbarState];
//    [self.textViewCustomDelegate saveInDraft];
}

- (void)richTextEditorToolbarDidSelectBulletPoint
{
    
    NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:self.selectedRange];
    
    BOOL isAllLineStyled=[self isAllLinesStyled:rangeOfParagraphsInSelectedText withStyle:bulletListkeyValue forKey:listingStyleString];
    
    [self applybulletStyleToSelectedRangeForNewLine:NO]; //should enable ########
    
    NSInteger prevSelectedLoc = self.selectedRange.location;
    NSInteger endLoc = self.selectedRange.location + self.selectedRange.length;
    NSRange currParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(endLoc, 0)];
    
    NSRange  nextParaRange = NSMakeRange(NSNotFound, NSNotFound);
    if (currParaRange.location+currParaRange.length+1 < self.text.length) {
        nextParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(currParaRange.location+currParaRange.length+1,0)];
    }
    
    if (!isAllLineStyled && nextParaRange.location != NSNotFound && currParaRange.location != nextParaRange.location ) {
        NSMutableParagraphStyle *paraStyle = [[self dictionaryAtIndex:nextParaRange.location] objectForKey:NSParagraphStyleAttributeName];
        [self listingNextParastyle:paraStyle forRange:nextParaRange];
    }
    else if(isAllLineStyled && nextParaRange.location != NSNotFound && currParaRange.location != nextParaRange.location)
    {
        NSDictionary *nextParaDict = [self dictionaryAtIndex:nextParaRange.location];
        NSString *ListingStyle = [nextParaDict objectForKey:listingStyleString];
        NSMutableParagraphStyle *paraStyle = [nextParaDict objectForKey:NSParagraphStyleAttributeName];
        if (paraStyle && !ListingStyle) {
            [self removeAttributeForRange:nextParaRange forKey:NSParagraphStyleAttributeName];
        }
    }
    self.selectedRange = NSMakeRange(prevSelectedLoc, 0);
//    [self.textViewCustomDelegate saveInDraft];
 [_richTextDelegate handlePlaceHolder];
    
}

- (void)richTextEditorToolbarDidSelectNumberPoint
{
    
    NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:self.selectedRange];
    
    BOOL isAllLineStyled=[self isAllLinesStyled:rangeOfParagraphsInSelectedText withStyle:numberListKeyValue forKey:listingStyleString];
    
    [self applyNumberStyleToSelectedRangeForNewLine:NO];
    
    NSInteger endLoc = self.selectedRange.location + self.selectedRange.length;
    NSRange currParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(endLoc, 0)];
    NSRange  nextParaRange = NSMakeRange(NSNotFound, NSNotFound);
    
    if (currParaRange.location+currParaRange.length+1 < self.text.length) {
        nextParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(currParaRange.location+currParaRange.length+1,0)];
    }
    
    if (!isAllLineStyled && nextParaRange.location != NSNotFound && currParaRange.location != nextParaRange.location ) {
        
        NSMutableParagraphStyle *paraStyle = [[self dictionaryAtIndex:nextParaRange.location] objectForKey:NSParagraphStyleAttributeName];
        [self listingNextParastyle:paraStyle forRange:nextParaRange];
    }
    else if(isAllLineStyled && nextParaRange.location != NSNotFound && currParaRange.location != nextParaRange.location)
    {
        NSDictionary *nextParaDict = [self dictionaryAtIndex:nextParaRange.location];
        NSString *ListingStyle = [nextParaDict objectForKey:listingStyleString];
        NSMutableParagraphStyle *paraStyle = [nextParaDict objectForKey:NSParagraphStyleAttributeName];
        if (paraStyle && !ListingStyle) {
            [self removeAttributeForRange:nextParaRange forKey:NSParagraphStyleAttributeName];
        }
    }
    self.selectedRange = NSMakeRange(endLoc, 0);
   [_richTextDelegate handlePlaceHolder];
//    [self.textViewCustomDelegate saveInDraft];
    
}

-(void)richTextEditorToolbarDidSelectLink:(NSString *)linkString
{
    /*
    NSString *prevLink = [self previousLink];
    if (self.selectedRange.length > 0) {
        [self.textViewCustomDelegate getLinkInputWithEditOptionWithPrevLink:prevLink];
    }
    else
    {
        if (prevLink) {
            self.selectedRange = [self.attributedText getAttributeRangeAtIndex:self.selectedRange.location andAttribute:NSLinkAttributeName];
            [self.textViewCustomDelegate getLinkInputWithEditOptionWithPrevLink:prevLink];
        }
        else
        {
            [self.textViewCustomDelegate getLinkInputWithEditOptionWithPrevLink:nil];
        }
        
    } */
}

- (void)richTextEditorToolbarDidSelectblockQuotes
{
    /*
    NSRange quoteSelectedRange = self.selectedRange;
    [self applyQuoteStyleForRange:quoteSelectedRange];
    
    NSInteger endLoc = self.selectedRange.location + self.selectedRange.length;
    NSRange currParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(endLoc, 0)];
    NSRange  nextParaRange = NSMakeRange(NSNotFound, NSNotFound);
    
    if (currParaRange.location+currParaRange.length+1 < self.text.length) {
        nextParaRange = [self.attributedText firstParagraphRangeFromTextRange:NSMakeRange(currParaRange.location+currParaRange.length+1,0)];
    }
    
    if (nextParaRange.location != NSNotFound && currParaRange.location != nextParaRange.location ) {
        [self paragraphStyleForQuote:nextParaRange isNext:YES previousSelectedLOcation:nextParaRange.location];
    }
    
     [_richTextDelegate handlePlaceHolder];
    [self updateToolbarState];
    [self.textViewCustomDelegate saveInDraft];
    [self.textViewCustomDelegate setFrameForViews];
    */
}

- (void)richTextEditorToolbarDidSelectTextBackgroundColor // reviewed

{
    BOOL isAllSelected=[self isSelectedFullyColored:self.selectedRange];
    NSInteger location = self.selectedRange.location + self.selectedRange.length ;
    NSInteger selectedRangeLoc = self.selectedRange.location;
    BOOL istypingChange  = self.selectedRange.length == 0 ? true : false;
    if (!isAllSelected || istypingChange) {
        NSRange previousRange = self.selectedRange;
        [self removeAttributeForRange:previousRange forKey:NSStrikethroughStyleAttributeName];
        [self removeAttributeForRange:previousRange  forKey:NSUnderlineStyleAttributeName];
        self.selectedRange = previousRange;
        [self applyFontAttributesToSelectedRangeWithBoldTrait:[NSNumber numberWithBool:0] italicTrait:[NSNumber numberWithBool:0] fontName:nil fontSize:nil];
        
        if (istypingChange &&  selectedRangeLoc - 1 >= 0) {
            
            NSInteger prevLoc = selectedRangeLoc - 1;
            NSString *prevChar =  [self.text substringWithRange:NSMakeRange(selectedRangeLoc - 1, 1)];
            
            if ([prevChar isEqualToString:@"\n"] && selectedRangeLoc-2 >= 0) {
                prevLoc = selectedRangeLoc - 2;
            }
            
            NSDictionary *bgColorDict = [self dictionaryAtIndex:prevLoc];
            
            UIColor *typingBgcolor = [self.typingAttributes objectForKey:NSBackgroundColorAttributeName];
            UIColor *bgColor = [bgColorDict objectForKey:NSBackgroundColorAttributeName];
            
            if (bgColor || typingBgcolor) { // change
                if (self.selectedRange.location > 0) {
                    NSDictionary *prevDict = [self dictionaryAtIndex:self.selectedRange.location - 1];
                    [self setTypingAttributes:prevDict];
                }
                [self removeAttributeToTypingAttributeForKey:NSBackgroundColorAttributeName];
            }
            else
            {
                UIColor *color = UIColorFromRGB(0xFFF8A6);
                [self removeAttributeToTypingAttributeForKey:NSUnderlineStyleAttributeName];
                [self removeAttributeToTypingAttributeForKey:NSStrikethroughStyleAttributeName];
                [self applyAttributeToTypingAttribute:color forKey:NSBackgroundColorAttributeName];
            }
        }
        else if (istypingChange && selectedRangeLoc == 0)
        {
            UIColor *typingBgColor = [self.typingAttributes objectForKey:NSBackgroundColorAttributeName];
            if (typingBgColor) {
                [self removeAttributeToTypingAttributeForKey:NSBackgroundColorAttributeName];
            }
            else
            {
                UIColor *color = UIColorFromRGB(0xFFF8A6);
                [self applyAttributeToTypingAttribute:color forKey:NSBackgroundColorAttributeName];
            }
        }
        else
        {
            [self applyStyleForSelectedRange:NSBackgroundColorAttributeName];
        }
        
    }
    else
    {
        [self applyStyleForSelectedRange:NSBackgroundColorAttributeName];
    }
    self.selectedRange = NSMakeRange(location, 0);
    
    [self updateToolbarState];
//    [self.textViewCustomDelegate saveInDraft];
    
}

-(void)richTextEditorToolbarDidSelectPhoto //reviewed
{
    //    [self.textViewCustomDelegate tappedPhotosBtn];
}

-(void)richTextEditorToolbarDidSelectEmbededImage //reviewed
{
    //    [self.textViewCustomDelegate tappedEmbededImageBtn];
}

-(void)richTextEditorToolbarDidSelectAtMention
{
//    [self applyMentioning];
}

-(void)richTextEditorToolbarDidSelectTrendingTag
{
//    [self applyTrendingTag];
}

#pragma mark - text style handling  Methods

-(void)applyStyleForSelectedRange:(NSString *)style // reviewed
{
    [self applyStyle:style inRange:self.selectedRange];
}

-(void)applyStyle:(NSString*)style inRange:(NSRange)range  // reviewed
{
    NSArray *newRangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:self.selectedRange];
    
    for (int i=0 ; i<newRangeOfParagraphsInSelectedText.count ; i++)
    {
        NSValue *value = [newRangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
        NSString *listingStyle = [dictionary objectForKey:listingStyleString];
        NSRange changeRange = paragraphRange ;
        if (listingStyle) {
            
            if (i==0 && i==[newRangeOfParagraphsInSelectedText count]-1) {
                
                if (range.location <= paragraphRange.location+styleWt  ) {
                    NSInteger padd= (paragraphRange.location + styleWt) - range.location;
                    changeRange = NSMakeRange(paragraphRange.location + styleWt, range.length-padd);
                }
                else
                {
                    changeRange = range;
                }
            }
            else if (i==0) {
                if (range.location <= paragraphRange.location+styleWt  ) {
                    
                    changeRange = NSMakeRange(paragraphRange.location + styleWt, paragraphRange.length - styleWt);
                }
                else
                {
                    NSUInteger len = paragraphRange.location + paragraphRange.length - range.location;
                    changeRange = NSMakeRange(range.location, len);
                }
            }
            else  if (i==[newRangeOfParagraphsInSelectedText count]-1)
            {
                NSInteger loc = range.location + range.length;
                NSInteger len = loc - paragraphRange.location;
                changeRange = NSMakeRange(paragraphRange.location + styleWt, len - styleWt);
            }
            else
            {
                changeRange = NSMakeRange(paragraphRange.location + styleWt, paragraphRange.length - styleWt);
            }
        }
        
        else
        {
            if (i == 0 && i==[newRangeOfParagraphsInSelectedText count]-1) {
                changeRange = range;
            }
            else if (i == 0) {
                NSUInteger len = (paragraphRange.location + paragraphRange.length) - range.location;
                changeRange = NSMakeRange(range.location, len);
                
            }
            else if (i==[newRangeOfParagraphsInSelectedText count]-1)
            {
                NSInteger loc = range.location + range.length;
                NSInteger len = loc - paragraphRange.location;
                changeRange = NSMakeRange(paragraphRange.location ,len);
            }
        }
        
        NSDictionary *dict = [self dictionaryAtIndex:changeRange.location ];
        UIFont *font = [dict objectForKey:NSFontAttributeName];
        if([style isEqualToString:NSUnderlineStyleAttributeName] || [style isEqualToString:NSStrikethroughStyleAttributeName])
        {
            NSNumber *existingUnderlineStyle = [dict objectForKey:style];
            if (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone)
                existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
            else
                existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleNone];
            
            [self applyAttributes:existingUnderlineStyle forKey:style atRange:changeRange];
        }
        if ([style isEqualToString:@"Bold"]) {
            [self applyFontAttributesWithBoldTrait:[NSNumber numberWithBool:![font isBold]] italicTrait:nil fontName:nil fontSize:nil toTextAtRange:changeRange];
        }
        if ([style isEqualToString:@"Italic"]) {
            [self applyFontAttributesWithBoldTrait:nil italicTrait:[NSNumber numberWithBool:![font isItalic]] fontName:nil fontSize:nil toTextAtRange:changeRange];
        }
        if ([style isEqualToString:NSBackgroundColorAttributeName]) {
            
            BOOL isAllSelected=[self isSelectedFullyColored:changeRange];
            
            if (isAllSelected) {
                [self removeAttributeForRange:changeRange forKey:NSBackgroundColorAttributeName];
            }
            else
            {
                UIColor *color = UIColorFromRGB(0xFFF8A6);
                [self applyAttributes:color forKey:style atRange:changeRange];
            }
        }
        
    }
}

- (void)updateToolbarState
{
    // If no text exists or typing attributes is in progress update toolbar using typing attributes instead of selected text
    if (self.typingAttributesInProgress || ![self hasText])
    {
        NSMutableDictionary * tyingAttrib = [self.typingAttributes mutableCopy];
        [self getCurrentParaAttrib:tyingAttrib];
        [self.toolBar updateStateWithAttributes:tyingAttrib isTypingAttribute:YES];
    }
    else
    {
        int location = [self offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];
        
        if (location == self.text.length)
            location --;
        
        [self.toolBar updateStateWithAttributes:[self getAttribute] isTypingAttribute:NO];
    }
    
    [self scrollRangeToVisible:self.selectedRange];
}

- (void)applyAttributeToTypingAttribute:(id)attribute forKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [self.typingAttributes mutableCopy];
    [dictionary setObject:attribute forKey:key];
    [self setTypingAttributes:dictionary];
}


- (void)applyFontAttributesToSelectedRangeWithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize
{
    [self applyFontAttributesWithBoldTrait:isBold italicTrait:isItalic fontName:fontName fontSize:fontSize toTextAtRange:self.selectedRange];
}

- (void)applyFontAttributesWithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize toTextAtRange:(NSRange)range
{
    // If any text selected apply attributes to text
    if (range.length > 0)
    {
        NSMutableAttributedString *attributedString = self.textStorage;
        
        [attributedString beginEditing];
        [attributedString enumerateAttributesInRange:range
                                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                          usingBlock:^(NSDictionary *dictionary, NSRange range, BOOL *stop){
                                              
                                              UIFont *newFont = [self fontwithBoldTrait:isBold
                                                                            italicTrait:isItalic
                                                                               fontName:fontName
                                                                               fontSize:fontSize
                                                                         fromDictionary:dictionary];
                                              
                                              if (newFont)
                                                  [attributedString addAttributes:[NSDictionary dictionaryWithObject:newFont forKey:NSFontAttributeName] range:range];
                                          }];
        [attributedString endEditing];
        
        [self setSelectedRange:range];
    }
    // If no text is selected apply attributes to typingAttribute
    else
    {
        self.typingAttributesInProgress = YES;
        
        UIFont *newFont = [self fontwithBoldTrait:isBold
                                      italicTrait:isItalic
                                         fontName:fontName
                                         fontSize:fontSize
                                   fromDictionary:self.typingAttributes];
        if (newFont)
            [self applyAttributeToTypingAttribute:newFont forKey:NSFontAttributeName];
    }
    
    [self updateToolbarState];
}

- (UIFont *)fontwithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize fromDictionary:(NSDictionary *)dictionary
{
    UIFont *newFont = nil;
    UIFont *font = [dictionary objectForKey:NSFontAttributeName];
    BOOL newBold = (isBold) ? isBold.intValue : [font isBold];
    BOOL newItalic = (isItalic) ? isItalic.intValue : [font isItalic];
    CGFloat newFontSize = (fontSize) ? fontSize.floatValue : font.pointSize;
    
    if (fontName)
    {
        newFont = [UIFont fontWithName:fontName size:newFontSize boldTrait:newBold italicTrait:newItalic];
    }
    else
    {
        newFont = [font fontWithBoldTrait:newBold italicTrait:newItalic andSize:newFontSize];
    }
    
    return newFont;
}

- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range
{
    [self applyAttributes:attribute forKey:key atRange:range andCursorRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range andCursorRange:(NSRange) cursorRange
{
    // If any text selected apply attributes to text
    if (range.length > 0)
    {
        NSMutableAttributedString *attributedString = self.textStorage;
        
        // Workaround for when there is only one paragraph,
        // sometimes the attributedString is actually longer by one then the displayed text,
        // and this results in not being able to set to lef align anymore.
        if (range.length == attributedString.length-1 && range.length == self.text.length)
            ++range.length;
        [attributedString beginEditing];
        [attributedString addAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] range:range];
        [attributedString endEditing];
        //    [self setAttributedText:attributedString];
        
        if (cursorRange.location != NSNotFound) {
            [self setSelectedRange:NSMakeRange(cursorRange.location,0)];
        }
        //        else
        //        {
        //            [self setSelectedRange:NSMakeRange(range.location + range.length,0)];
        //        }
        
    }
    // If no text is selected apply attributes to typingAttribute
    else
    {
        self.typingAttributesInProgress = YES;
        [self applyAttributeToTypingAttribute:attribute forKey:key];
    }
    
    [self updateToolbarState];
}

- (void)applyAttrubutesToSelectedRange:(id)attribute forKey:(NSString *)key
{
    [self applyAttributes:attribute forKey:key atRange:self.selectedRange];
}


#pragma mark - Get attributes  Methods
-(void)getCurrentParaAttrib:(NSMutableDictionary *)attributeDict
{
    NSRange currParaRange = [self.attributedText firstParagraphRangeFromTextRange:self.selectedRange];
    NSDictionary * currParaDict = [self dictionaryAtIndex:currParaRange.location];
    NSString *currListString = [currParaDict objectForKey:listingStyleString];
   
    if (!currListString && [self isContainStyle:listingStyleString]) {
        currListString = [self listingStyleInSelectedRange];
    }
    
    if ([currListString isEqualToString:numberListKeyValue]) {
        [attributeDict setObject:numberListKeyValue forKey:listingStyleString];
    }
    else if ([currListString isEqualToString:bulletListkeyValue])
    {
        [attributeDict setObject:bulletListkeyValue forKey:listingStyleString];
    }
 
}

- (NSDictionary *)dictionaryAtIndex:(NSInteger)index
{
    // If index at end of string, get attributes starting from previous character
    if (index == self.attributedText.string.length && [self hasText])
        --index;
    
    // If no text exists get font from typing attributes
    return  ([self hasText])
    ? [self.attributedText attributesAtIndex:index effectiveRange:nil]
    : self.typingAttributes;
}


-(NSDictionary *)getAttribute // reviewed
{
    NSMutableDictionary *attributeDict = [[NSMutableDictionary alloc]init];
    
    NSInteger location = 0;
    if (self.selectedRange.location !=0) {
        location =self.selectedRange.location-1;
    }
    NSDictionary *prevDictionary = [self dictionaryAtIndex:location];
    NSDictionary *currDictionary = [self dictionaryAtIndex:self.selectedRange.location];
    
    NSString *bgColorStyle = [prevDictionary objectForKey:NSBackgroundColorAttributeName];
    NSString *CurrBgColorStyle = [currDictionary objectForKey:NSBackgroundColorAttributeName];
    
    if (bgColorStyle  || CurrBgColorStyle ) {
        [attributeDict setObject:@"true" forKey:NSBackgroundColorAttributeName];
    }
    UIFont *previFont = [prevDictionary objectForKey:NSFontAttributeName];
    UIFont *currFont = [currDictionary objectForKey:NSFontAttributeName];
    if ([previFont isBold] || [currFont isBold]) {
        [attributeDict setObject:@"true" forKey:@"bold"];
    }
    if ([previFont isItalic] || [currFont isItalic]) {
        [attributeDict setObject:@"true" forKey:@"italic"];
    }
    
    NSNumber *prevStrikethrough = [prevDictionary objectForKey:NSStrikethroughStyleAttributeName];
    NSNumber *existingStrikethrough = [currDictionary objectForKey:NSStrikethroughStyleAttributeName];
    if ((prevStrikethrough && prevStrikethrough.intValue != 0) || (existingStrikethrough &&existingStrikethrough.intValue != 0)) {
        [attributeDict setObject:[NSNumber numberWithInt:1] forKey:NSStrikethroughStyleAttributeName];
    }
    
    [self getCurrentParaAttrib:attributeDict];
    NSNumber *prevUnderlineStyle = [prevDictionary objectForKey:NSUnderlineStyleAttributeName];
    NSNumber *existingUnderlineStyle = [currDictionary objectForKey:NSUnderlineStyleAttributeName];
    if ((prevUnderlineStyle && prevUnderlineStyle.intValue != 0) || (existingUnderlineStyle && existingUnderlineStyle.intValue != 0)) {
        [attributeDict setObject:[NSNumber numberWithInt:1] forKey:NSUnderlineStyleAttributeName];
    }
    
    if ([currDictionary objectForKey:NSLinkAttributeName] && [currDictionary objectForKey:NSLinkAttributeName]) {
        [attributeDict setObject:[currDictionary objectForKey:NSLinkAttributeName] forKey:NSLinkAttributeName];
    }
    
    return attributeDict;
}

#pragma mark - Validate attributes  Methods

-(BOOL)isSelectedFullyColored:(NSRange )rangeOfText
{
    int count=0;
    for (int i=0 ; i<rangeOfText.length ; i++)
    {
        NSDictionary *dictionary = [self dictionaryAtIndex:rangeOfText.location+i];
        NSString *listStyle=[dictionary objectForKey:NSBackgroundColorAttributeName];
        if (listStyle) {
            count++;
        }
    }
    return count == rangeOfText.length ? true:false;
}

-(NSString *)listingStyleInSelectedRange // check all paragraph in the selected range for minumum
{
    NSArray *newRangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRangeForQuote:self.selectedRange];
    for (int i=0 ; i<newRangeOfParagraphsInSelectedText.count ; i++)
    {
        NSValue *value = [newRangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        NSDictionary *currDict = [self dictionaryAtIndex:paragraphRange.location];
        NSString * currListing = [currDict objectForKey:listingStyleString];
        if (currListing) {
            return  currListing;
        }
    }
    return nil;
}

-(BOOL)isContainStyle:(NSString*)style
{
    NSArray *newRangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRangeForQuote:self.selectedRange];
    for (int i=0 ; i<newRangeOfParagraphsInSelectedText.count ; i++) //adding paragraph style
    {
        NSValue *value = [newRangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        NSDictionary *currDict = [self dictionaryAtIndex:paragraphRange.location];
        if ([currDict objectForKey:style]) {
            return true;
        }
    }
    return false;
}

-(BOOL)isAllLinesStyled:(NSArray *)selectedParagraph withStyle:(NSString *)style forKey:(NSString *)key  // reviewed
{
    int count=0;
    for (int i=0 ; i<selectedParagraph.count ; i++)
    {
        NSValue *value = [selectedParagraph objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
        NSString *listStyle=[dictionary objectForKey:key];
        
        if ([key isEqualToString:listingStyleString]) {
            if ([listStyle isEqualToString:style]) {
                count++;
            }
        }
}
    return count==selectedParagraph.count && selectedParagraph.count !=0 ?true:false;
}

#pragma mark - Remove attributes  Methods

- (void)removeAttributeForRange:(NSRange)range forKey:(NSString *)key
{
    NSMutableAttributedString *attrbStr = self.textStorage;
    [attrbStr beginEditing];
    [attrbStr removeAttribute:key range:range];
    [attrbStr endEditing];
}

- (void)removeAttributeToTypingAttributeForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [self.typingAttributes mutableCopy];
    [dictionary removeObjectForKey:key];
    [self setTypingAttributes:dictionary];
}

#pragma mark - Apply  Number Listing attributes  Methods

-(void)applyAttribute:(NSString *)attribute
{
    if ((self.selectedRange.location-1 > 0) && (self.selectedRange.location  <= [self.attributedText length])) {
        NSDictionary *newDict = [self dictionaryAtIndex:self.selectedRange.location-1];
        
        NSDictionary *anotherDict = nil;
        NSInteger selLoc = self.selectedRange.location;
        if ((selLoc+1  <= [self.attributedText length])) {
            anotherDict=[self dictionaryAtIndex:selLoc+1];
        }
        
        NSURL * prevLocationLink = [newDict objectForKey:attribute];
        NSURL *nextLocationLink = [anotherDict objectForKey:attribute];
        if (prevLocationLink && !nextLocationLink)
        {
            [self removeAttributeForRange:NSMakeRange(prevRange.location,self.selectedRange.location - prevRange.location) forKey:attribute];
        }
    }
}


-(void)applyNumberStyleToSelectedRangeForNewLine:(BOOL)isNewLine
{
    [self applyNumberListInRange:self.selectedRange isInsert:isNewLine];
    [self updateToolbarState];
}

-(void)applyNumberListInRange:(NSRange)range isInsert:(BOOL)isNewLine // reviewed
{
    NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:range];
    NSRange pevSelRange=self.selectedRange;
    
    NSInteger preAddedNumber = 0;
    NSInteger changeLen = 0;
    BOOL isAllLineStyled=[self isAllLinesStyled:rangeOfParagraphsInSelectedText withStyle:numberListKeyValue forKey:listingStyleString];
    for (int i=0 ; i<rangeOfParagraphsInSelectedText.count ; i++)
    {
        NSInteger number=i;
        NSString *styleNumber;
        
        NSValue *value = [rangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        
        NSInteger loc=paragraphRange.location + changeLen;
        if (loc-1 >= 0) {
            NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:NSMakeRange((paragraphRange.location+changeLen)-1,1)];
            NSValue *value = [rangeOfParagraphsInSelectedText objectAtIndex:0];
            NSRange prevParagraphRange = [value rangeValue];
            number=[self getParagrapNumberInRange:prevParagraphRange];
        }
        
        styleNumber = [self getStyleNumberForNumber:number+1];
        preAddedNumber = number;
        
        if (!isNewLine)  // numberList for selected range
        {
            NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location+changeLen];
            NSString *listStyle=[dictionary objectForKey:listingStyleString];
            NSMutableAttributedString *attrbStr=self.textStorage;
            [attrbStr beginEditing];
            int locationChangelength=0;
            NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
            NSRange modifiedRange;
            
            if (!paragraphStyle)
                paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.firstLineHeadIndent = 5;
            
            if ([listStyle isEqualToString:numberListKeyValue]) {
                NSInteger startLocation = paragraphRange.location + changeLen;
                NSInteger endLocation = startLocation + styleWt;
                
                if (!isAllLineStyled) {
                    if (startLocation >= 0 && endLocation <= attrbStr.length) {
                        [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location+changeLen,styleWt) withString:styleNumber];
                    }
                    [attrbStr endEditing];
                    self.selectedRange=NSMakeRange(paragraphRange.location+paragraphRange.length,0);
                    continue;
                }
                [attrbStr removeAttribute:listingStyleString range:NSMakeRange(paragraphRange.location+changeLen,paragraphRange.length)];
                
                if (startLocation >= 0 && endLocation <= attrbStr.length) {
                    [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location+changeLen,styleWt) withString:@""];
                    changeLen -=styleWt;
                }
                
                [attrbStr endEditing];
                [self changeCurrentListingParaStyle:NSMakeRange(paragraphRange.location+changeLen+paragraphRange.length,0)];
                self.selectedRange=NSMakeRange(paragraphRange.location+changeLen+paragraphRange.length,0);
                preAddedNumber = 0;
                NSInteger  loc = self.selectedRange.location;
                [self changeBlowParaNumber:preAddedNumber];
                self.selectedRange = NSMakeRange(loc, 0);
                continue;
            }
            else if ([listStyle isEqualToString:bulletListkeyValue])
            {
                NSMutableAttributedString *numberStr=[[NSMutableAttributedString alloc]initWithString:styleNumber attributes:[NSDictionary dictionaryWithObjectsAndKeys:normalFont,NSFontAttributeName, nil]];
                
                NSInteger startLocation = paragraphRange.location + changeLen;
                NSInteger endLocation = startLocation + styleWt;
                
                if (startLocation >=0 && endLocation <= attrbStr.length) {
                    [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location+changeLen,styleWt) withAttributedString:numberStr];
                    
                    [attrbStr addAttribute:NSBaselineOffsetAttributeName
                                     value:[NSNumber numberWithFloat:0]
                                     range:NSMakeRange(paragraphRange.location+changeLen, styleWt-1)];
                }
                modifiedRange=paragraphRange;
            }
            else
            {
                NSMutableDictionary *mutableDict =[[NSMutableDictionary alloc]init];
                [mutableDict setObject:normalFont forKey:NSFontAttributeName];
                
                NSMutableAttributedString *numberStr=[[NSMutableAttributedString alloc]initWithString:styleNumber attributes:mutableDict];
                
                NSInteger startLocation;
                if ([attrbStr length]) {
                    startLocation = paragraphRange.location+changeLen;
                    [attrbStr insertAttributedString:numberStr atIndex:paragraphRange.location+changeLen];
                }
                else
                {
                    startLocation = 0;
                    [attrbStr appendAttributedString:numberStr];
                }
                
                modifiedRange=NSMakeRange(startLocation, paragraphRange.length+styleWt);
                locationChangelength=(number+1)*styleWt;
                changeLen +=numberStr.length;
            }
            [attrbStr endEditing];
            [self listingParagraphStyle:paragraphStyle forRange:modifiedRange];
            [self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:modifiedRange];
            [self applyAttributes:numberListKeyValue forKey:listingStyleString atRange:modifiedRange];
            
            self.selectedRange=NSMakeRange(paragraphRange.location+locationChangelength+paragraphRange.length,0);
        }
        else // numberList for new Line
        {
            if (i==0) {
                NSMutableAttributedString *attrbStr= self.textStorage;
                [attrbStr beginEditing];
                
                if (range.location >0) // removing for double tab in unordered list (escaping form unorderlist)
                {
                    NSRange prevParagraphRange = [self.attributedText
                                                  firstParagraphRangeFromTextRange:NSMakeRange(range.location-1, 1)];
                    NSString *newText=[[self.attributedText attributedSubstringFromRange:prevParagraphRange] string];
                    
                    if ([self isEmptyLineInText:newText isNumberList:YES]) {  //Empty previous line
                        
                        NSRange fullCurrParaRange = [self.attributedText
                                                     firstParagraphRangeFromTextRange:prevParagraphRange withNewline:YES];
                        
                        [attrbStr removeAttribute:listingStyleString range:fullCurrParaRange];
                        [attrbStr replaceCharactersInRange:fullCurrParaRange withString:@""];
                        [attrbStr endEditing];
                        NSInteger length=self.attributedText.length - prevParagraphRange.location;
                        if (length-2>0) {
                            [self changeNumberOfParagraph:NSMakeRange(prevParagraphRange.location+2, length-2) withIsInc:YES previousNumber:0];
                        }
                        
                        self.selectedRange=NSMakeRange(prevParagraphRange.location, 0);
                        return;
                    }
                }
                
                NSRange paragraphStyleRange;
                NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
                
                NSMutableDictionary *mutableDict =[[NSMutableDictionary alloc]init];
                [mutableDict setObject:normalFont forKey:NSFontAttributeName];
                
                NSMutableAttributedString *numberStr=[[NSMutableAttributedString alloc]initWithString:styleNumber attributes:mutableDict];
                [numberStr beginEditing];
                [numberStr addAttribute:listingStyleString value:numberListKeyValue range:NSMakeRange(0, numberStr.length)];
                [numberStr endEditing];
                if (paragraphRange.location < attrbStr.length) {
                    [attrbStr insertAttributedString:numberStr atIndex:paragraphRange.location];
                }
                else
                {
                    [attrbStr appendAttributedString:numberStr];
                }
                
                paragraphStyleRange=NSMakeRange(paragraphRange.location,  paragraphRange.length+styleNumber.length);
                [attrbStr endEditing];
                
                NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
                if (!paragraphStyle)
                    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.firstLineHeadIndent = 5;
                
                [self listingParagraphStyle:paragraphStyle forRange:paragraphStyleRange];
                [self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphStyleRange];
                [self applyAttributes:numberListKeyValue forKey:listingStyleString atRange:paragraphStyleRange];
                
                self.selectedRange=NSMakeRange(pevSelRange.location + styleWt, 0);
                NSInteger loc = self.selectedRange.location;
                [self changeBlowParaNumber:number+1];
                self.selectedRange = NSMakeRange(loc, 0);
                return;
            }
        }
        
    }
    self.selectedRange=NSMakeRange(range.location+range.length+changeLen, 0);
    NSInteger loc =  self.selectedRange.location;
    NSRange currentParaRange = [self.attributedText firstParagraphRangeFromTextRange:self.selectedRange];
    NSUInteger number = [self getParagrapNumberInRange:currentParaRange];
    [self changeBlowParaNumber:number];
    self.selectedRange = NSMakeRange(loc, 0);
}

-(void)changeBlowParaNumber:(NSInteger )number
{
    NSRange currentPara = [self.attributedText firstParagraphRangeFromTextRange:self.selectedRange];
    NSUInteger endLoc = currentPara.location + currentPara.length;
    NSInteger start=endLoc + 1;
    
    if (start  < self.attributedText.length) {
        NSInteger length=(self.attributedText.length) - start;
        [self changeNumberOfParagraph:NSMakeRange(start, length) withIsInc:YES previousNumber:number];
    }
}


-(NSString *)getStyleNumberForNumber:(NSInteger)number // reviewed
{
    NSString *styleNumber ;
    if (number < 10) {
        styleNumber=[NSString stringWithFormat:@" %ld. ",(long)number];
    }
    else
        styleNumber=[NSString stringWithFormat:@"%ld. ",(long)number];
    
    return styleNumber;
}

-(void)changeListingStyleOfBelowParagraph //reviewd
{
    NSInteger len=self.attributedText.length-self.selectedRange.location;
    NSArray *newRangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:NSMakeRange(self.selectedRange.location,len)];
    if (newRangeOfParagraphsInSelectedText.count >1) {
        
        NSValue *currentValue = [newRangeOfParagraphsInSelectedText objectAtIndex:0];
        NSRange currentParagraphRange = [currentValue rangeValue];
        
        NSDictionary *currentDictionary = [self dictionaryAtIndex:currentParagraphRange.location];
        NSString *currentValueListStyle=[currentDictionary objectForKey:listingStyleString];
        
        NSValue *nextValue = [newRangeOfParagraphsInSelectedText objectAtIndex:1];
        NSRange nextParagraphRange = [nextValue rangeValue];
        
        NSDictionary *nextDictionary = [self dictionaryAtIndex:nextParagraphRange.location];
        NSString *nextValueListStyle=[nextDictionary objectForKey:listingStyleString];
        
        if (![currentValueListStyle isEqualToString:numberListKeyValue] && [nextValueListStyle isEqualToString:numberListKeyValue]) {
            NSInteger currentLength=self.attributedText.length - nextParagraphRange.location;
            [self changeNumberOfParagraph:NSMakeRange(nextParagraphRange.location, currentLength) withIsInc:YES previousNumber:0];
        }
        else if ([currentValueListStyle isEqualToString:numberListKeyValue] && [nextValueListStyle isEqualToString:numberListKeyValue])
        {
            NSInteger currentNumber = [self getParagrapNumberInRange:currentParagraphRange];
            NSInteger currentLength=self.attributedText.length - nextParagraphRange.location;
            [self changeNumberOfParagraph:NSMakeRange(nextParagraphRange.location, currentLength) withIsInc:YES previousNumber:currentNumber];
        }
    }
}

-(NSInteger)getParagrapNumberInRange:(NSRange)prevParagraphRange //reviewed
{
    NSString *newText=[[self.attributedText attributedSubstringFromRange:prevParagraphRange] string];
    if (newText)
    {
        return  [self getNumberFromString:newText];
    }
    return 0;
}

-(NSInteger)getNumberFromString:(NSString*)string //reviewed
{
    if (string) {
        NSString *  separatorStr=@".";
        NSArray *content=[string componentsSeparatedByString:separatorStr];
        NSMutableCharacterSet *carSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789. "];
        BOOL isNumber = [[[content objectAtIndex:0] stringByTrimmingCharactersInSet:carSet] isEqualToString:@""];
        if (isNumber) {
            return [[content objectAtIndex:0] integerValue];
        }
        else
        {
            return 0;
        }
    }
    return 0;
}

-(BOOL)isContainNumber:(NSString*)string
{
    NSString *  separatorStr=@".";
    NSArray *content=[string componentsSeparatedByString:separatorStr];
    NSMutableCharacterSet *carSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789. "];
    BOOL isNumber = [[[content objectAtIndex:0] stringByTrimmingCharactersInSet:carSet] isEqualToString:@""];
    return isNumber;
}

-(void)changeNumberOfParagraph:(NSRange )changeInRange withIsInc:(BOOL)isIncrement previousNumber:(NSInteger)prevNumber //reviewed
{
    if (![self hasText])
        return;
    
    NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:changeInRange];
    NSRange previousParaRange = self.selectedRange;
    for (int i=0 ; i<rangeOfParagraphsInSelectedText.count ; i++)
    {
        NSValue *value = [rangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        
        NSMutableAttributedString *attrbStr = self.textStorage;
        [attrbStr beginEditing];
        NSMutableDictionary *dictionary = [[self dictionaryAtIndex:paragraphRange.location] mutableCopy];
        NSString *listStyle=[dictionary objectForKey:listingStyleString];
        if ([listStyle isEqualToString:numberListKeyValue]) {
            
            NSString *numberStr = nil;
            numberStr =[self getStyleNumberForNumber:prevNumber+i+1];
            if (!numberStr) {
                numberStr = @"";
            }
            
            [dictionary setObject:normalFont forKey:NSFontAttributeName];
            NSMutableAttributedString *styleNumberStr=[[NSMutableAttributedString alloc]initWithString:numberStr attributes:dictionary];
            
            [styleNumberStr addAttribute:listingStyleString value:numberListKeyValue range:NSMakeRange(0, styleNumberStr.length)];
            
            if (paragraphRange.length >0) {
                [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location, styleWt) withAttributedString:styleNumberStr];
            }
            NSMutableParagraphStyle *paraStyle = [[self dictionaryAtIndex:paragraphRange.location] objectForKey:NSParagraphStyleAttributeName];
            if (!paraStyle) {
                paraStyle = [[NSMutableParagraphStyle alloc]init];
                paraStyle.firstLineHeadIndent = 5;
            }
            [self listingParagraphStyle:paraStyle forRange:paragraphRange];
            [attrbStr endEditing];
        }
        else
        {
            [attrbStr endEditing];
            self.selectedRange=NSMakeRange(previousParaRange.location + styleWt, 0);
            return;
        }
        if (i==0) {
            previousParaRange = paragraphRange;
        }
    }
    self.selectedRange=NSMakeRange(changeInRange.location, 0);
}

-(BOOL)isEmptyLineInText:(NSString*)lineText isNumberList:(BOOL)isOrderedList //reviewed
{
    BOOL isNumber=true;
    
    NSMutableString * text = [lineText mutableCopy];
    lineText = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if (isOrderedList && lineText)
    {
        NSString*   separatorStr=@".";
        NSArray *content=[lineText componentsSeparatedByString:separatorStr];
        NSMutableCharacterSet *carSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789."];
        NSString *trimmedText=[[content objectAtIndex:0] stringByTrimmingCharactersInSet:carSet];
        isNumber = [trimmedText isEqualToString:@" "] || [trimmedText isEqualToString:@""];
        if (isNumber && [content count]==2 && [[content objectAtIndex:1] isEqualToString:@" "]) {
            return YES;
        }
    }
    
    else if ([lineText isEqualToString:bulletStyleString.string])
    {
        return YES;
    }
    return false;
}


#pragma mark - Apply  Listing attributes common Methods

-(void)changeCurrentListingParaStyle:(NSRange)range
{
    NSRange currSelectedRange = range;
    NSRange currentPara = [self.attributedText firstParagraphRangeFromTextRange:range];
    NSRange prevPara =  [self.attributedText previousParagraphForRange:range];
    if (prevPara.location != NSNotFound) {
        NSDictionary  *prevDict = [self dictionaryAtIndex:prevPara.location];
        NSString *prevListingStr = [prevDict objectForKey:listingStyleString];
        if (!prevListingStr) {
            [self removeAttributeForRange:currentPara forKey:NSParagraphStyleAttributeName];
        }
    }
    self.selectedRange = currSelectedRange;
}

-(void)listingNextParastyle:(NSMutableParagraphStyle*)paraStyle forRange:(NSRange)nextParaRange
{
    if (!paraStyle) {
        paraStyle = [[NSMutableParagraphStyle alloc] init];
    }
    paraStyle.maximumLineHeight = 20.0;
    paraStyle.paragraphSpacingBefore = 12;
    paraStyle.lineSpacing = 0;
    
    [self applyAttributes:paraStyle forKey:NSParagraphStyleAttributeName atRange:nextParaRange];
}




#pragma mark - Apply   Bullet Listing attributes  Methods


// bullet listing begins

-(void)applybulletStyleToSelectedRangeForNewLine:(BOOL)isNewLine // completed
{
//    prevContentHt = self.contentSize.height;
    NSRange addBulletForRange;
    if (self.selectedRange.length == 0) {
        addBulletForRange = [self.attributedText firstParagraphRangeFromTextRange:self.selectedRange];
    }
    else
    {
        addBulletForRange = self.selectedRange;
    }
    [self applyBulletTextForRange:addBulletForRange isNewLine:isNewLine];
    NSInteger location = self.selectedRange.location;
    [self changeListingStyleOfBelowParagraph];
    self.selectedRange = NSMakeRange(location, 0);
    
    [self updateToolbarState];
}

-(void)applyBulletTextForRange:(NSRange) range isNewLine:(BOOL)isNewLine // completed
{
//    prevContentHt = self.contentSize.height;
    
    NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:range];
    
    BOOL isAllLineStyled=[self isAllLinesStyled:rangeOfParagraphsInSelectedText withStyle:bulletListkeyValue forKey:listingStyleString];
    int changeInIndex=0;
    
    for (int i=0 ; i<rangeOfParagraphsInSelectedText.count ; i++)
    {
        NSValue *value = [rangeOfParagraphsInSelectedText objectAtIndex:i];
        NSRange paragraphRange = [value rangeValue];
        
        NSRange paragraphStyleRange;
        NSMutableAttributedString *attrbStr=self.textStorage;
        [attrbStr beginEditing];
        NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location+changeInIndex];
        NSString *listStyle=[dictionary objectForKey:listingStyleString];
        
        NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
        
        if (!paragraphStyle)
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.headIndent = 0;
        paragraphStyle.firstLineHeadIndent = 0;
        
        int locationChangelength=0;
        if (!isNewLine && [listStyle isEqualToString:bulletListkeyValue]) { //removing Bullet
            if (!isAllLineStyled) {
                continue;
            }
            
            [attrbStr removeAttribute:listingStyleString range:NSMakeRange(paragraphRange.location+changeInIndex,paragraphRange.length)];
            
            NSInteger startLocation = paragraphRange.location + changeInIndex;
            NSInteger endLocation = startLocation + styleWt;
            paragraphStyleRange=NSMakeRange(paragraphRange.location + changeInIndex,  paragraphRange.length-styleWt);
            if (startLocation >= 0 && endLocation <= attrbStr.length) {
                [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location+changeInIndex,styleWt) withString:@""];
                locationChangelength =-(i+1)*styleWt;
                changeInIndex -=styleWt;
            }
            
            [attrbStr endEditing];
            [self changeCurrentListingParaStyle:NSMakeRange(paragraphRange.location+locationChangelength+paragraphRange.length,0)];
            self.selectedRange=NSMakeRange(paragraphRange.location+locationChangelength+paragraphRange.length,0);
            continue;
        }
        else if ([listStyle isEqualToString:numberListKeyValue]) // number to bullet change
        {
            NSInteger startLocation = paragraphRange.location + changeInIndex;
            NSInteger endLocation = startLocation + styleWt;
            
            if (startLocation >= 0 && endLocation <= attrbStr.length) {
                [attrbStr replaceCharactersInRange:NSMakeRange(paragraphRange.location+changeInIndex,styleWt) withAttributedString:bulletStyleString];
                
                paragraphStyleRange=NSMakeRange(paragraphRange.location+changeInIndex, paragraphRange.length);
                [attrbStr addAttribute:NSBaselineOffsetAttributeName
                                 value:[NSNumber numberWithFloat:3.5]  //adjust this number till text appears to be centered *bullet*
                                 range:NSMakeRange(paragraphStyleRange.location, styleWt-1)];
                [attrbStr addAttribute:NSFontAttributeName value:bulletFont range:NSMakeRange(paragraphStyleRange.location, styleWt-1)];
                [attrbStr endEditing];
                
                [self listingParagraphStyle:paragraphStyle forRange:paragraphStyleRange];
                [self applyAttributes:bulletListkeyValue forKey:listingStyleString atRange:paragraphStyleRange];
                
            }
            
        }
        else  //adding bullet
        {
            if (range.location  > 0) {
                NSRange prevParagraphRange = [self.attributedText
                                              firstParagraphRangeFromTextRange:NSMakeRange(range.location-1, 1)];
                
                NSString *str=[[self.attributedText attributedSubstringFromRange:prevParagraphRange] string];
                if ([self isEmptyLineInText:str isNumberList:NO]) {
                    
                    NSRange fullCurrParaRange = [self.attributedText firstParagraphRangeFromTextRange:prevParagraphRange withNewline:YES];
                    [attrbStr removeAttribute:listingStyleString range:fullCurrParaRange];
                    [attrbStr replaceCharactersInRange:fullCurrParaRange withString:@""];
                    [attrbStr endEditing];
                    self.selectedRange=NSMakeRange(prevParagraphRange.location, 0);
                    continue;
                    
                }
            }
            NSInteger startLocation;
            
            if (paragraphRange.location+changeInIndex < [attrbStr length]) {
                startLocation = paragraphRange.location+changeInIndex;
                NSDictionary *dotDict = [self dictionaryAtIndex:startLocation];
                NSString *bullotDot = [dotDict objectForKey:@"bulletDot"];
                if (![bullotDot isEqualToString:@"bulletDot"]) {
                    [attrbStr insertAttributedString:bulletStyleString atIndex:startLocation];
                    changeInIndex +=styleWt;
                    [attrbStr addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:3.5] range:NSMakeRange(startLocation, styleWt-1)];
                    [attrbStr addAttribute:listingStyleString value:bulletListkeyValue range:NSMakeRange(startLocation,  paragraphRange.length+styleWt)];
                }
            }
            else
            {
                startLocation = paragraphRange.location;
                [attrbStr appendAttributedString:bulletStyleString];
                changeInIndex +=styleWt;
                [attrbStr addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:3.5] range:NSMakeRange(startLocation, styleWt-1)];
                
                [attrbStr addAttribute:listingStyleString value:bulletListkeyValue range:NSMakeRange(startLocation,  paragraphRange.length+styleWt)];
            }
            
            
            paragraphStyleRange=NSMakeRange(startLocation,  paragraphRange.length+styleWt);
            locationChangelength=(i+1)*styleWt;
            
            NSRange bulletRange = NSMakeRange(startLocation, paragraphRange.length + styleWt);
            
            [attrbStr endEditing];
            [self listingParagraphStyle:paragraphStyle forRange:bulletRange];
        }
        self.selectedRange=NSMakeRange(paragraphRange.location+locationChangelength+paragraphRange.length,0);
    }
}

-(void)listingParagraphStyle:(NSMutableParagraphStyle *)paraStyle forRange:(NSRange)bulletRange // completed
{
    if (!paraStyle) {
        paraStyle = [[NSMutableParagraphStyle alloc] init];
    }
    
    CGFloat indent =[self widthofBulletStyle];
    paraStyle.headIndent =indent;
    paraStyle.maximumLineHeight = 20.0;
    paraStyle.lineSpacing = 0;
    paraStyle.paragraphSpacingBefore = 12;
    paraStyle.tailIndent = -indent;
    [self applyAttributes:paraStyle forKey:NSParagraphStyleAttributeName atRange:bulletRange];
}

-(CGFloat )widthofBulletStyle // reviewed
{
    CGRect textRect = [bulletStyleString.string boundingRectWithSize:self.bounds.size
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:bulletFont}
                                                             context:nil];
    return textRect.size.width;
}


@end
