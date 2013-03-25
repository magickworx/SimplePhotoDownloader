/*****************************************************************************
 *
 * FILE:	RootViewController.m
 * DESCRIPTION:	PhotoDownloader: Root View Controller
 * DATE:	Mon, Mar 25 2013
 * UPDATED:	Mon, Mar 25 2013
 * AUTHOR:	Kouichi ABE (WALL) / 阿部康一
 * E-MAIL:	kouichi@MagickWorX.COM
 * URL:		http://www.MagickWorX.COM/
 * COPYRIGHT:	(c) 2013 阿部康一／Kouichi ABE (WALL), All rights reserved.
 * LICENSE:
 *
 *  Copyright (c) 2013 Kouichi ABE (WALL) <kouichi@MagickWorX.COM>,
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 *   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
 *   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *   INTERRUPTION)  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 *   THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: RootViewController.m,v 1.2 2013/01/22 15:23:51 kouichi Exp $
 *
 *****************************************************************************/

#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"

#define	kThumbnailWidth		75.0f
#define	kThumbnailHeight	75.0f
#define	kImageCellWidth		(kThumbnailWidth  + 2.0f * 2.0f)
#define	kImageCellHeight	(kThumbnailHeight + 2.0f * 2.0f)

/******************************************************************************
 *
 *	ImageCollectionCell
 *
 *****************************************************************************/
@interface ImageCollectionCell : UICollectionViewCell
{
@private
  UIImageView *	_imageView;
}
@property (nonatomic,strong,readonly) UIImageView *	imageView;
@end

@interface ImageCollectionCell ()
@property (nonatomic,strong,readwrite) UIImageView *	imageView;
@end

@implementation ImageCollectionCell

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizesSubviews	= YES;
    self.autoresizingMask	= UIViewAutoresizingFlexibleLeftMargin
				| UIViewAutoresizingFlexibleRightMargin
				| UIViewAutoresizingFlexibleTopMargin
				| UIViewAutoresizingFlexibleBottomMargin
				| UIViewAutoresizingFlexibleWidth
				| UIViewAutoresizingFlexibleHeight;
    CGFloat	x = 0.0f;
    CGFloat	y = 0.0f;
    CGFloat	w = frame.size.width;
    CGFloat	h = frame.size.height;

    UIImageView *	imageView;
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    imageView.autoresizingMask	= UIViewAutoresizingFlexibleLeftMargin
				| UIViewAutoresizingFlexibleRightMargin
				| UIViewAutoresizingFlexibleTopMargin
				| UIViewAutoresizingFlexibleBottomMargin
				| UIViewAutoresizingFlexibleWidth
				| UIViewAutoresizingFlexibleHeight;
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setClipsToBounds:YES];
    [self.contentView addSubview:imageView];
    self.imageView = imageView;
  }
  return self;
}

-(void)prepareForReuse
{
  [super prepareForReuse];

  self.imageView.image	= nil;
}

@end

/******************************************************************************
 *
 *	RootViewController
 *
 *****************************************************************************/
static NSString * imageCellIdentifier = @"ImageCollectionCellIdentifier";

@interface RootViewController ()
{
@private
  NSMutableArray *	_images;	// ダウンロード画像を保存する配列
  NSOperationQueue *	_queue;		// 非同期ダウンロード用のキュー
}
@property (nonatomic,strong) NSMutableArray *	images;
@property (nonatomic,strong) NSOperationQueue *	queue;
@end

@interface RootViewController (Private)
-(void)activityActionForImage:(UIImage *)image;
-(void)popupWithMessage:(NSString *)message;
@end

@implementation RootViewController

-(id)init
{
  /*
   * layout の各パラメータの数値は適当
   * 詳細はリファレンスを読んでね。
   */
  UICollectionViewFlowLayout *	layout;
  layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 24.0f;
  layout.minimumInteritemSpacing = 16.0f;
  layout.itemSize = CGSizeMake(kImageCellWidth, kImageCellHeight);
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.sectionInset = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);

  self = [super initWithCollectionViewLayout:layout];
  if (self) {
    self.title = NSLocalizedString(@"PhotoDownloader", @"");
    [self.collectionView registerClass:[ImageCollectionCell class]
			 forCellWithReuseIdentifier:imageCellIdentifier];
    _images = [[NSMutableArray alloc] init];
    _queue  = [[NSOperationQueue alloc] init];
  }

  srandomdev();

  return self;
}

-(void)dealloc
{
  [self.queue cancelAllOperations];
}

-(void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  self.view.autoresizesSubviews	= YES;
  self.view.autoresizingMask	= UIViewAutoresizingFlexibleLeftMargin
				| UIViewAutoresizingFlexibleRightMargin
				| UIViewAutoresizingFlexibleTopMargin
				| UIViewAutoresizingFlexibleBottomMargin;

  UIBarButtonItem *	downloadButton;
  downloadButton = [[UIBarButtonItem alloc]
		    initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
		    target:self
		    action:@selector(downloadAction:)];
  self.navigationItem.rightBarButtonItem = downloadButton;
}

