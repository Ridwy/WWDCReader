//
//  CNWPDFDocument.m
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import "CNWPDFDocument.h"

@implementation CNWPDFDocument {
    CGPDFDocumentRef _premitiveDocument;
}
@synthesize URL = _URL;
@synthesize pageCount = _pageCount;

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self && URL) {
        _premitiveDocument = CGPDFDocumentCreateWithURL((CFURLRef)URL);
        if (_premitiveDocument) {
            _URL = URL;
            _currentPageIndex = 1;
            return self;
        }
    }
    self = nil;
    return self;
}

- (void)dealloc {
    CGPDFDocumentRelease(_premitiveDocument);
}

- (BOOL)isSupported {
    // パスワードでロックされていないか？
    if (CGPDFDocumentIsUnlocked(_premitiveDocument) == NO) return NO;;
    
    // 1ページ以上あるか？
    _pageCount = CGPDFDocumentGetNumberOfPages(_premitiveDocument);
    if (_pageCount == 0) return NO;
    
    return YES;
}

- (void)setCurrentPageIndex:(NSUInteger)index {
    _currentPageIndex = MIN(MAX(1, index), self.pageCount);
}

- (CGPDFPageRef)currentPage {
    return CGPDFDocumentGetPage(_premitiveDocument, self.currentPageIndex);
}

- (void)clearPageCache {
    CGPDFDocumentRelease(_premitiveDocument);
    _premitiveDocument = CGPDFDocumentCreateWithURL((CFURLRef)self.URL);
}
@end
