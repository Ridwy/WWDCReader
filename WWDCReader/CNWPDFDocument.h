//
//  CNWPDFDocument.h
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CNWPDFDocument : NSObject
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly, getter=isSupported) BOOL supported;
@property (nonatomic, readonly) NSUInteger pageCount;
@property (nonatomic) NSUInteger currentPageIndex; // starting at 1.
- (instancetype)initWithURL:(NSURL *)URL;
- (CGPDFPageRef)currentPage;
- (void)clearPageCache;
@end
