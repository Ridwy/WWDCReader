//
//  CNWAppDelegate.h
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CNWAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

NSURL *CNWDocumentsDirectoryURL();