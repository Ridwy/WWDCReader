//
//  ViewController.m
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import "CNWReaderViewController.h"
#import "CNWPDFPageView.h"

@interface CNWReaderViewController ()
@property (weak, nonatomic) IBOutlet CNWPDFPageView *pageView;
@property (weak, nonatomic) NSLayoutConstraint *pageAspectConstraint;
@property (weak, nonatomic) UISlider *seekSlider;
@end

@implementation CNWReaderViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 32, 32)];
    [slider addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
    slider.minimumValue = 1;
    slider.maximumValue = 10;
    slider.value = 1;
    self.seekSlider = slider;
    
    UIBarButtonItem *sliderItem = [[UIBarButtonItem alloc] initWithCustomView:slider];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[space, sliderItem, space];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePage];
    self.seekSlider.maximumValue = self.pdfDocument.pageCount;
    self.navigationController.toolbarHidden = (self.pdfDocument.pageCount == 1);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.pageView.page = nil;
    [self.pdfDocument clearPageCache];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint location = [tapRecognizer locationInView:self.view];
    CGRect bounds = self.view.bounds;
    
    if (self.navigationController.navigationBarHidden) {
        if (location.y < 50 || CGRectGetMaxY(bounds) - 40 < location.y) {
            [self showBar];
        } else {
            if (location.x < CGRectGetMidX(bounds)) {
                // previous
                self.pdfDocument.currentPageIndex = self.pdfDocument.currentPageIndex - 1;
                [self updatePage];
            } else {
                // next
                self.pdfDocument.currentPageIndex = self.pdfDocument.currentPageIndex + 1;
                [self updatePage];
            }
        }
    } else {
        [self hideBar];
    }
}

- (void)updatePage {
    if (!self.pageView) return;
    
    self.pageView.page = nil;
    [self.pdfDocument clearPageCache];
    
    CGPDFPageRef page = [self.pdfDocument currentPage];
    self.pageView.page = page;
    [self.pageView setNeedsDisplay];
    
    if (page) {
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        CGFloat aspect = pageRect.size.width / pageRect.size.height;
        if (self.pageAspectConstraint.multiplier != aspect) {
            NSLayoutConstraint *constraint;
            constraint = [NSLayoutConstraint constraintWithItem:self.pageView
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.pageView
                                                      attribute:NSLayoutAttributeHeight
                                                     multiplier:aspect
                                                       constant:0];
            if (self.pageAspectConstraint) {
                [self.pageView removeConstraint:self.pageAspectConstraint];
            }
            self.pageAspectConstraint = constraint;
            [self.pageView addConstraint:self.pageAspectConstraint];
        }
    }
    
    self.navigationItem.title = [NSString stringWithFormat:@"%lu/%lu",
                                 self.pdfDocument.currentPageIndex, self.pdfDocument.pageCount];
    
    self.seekSlider.value = self.pdfDocument.currentPageIndex;
}

- (void)hideBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)showBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (1 < self.pdfDocument.pageCount) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void)seek:(id)sender {
    self.pdfDocument.currentPageIndex = floor(self.seekSlider.value);
    [self updatePage];
}
@end
