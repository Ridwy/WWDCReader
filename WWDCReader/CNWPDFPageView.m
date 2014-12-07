//
//  CNWPDFPageView.m
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import "CNWPDFPageView.h"

@implementation CNWPDFPageView
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.geometryFlipped = YES;
    }
    return self;
}

- (void)dealloc {
    CGPDFPageRelease(_page);
}

- (void)setPage:(CGPDFPageRef)page {
    CGPDFPageRelease(_page);
    _page = page;
    CGPDFPageRetain(_page);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.page == nil) {
        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, self.bounds);
        return;
    }
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, self.bounds);
    
    CGRect pageRect = CGPDFPageGetBoxRect(self.page, kCGPDFMediaBox);
    CGFloat scale = MIN(self.bounds.size.width / pageRect.size.width,
                        self.bounds.size.height / pageRect.size.height);
    CGFloat width = pageRect.size.width * scale;
    CGFloat height = pageRect.size.height * scale;
    CGFloat x = self.bounds.origin.x + 0.5 * (self.bounds.size.width - width);
    CGFloat y = self.bounds.origin.y + 0.5 * (self.bounds.size.height - height);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, x, y);
    CGContextScaleCTM(context, scale, scale);
    CGContextDrawPDFPage(context, self.page);
    CGContextRestoreGState(context);
}
@end