/*****************************************************************************/

#pragma mark UIBarButtonItem action
-(void)downloadAction:(id)sender
{
  __block RootViewController *	weakSelf = self;

  [self.images removeAllObjects];

  /*
   * ダウンロード完了時に呼び出されるコールバック関数
   * ここでは、エラーなしでデータが存在する場合は、
   * ダウンロードした画像を仮定して NSData から UIImage を作成する。
   *
   * 独自のアプリで応用する場合は、この関数から delegate を呼び出したり、
   * NSNotification を使った通知を行うと良い。
   */
  void (^completionHandler)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse * response, NSData * data, NSError * error) {
    if ([data length] > 0 && error == nil) {
      UIImage *	image = [[UIImage alloc] initWithData:data];
      [weakSelf.images addObject:image];

      // GUI の書き換えは main スレッドで実施
      dispatch_async(dispatch_get_main_queue(), ^{
	[weakSelf.collectionView reloadData];
      });
    }
    else {
      [weakSelf popupWithMessage:[error localizedDescription]];
    }
  };

  static NSString * const	baseURLString = @"http://www.s-se.jp/kankou/photo_hikari1/images";

  /*
   * maxPhotos はダウンロードする画像の枚数。
   * このサンプルソースコードではダウンロードした画像を
   * NSMutableArray に保存する。
   * 指定する数を大きくすると画像サイズにもよるが、メモリ不足になるだろう。
   * 実際のアプリで応用する場合は、ダウンロード画像の管理方法も
   * きちんと設計する必要がある。
   */
  NSUInteger		maxPhotos = 10;
  NSMutableArray *	urls;
  urls = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < maxPhotos; i++) {
    /*
     * www.s-se.jp サイトの画像の枚数は 133 枚。
     * ファイル名は 0 からの連番なので、ランダムな 0 から 132 の番号を生成。
     */
    long	n = random() % 133;
    NSString *	urlString;
    urlString = [[NSString alloc]
		  initWithFormat:@"%@/img%04ld.jpg", baseURLString, n];
    NSURL *	url;
    url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *	request;
    request = [[NSURLRequest alloc] initWithURL:url];
    /*
     * 非同期に画像をダウンロード
     * ダウンロードが完了した際に completionHandler が呼ばれる。
     * そのため、完了時に実施したい処理は completionHandler 側に記述する。
     */
    [NSURLConnection sendAsynchronousRequest:request
 		     queue:self.queue
		     completionHandler:completionHandler];
  }
}

/*****************************************************************************/

#pragma mark UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

#pragma mark UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView
	numberOfItemsInSection:(NSInteger)section
{
  return self.images.count;
}

#pragma mark UICollectionViewDataSource
/*
 * The cell that is returned must be retrieved from a call to
 * -dequeueReusableCellWithReuseIdentifier:forIndexPath:
 */
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
	cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ImageCollectionCell *	cell;
  cell = (ImageCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];

  UIImage *	image	= [self.images objectAtIndex:[indexPath row]];
  cell.imageView.image	= image; 

  return cell;
}


#pragma mark UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView
	didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  UIImage *	image	= [self.images objectAtIndex:[indexPath row]];

  [self activityActionForImage:image];
}


#pragma mark UICollectionViewDelegateFlowLayout
-(CGSize)collectionView:(UICollectionView *)collectionView
	layout:(UICollectionViewLayout *)collectionViewLayout
	sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  /*
   * この delegate では、ダウンロードした画像を縮小表示するための
   * 縦横の比率を計算する。portrait や landscape が混在する場合は、
   * それぞれに応じた値になるはず。
   */
  UIImage *	image	= [self.images objectAtIndex:[indexPath row]];
  CGFloat	width	= image.size.width;
  CGFloat	height	= image.size.height;
  CGFloat	factor	= 1.0f;
  CGSize	itemSize;

  if (width > height) {		// Landscape
    factor = kImageCellWidth / width;
  }
  else if (height > width) {	// Portrait
    factor = kImageCellHeight / height;
  }
  else {
    factor = 1.0f;
  }
  itemSize = CGSizeMake(floorf(width * factor), floorf(height * factor));

  return itemSize;
}

/*****************************************************************************/

-(void)activityActionForImage:(UIImage *)image
{
  NSMutableArray *	items;
  items = [[NSMutableArray alloc] init];
  [items addObject:image];

  UIActivityViewController *	activityViewController;
  activityViewController = [[UIActivityViewController alloc]
			    initWithActivityItems:items
			    applicationActivities:nil];
  activityViewController.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact];

  [self presentViewController:activityViewController
			     animated:YES
			     completion:nil];
}

/*****************************************************************************/

-(void)popupWithMessage:(NSString *)message
{
  UIAlertView *	alertView;
  alertView = [[UIAlertView alloc]
		initWithTitle:NSLocalizedString(@"Error", @"")
		message:message
		delegate:nil
		cancelButtonTitle:NSLocalizedString(@"Close", @"")
		otherButtonTitles:nil];
  [alertView show];
}

@end
