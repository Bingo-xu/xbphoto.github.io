//
//  ViewController.m
//  照片合成
//
//  Created by xubin on 16/7/6.
//  Copyright © 2016年 Appledev. All rights reserved.
//

#import "ViewController.h"
#import "YDYImagePicker.h"
#import <Foundation/Foundation.h>

@interface ViewController ()

@property (strong, nonatomic) YDYImagePicker * picker;

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property (nonatomic, strong) NSMutableArray * imagesArr;

@property (nonatomic, strong) NSMutableArray * pointArr;

@property (nonatomic, assign) NSInteger  index;

@property (nonatomic, assign) CGFloat  imageHeight;

@property (nonatomic, assign) CGFloat  imageWidth;

@property (nonatomic, assign) BOOL isMove;

@property (nonatomic, strong) UIImage * BGImage;

@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

@implementation ViewController{
    CGFloat lastScale;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _imageHeight = YScreenHeight;
    _imageWidth = YScreenWidth;
    _BGImage = [UIImage imageNamed:@"bg1"];
    [self rewriteBGImageWith:_BGImage];
}

-(void)rewriteBGImageWith:(UIImage *)image{
    _BGImage = image;
    self.showImageView.image = image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- 点击事件
//背景切换
- (IBAction)bgChange:(UIButton *)sender {
    self.index++;
    if (self.index == 5) {
        self.index = 0;
    }
    _BGImage = [UIImage imageNamed:[NSString stringWithFormat:@"bg%ld",self.index+1]];
   [self rewriteBGImageWith:_BGImage];
}

//相册选择背景
- (IBAction)cameraChoose:(UIButton *)sender {
    self.picker = [YDYImagePicker new];
    [self.picker pickerImageWithMaxImagesCount:1 isTailor:NO rootVC:self PhotosBlock:^(NSArray<UIImage *> *photos) {
        [self rewriteBGImageWith:photos[0]];
    } cancelBlock:^{
        
    }];
    
}


//保存照片
- (IBAction)saveImage:(UIButton *)sender {
    if (self.imagesArr.count == 0) {
        return;
    }
    if (_isMove) {
        [self.pointArr removeAllObjects];
    }
    for (UIView * view in self.showImageView.subviews) {
        [self.pointArr addObject:NSStringFromCGRect(view.frame)];
        [view removeFromSuperview];
    }
    UIImage * resultImage = [self mergedImageOnMainImage:self.showImageView.image WithImageArray:self.imagesArr];
    self.showImageView.image = resultImage;
    [self.imagesArr removeAllObjects];

}

//拍照
- (IBAction)cameraAction:(UIButton *)sender {
    self.picker = [YDYImagePicker new];
    [self.picker takePhotoWithRootVC:self isTailor:YES PhotosBlock:^(UIImage *photo) {
    [self addImagesWith:@[photo]];
    } cancelBlock:^{
      
    }];
    
}
//选照片
- (IBAction)selectPhoto:(UIButton *)sender {
    
    self.picker = [YDYImagePicker new];
    [self.picker pickerImageWithMaxImagesCount:9 isTailor:NO rootVC:self PhotosBlock:^(NSArray<UIImage *> *photos) {
        
         [self addImagesWith:photos];
        
    } cancelBlock:^{
        
    }];
}
//点击编辑删除照片
- (IBAction)deletePhto:(UIButton *)sender {
    sender.selected = !sender.isSelected;
}


#pragma mark- 拖移手势
//托移手势实现
- (void)buttonHandlePan:(UIPanGestureRecognizer*) recognizer
{
    _isMove = YES;
    UIView * panView = recognizer.view;
    CGFloat width = panView.frame.size.width;
    CGFloat height = panView.frame.size.height;
    NSLog(@"拖移，慢速移动");
    CGPoint translation = [recognizer translationInView:self.showImageView];
    CGPoint newcenter = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);;
    if (newcenter.x >= _imageWidth - width/2) {
        newcenter.x = _imageWidth - width/2;
    }
    if (newcenter.x <= width/2) {
        newcenter.x = width/2;
    }
    if (newcenter.y >= _imageHeight - height/2) {
        newcenter.y = _imageHeight - height/2;
    }
    if (newcenter.y <= height/2) {
        newcenter.y = height/2;
    }
    recognizer.view.center = newcenter;
    panView.frame = recognizer.view.frame;
    [recognizer setTranslation:CGPointZero inView:self.showImageView];
    
}

