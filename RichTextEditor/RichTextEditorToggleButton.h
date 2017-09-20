//
//  RichTextEditorToggleButton.h
//  RichTextEditor
//
//  Created by Karthi A on 17/09/17.
//  Copyright © 2017 Karthi A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RichTextEditorToggleButton : UIButton
@property (nonatomic, assign) BOOL on;
@property (nonatomic, assign) BOOL changeIcon;

@property(nonatomic,strong)NSString* onImageName;
@property(nonatomic,strong)NSString* offImageName;

- (id)init;
-(id)initWithImage:(NSString *) imageName;

@end
