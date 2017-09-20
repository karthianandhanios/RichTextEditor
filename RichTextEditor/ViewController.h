//
//  ViewController.h
//  RichTextEditor
//
//  Created by Karthi A on 07/08/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (strong, nonatomic) IBOutlet UIButton *tempClickToEditButton;

@end

