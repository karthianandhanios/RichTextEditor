//
//  EditorViewController.m
//  RichTextEditor
//
//  Created by Karthi A on 14/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import "EditorViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define RICHTEXTEDITOR_TOOLBAR_HEIGHT 55
@interface EditorViewController ()

@end

@implementation EditorViewController
@synthesize richTextEditorTextView,placeHolderLabel;
- (void)viewDidLoad {
    [super viewDidLoad];
  
    [placeHolderLabel.superview bringSubviewToFront:placeHolderLabel];
    [self initialTextViewSetUp];
    [self textViewToolBarSetup];
   }

-(void)initialTextViewSetUp
{
    self.title = @"RichTextEditor";
    [richTextEditorTextView becomeFirstResponder];
//    richTextEditorTextView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
//    richTextEditorTextView.contentInset = UIEdgeInsetsMake(10,10, 0, 10);
    richTextEditorTextView.contentHt = self.view.bounds.size.height;
    richTextEditorTextView.richTextDelegate = self ;
    richTextEditorTextView.keyboardType=UIKeyboardTypeDefault;
    richTextEditorTextView.keyboardAppearance=UIKeyboardAppearanceLight;
    
    richTextEditorTextView.autocorrectionType=UITextAutocorrectionTypeYes;
    richTextEditorTextView.autocapitalizationType=UITextAutocapitalizationTypeSentences;
    richTextEditorTextView.font= [UIFont fontWithName:@"HelveticaNeue" size:16];
    
    richTextEditorTextView.layer.cornerRadius=0;
    richTextEditorTextView.backgroundColor=[UIColor whiteColor];
    richTextEditorTextView.layer.shadowColor=[UIColor lightGrayColor].CGColor;
    richTextEditorTextView.layer.shadowOpacity=1;
    CGRect shadowFrame=CGRectMake(0, 7, richTextEditorTextView.frame.size.width, richTextEditorTextView.frame.size.height-5);
    richTextEditorTextView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:shadowFrame] CGPath];
    
//    CGFloat padding = 20;
//    placeHolderLabel.frame = CGRectMake(padding, padding, self.view.bounds.size.width - 2 *padding, 25);

}
-(void)textViewToolBarSetup
{
    if (!accessoryViewBg) {
        accessoryViewBg=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.richTextEditorTextView.frame.size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)];
        
        accessoryViewBg.backgroundColor=[UIColor clearColor];
        accessoryViewBg.backgroundColor=UIColorFromRGB(0xf2f2f2);
        accessoryViewBg.layer.borderColor=UIColorFromRGB(0xe8e8e8).CGColor;
        
        //    accessoryView=[[UIView alloc]initWithFrame:CGRectMake(0,0,0, RICHTEXTEDITOR_TOOLBAR_HEIGHT)];
        UIDevice* thisDevice = [UIDevice currentDevice];
        if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            accessoryViewBg.autoresizingMask=UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
            
            //        accessoryView.autoresizingMask=UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
        }
        //
        //    accessoryView.opaque=YES;
        //    [accessoryView setBackgroundColor:[UIColor clearColor]];
        
        [richTextEditorTextView.toolBar setFrame:CGRectMake(0, 0, self.view.frame.size.width,RICHTEXTEDITOR_TOOLBAR_HEIGHT)];
        //    richTextEditorTextView.toolBar.customView = accessoryView;
        //        [self configureRichTexteditor];
        [accessoryViewBg addSubview:richTextEditorTextView.toolBar];
        [richTextEditorTextView.toolBar setBackgroundColor: UIColorFromRGB(0xf2f2f2)];
        richTextEditorTextView.toolBar.backgroundColor =UIColorFromRGB(0xffffff);
        
        accessoryBaseView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)];
        [accessoryBaseView addSubview:accessoryViewBg];
        [accessoryBaseView setBackgroundColor:[UIColor clearColor]];
        richTextEditorTextView.inputAccessoryView=accessoryBaseView;
        richTextEditorTextView.toolBarFeatures = RichTextEditorFeatureAll;
        [richTextEditorTextView.toolBar redraw];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)handlePlaceHolder
{
    if ([richTextEditorTextView hasText])
        placeHolderLabel.hidden= true;
    else
    {
        placeHolderLabel.hidden= false;
    [placeHolderLabel.superview bringSubviewToFront:placeHolderLabel];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