#pragma mark- 缩放手势
-(void)scaGesture:(id)sender {
    [self.view bringSubviewToFront:[(UIPinchGestureRecognizer*)sender view]];
    //当手指离开屏幕时,将lastscale设置为1.0
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        lastScale = 1.0;
        return;
    }
    
    CGFloat scale = 1.0 - (lastScale - [(UIPinchGestureRecognizer*)sender scale]);
    CGAffineTransform currentTransform = [(UIPinchGestureRecognizer*)sender view].transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
    [[(UIPinchGestureRecognizer*)sender view]setTransform:newTransform];
    lastScale = [(UIPinchGestureRecognizer*)sender scale];
    
}

#pragma mark-
-(void)tapGesture:(UIGestureRecognizer*) recognizer{
    if (self.deleteBtn.isSelected&&self.imagesArr.count>0) {
        [self.pointArr removeObject:NSStringFromCGRect(recognizer.view.frame)];
        [self.imagesArr removeObject:[(UIImageView *)recognizer.view image]];
        //移除视图
        [recognizer.view removeFromSuperview];
    }
}

#pragma mark- 照片处理相关
//将照片放入数组
-(void)addImagesWith:(NSArray *)arr{
    [self rewriteBGImageWith:_BGImage];
    if (self.imagesArr.count + arr.count >9) {
        [self.imagesArr removeObjectsInRange:NSMakeRange(0, self.imagesArr.count + arr.count -9)];
    }
    [self.imagesArr addObjectsFromArray:arr];
    [self showImages];
}


//显示选中的照片
-(void)showImages{
    NSInteger max = self.imagesArr.count;
    if (max>0) {
        NSInteger maxI ,minJ;
        if (max%3!=0) {
            maxI = max/3+1;
        }else{
            maxI = max/3;
        }
        
        minJ = 3;
        
        for (NSInteger i = 0; i< maxI; i++) {
            if (i==maxI-1) {
                if (max%3!=0) {
                    minJ = max%3;
                }
            }
            for (NSInteger j=0; j<minJ; j++) {
                UIImageView * imageView ;
                if (self.showImageView.subviews.count>3*i+j) {
                    imageView = self.showImageView.subviews[3*i+j];
                }
               
                if (!imageView) {
                    imageView = [UIImageView new];
                    CGRect frame = CGRectMake(j*((_imageWidth-10)/3+5), i*((_imageHeight-10)/3+5), (_imageWidth-10)/3, (_imageHeight-10)/3);
                    imageView.frame = frame;
                    //拖移手势
                    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(buttonHandlePan:)];
                    [imageView addGestureRecognizer:panGestureRecognizer];
                    imageView.userInteractionEnabled = YES;
                    //缩放手势
                    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(scaGesture:)];
                    [imageView addGestureRecognizer:pinchRecognizer];
                    
                    //点击手势
                    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
                    [imageView addGestureRecognizer:tap];
                    
                    imageView.contentMode = UIViewContentModeScaleAspectFit;
               
                    [self.pointArr addObject:NSStringFromCGRect(frame)];
                    [self.showImageView addSubview:imageView];
                   
                }
//                UIImage * result = [self imageWithImageSimple:self.imagesArr[i*3+j] scaledToSize:CGSizeMake((_imageWidth-10)/3, (_imageHeight-10)/3)];
//                [self.imagesArr replaceObjectAtIndex:i*3+j withObject:result];
//                imageView.image = result;
                imageView.image = self.imagesArr[i*3+j];
            }
        }

    }
}


//多张照片合成一张
- (UIImage *) mergedImageOnMainImage:(UIImage *)mainImg WithImageArray:(NSArray *)imgArray
{
    CGRect mainFrame = CGRectMake(0, 0, _imageWidth, _imageHeight);
     UIGraphicsBeginImageContextWithOptions(mainFrame.size, NO,[UIScreen mainScreen].scale);
    [mainImg drawInRect:mainFrame];//根据新的尺寸画出传过来的图片
    int i = 0;
    for (UIImage *img in imgArray) {
        CGSize size = CGRectFromString(self.pointArr[i]).size;
        CGPoint origin = CGRectFromString(self.pointArr[i]).origin;
        CGPoint center = CGPointMake(origin.x+size.width/2, origin.y+size.height/2);
        CGRect realRect = CGRectMake(origin.x, center.y - (size.width/img.size.width*img.size.height)/2, size.width, size.width/img.size.width*img.size.height);
        [img drawInRect:realRect];
        i++;
    }

    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();//关闭当前环境
    
    if (resultImage == nil) {
        return nil;
    }
    else {

        //存入相册
        UIImageWriteToSavedPhotosAlbum(resultImage, self, nil, nil);
        return resultImage;
    }
}



#pragma mark - 初始化相关
-(NSMutableArray *)imagesArr{
    if (!_imagesArr) {
        _imagesArr = [NSMutableArray new];
    }
    return _imagesArr;
}

-(NSMutableArray *)pointArr{
    if (!_pointArr) {
        _pointArr = [NSMutableArray new];
    }
    return _pointArr;
}

@end
