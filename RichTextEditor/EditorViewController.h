//
//  EditorViewController.h
//  RichTextEditor
//
//  Created by Karthi A on 14/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RichTextEditorTextView.h"
@interface EditorViewController : UIViewController<RIchTextViewDelegate>
{
    UIView *accessoryViewBg;
//    UIView *accessoryView;
    UIView*accessoryBaseView;
}
@property (strong, nonatomic) IBOutlet UILabel *placeHolderLabel;
@property (strong, nonatomic) IBOutlet RichTextEditorTextView *richTextEditorTextView;
@end
