//
//  ViewController.m
//  RichTextEditor
//
//  Created by Karthi A on 07/08/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import "ViewController.h"
#import "EditorViewController.h"
@interface ViewController ()

@end

@implementation ViewController
@synthesize contentTextView,titleTextView;
- (void)viewDidLoad {
    [super viewDidLoad];
//    contentTextView.tag = 1111;
//    contentTextView.delegate  = self;
//    titleTextView.tag = 2222;
//    titleTextView.delegate  = self;
//    titleTextView.frame = CGRectMake(0, 0,self.view.frame.size.width, 60);
//    [contentTextView addSubview:titleTextView];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)textViewDidChange:(UITextView *)textView
{
//    [self updateFrames];
}

//- (void)updateFrames
//{
//    CGSize size = self.titleTextView.contentSize;
//    CGRect rect = {0,-size.height,size};
//    self.titleTextView.frame = rect;
//    NSLog(@"content Size  --  %@ and title frame---%@",NSStringFromCGSize(size),NSStringFromCGRect(rect));
//     self.contentTextView.contentInset = UIEdgeInsetsMake(size.height, 0, 0, 0);
//}

- (IBAction)openEditorView:(id)sender {
    EditorViewController *editorViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditorViewController"];
    [self.navigationController pushViewController:editorViewController animated:YES];

}

@end
